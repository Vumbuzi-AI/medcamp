defmodule Medcamp.Procurement.PurchaseOrders do
  @moduledoc """
  Purchase order lifecycle: draft → pending_approval → approved → sent →
  acknowledged → delivered.

  Submission for approval requires all 5 checklist booleans.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Ecto.Multi

  alias Medcamp.Procurement.{
    PurchaseOrder,
    PurchaseOrderItem,
    Quote,
    References,
    Notifications
  }

  alias Medcamp.Accounts.User

  @pubsub Medcamp.PubSub

  def list_purchase_orders(opts \\ []) do
    purchase_orders_query(opts)
    |> preload([:supplier, :approved_by, :created_by, :rfq, :proforma_invoice, items: :rfq_item])
    |> Repo.all()
  end

  def list_purchase_orders_paginated(opts \\ %{}, page \\ 1, per_page \\ 20) do
    purchase_orders_query(opts)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([
      :supplier,
      :approved_by,
      :created_by,
      :rfq,
      :proforma_invoice,
      items: :rfq_item
    ])
  end

  def count_purchase_orders(opts \\ %{}) do
    purchase_orders_query(opts)
    |> Repo.aggregate(:count, :id)
  end

  def get_purchase_order!(id) do
    PurchaseOrder
    |> Repo.get!(id)
    |> Repo.preload([
      :supplier,
      :approved_by,
      :created_by,
      :rfq,
      :proforma_invoice,
      items: :rfq_item
    ])
  end

  def get_purchase_order(id) do
    case Repo.get(PurchaseOrder, id) do
      nil ->
        nil

      po ->
        Repo.preload(po, [
          :supplier,
          :approved_by,
          :created_by,
          :rfq,
          :proforma_invoice,
          items: :rfq_item
        ])
    end
  end

  defp maybe_filter(query, _field, nil), do: query
  defp maybe_filter(query, field, value), do: where(query, [q], field(q, ^field) == ^value)

  defp purchase_orders_query(opts) do
    opts = if is_list(opts), do: Map.new(opts), else: opts
    search = Map.get(opts, :search)

    PurchaseOrder
    |> join(:left, [p], sup in assoc(p, :supplier))
    |> join(:left, [p, sup], rfq in assoc(p, :rfq))
    |> maybe_filter(:supplier_id, Map.get(opts, :supplier_id))
    |> maybe_filter(:status, Map.get(opts, :status))
    |> maybe_filter_search(search)
    |> order_by([p], desc: p.inserted_at)
  end

  defp maybe_filter_search(query, nil), do: query
  defp maybe_filter_search(query, ""), do: query

  defp maybe_filter_search(query, search) do
    pattern = "%#{String.trim(search)}%"

    from [p, sup, rfq] in query,
      where:
        ilike(p.reference, ^pattern) or
          ilike(sup.legal_name, ^pattern) or
          ilike(sup.name, ^pattern) or
          ilike(rfq.reference, ^pattern)
  end

  # ---------------------------------------------------------------------------
  # Create
  # ---------------------------------------------------------------------------

  def create(attrs, %User{id: user_id}) do
    {items, attrs} = pop_items(attrs)

    attrs =
      attrs
      |> Map.new()
      |> Map.put_new(:reference, References.next_purchase_order_reference())
      |> Map.put(:created_by_id, user_id)
      |> Map.put_new(:status, "draft")
      |> Map.put_new(:po_date, Date.utc_today())

    Multi.new()
    |> Multi.insert(:po, PurchaseOrder.changeset(%PurchaseOrder{}, attrs))
    |> Multi.run(:items, fn _repo, %{po: po} -> insert_items(po.id, items) end)
    |> Multi.run(:totals, fn _repo, %{po: po} -> recalculate_totals(po) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{totals: po}} -> {:ok, Repo.preload(po, items: :rfq_item)}
      {:error, _op, reason, _} -> {:error, reason}
    end
  end

  @doc """
  Create a PO from an accepted quote. Copies line items; VAT matches the quote.
  """
  def create_from_quote(%Quote{} = quote, attrs, %User{id: user_id}) do
    quote = Repo.preload(quote, items: :rfq_item)

    base =
      %{
        reference: References.next_purchase_order_reference(),
        rfq_id: quote.rfq_id,
        supplier_id: quote.supplier_id,
        po_date: Date.utc_today(),
        subtotal: quote.subtotal,
        vat_amount: quote.vat_amount,
        total: quote.total,
        status: "draft",
        created_by_id: user_id
      }
      |> Map.merge(Map.new(attrs))

    items =
      Enum.map(quote.items, fn qi ->
        %{
          rfq_item_id: qi.rfq_item_id,
          inventory_received_id:
            qi.inventory_received_id || (qi.rfq_item && qi.rfq_item.inventory_received_id),
          position: qi.position,
          description: qi.rfq_item && qi.rfq_item.description,
          unit: qi.unit,
          quantity: qi.quantity_available,
          unit_price: qi.unit_price,
          total: qi.total
        }
      end)

    Multi.new()
    |> Multi.insert(:po, PurchaseOrder.changeset(%PurchaseOrder{}, base))
    |> Multi.run(:items, fn _repo, %{po: po} -> insert_items(po.id, items) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{po: po}} -> {:ok, Repo.preload(po, items: :rfq_item)}
      {:error, _op, reason, _} -> {:error, reason}
    end
  end

  def update(%PurchaseOrder{} = po, attrs) do
    {items, attrs} = pop_items(attrs)

    Multi.new()
    |> Multi.update(:po, PurchaseOrder.changeset(po, attrs))
    |> Multi.run(:items, fn _repo, %{po: po} ->
      if is_nil(items) do
        {:ok, []}
      else
        Repo.delete_all(from i in PurchaseOrderItem, where: i.purchase_order_id == ^po.id)
        insert_items(po.id, items)
      end
    end)
    |> Multi.run(:totals, fn _repo, %{po: po} -> recalculate_totals(po) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{totals: po}} -> {:ok, Repo.preload(po, items: :rfq_item, force: true)}
      {:error, _op, reason, _} -> {:error, reason}
    end
  end

  defp pop_items(attrs) do
    attrs = Map.new(attrs)
    items = Map.get(attrs, :items) || Map.get(attrs, "items")
    {items, Map.drop(attrs, [:items, "items"])}
  end

  defp insert_items(_po_id, nil), do: {:ok, []}

  defp insert_items(po_id, items) do
    Enum.reduce_while(Enum.with_index(items, 1), {:ok, []}, fn {item, idx}, {:ok, acc} ->
      attrs =
        item
        |> Map.new()
        |> Map.put(:purchase_order_id, po_id)
        |> Map.put_new(:position, idx)
        |> compute_line_total()

      %PurchaseOrderItem{}
      |> PurchaseOrderItem.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, rec} -> {:cont, {:ok, [rec | acc]}}
        {:error, cs} -> {:halt, {:error, cs}}
      end
    end)
  end

  defp compute_line_total(attrs) do
    qty = decimal(Map.get(attrs, :quantity) || Map.get(attrs, "quantity"))
    price = decimal(Map.get(attrs, :unit_price) || Map.get(attrs, "unit_price"))
    Map.put(attrs, :total, Decimal.mult(qty, price))
  end

  defp recalculate_totals(%PurchaseOrder{} = po) do
    items = Repo.all(from i in PurchaseOrderItem, where: i.purchase_order_id == ^po.id)

    subtotal =
      Enum.reduce(items, Decimal.new(0), fn i, acc ->
        Decimal.add(acc, i.total || Decimal.new(0))
      end)

    vat_amount = Decimal.mult(subtotal, Decimal.new("0.16"))
    total = Decimal.add(subtotal, vat_amount)

    po
    |> PurchaseOrder.changeset(%{subtotal: subtotal, vat_amount: vat_amount, total: total})
    |> Repo.update()
  end

  # ---------------------------------------------------------------------------
  # Lifecycle transitions
  # ---------------------------------------------------------------------------

  @doc """
  Checks all 5 checklist fields and transitions to `pending_approval`.
  """
  def submit_for_approval(%PurchaseOrder{} = po) do
    if checklist_complete?(po) do
      po
      |> PurchaseOrder.changeset(%{status: "pending_approval"})
      |> Repo.update()
      |> case do
        {:ok, updated} ->
          broadcast_all({:po_pending_approval, updated})
          {:ok, updated}

        error ->
          error
      end
    else
      {:error, :checklist_incomplete}
    end
  end

  def approve(%PurchaseOrder{} = po, %User{id: approver_id}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    po
    |> PurchaseOrder.changeset(%{
      status: "approved",
      approved_by_id: approver_id,
      approved_at: now
    })
    |> Repo.update()
    |> case do
      {:ok, updated} ->
        broadcast_all({:po_approved, updated})
        {:ok, updated}

      error ->
        error
    end
  end

  def send_to_supplier(%PurchaseOrder{} = po) do
    po
    |> PurchaseOrder.changeset(%{status: "sent"})
    |> Repo.update()
    |> case do
      {:ok, updated} ->
        broadcast_all({:po_sent, updated})
        broadcast_supplier(updated.supplier_id, {:po_sent, updated})

        notify_supplier_users(updated.supplier_id, "po_issued", %{
          title: "Purchase order: #{updated.reference}",
          body: "A new purchase order has been issued.",
          resource_type: "purchase_order",
          resource_id: updated.id
        })

        {:ok, updated}

      error ->
        error
    end
  end

  def acknowledge(%PurchaseOrder{} = po) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    po
    |> PurchaseOrder.changeset(%{status: "acknowledged", acknowledged_at: now})
    |> Repo.update()
    |> case do
      {:ok, updated} ->
        broadcast_all({:po_acknowledged, updated})
        broadcast_supplier(updated.supplier_id, {:po_acknowledged, updated})
        {:ok, updated}

      error ->
        error
    end
  end

  def mark_delivered(%PurchaseOrder{} = po) do
    po
    |> PurchaseOrder.changeset(%{status: "delivered"})
    |> Repo.update()
  end

  def checklist_complete?(%PurchaseOrder{} = po) do
    PurchaseOrder.checklist_fields()
    |> Enum.all?(fn field -> Map.get(po, field) == true end)
  end

  defp decimal(nil), do: Decimal.new(0)
  defp decimal(%Decimal{} = d), do: d
  defp decimal(n) when is_integer(n), do: Decimal.new(n)
  defp decimal(n) when is_float(n), do: Decimal.from_float(n)

  defp decimal(s) when is_binary(s) do
    case Decimal.parse(s) do
      {d, _} -> d
      :error -> Decimal.new(0)
    end
  end

  defp broadcast_all(msg), do: Phoenix.PubSub.broadcast(@pubsub, "procurement:all", msg)

  defp broadcast_supplier(supplier_id, msg),
    do: Phoenix.PubSub.broadcast(@pubsub, "supplier:#{supplier_id}", msg)

  defp notify_supplier_users(supplier_id, type, attrs) do
    user_ids =
      from(u in User, where: u.supplier_id == ^supplier_id, select: u.id)
      |> Repo.all()

    Enum.each(user_ids, fn uid -> Notifications.notify(uid, type, attrs) end)
  end
end
