defmodule Medcamp.Procurement.Invoices do
  @moduledoc """
  Invoice lifecycle: draft → submitted → pending_grn → grn_confirmed → approved.

  On approval, the related PO is transitioned to `delivered`.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Ecto.Multi

  alias Medcamp.Procurement.{
    Invoice,
    InvoiceItem,
    PurchaseOrder,
    References,
    Notifications
  }

  alias Medcamp.Accounts.User

  @pubsub Medcamp.PubSub

  def list_invoices(opts \\ []) do
    Invoice
    |> maybe_filter(:supplier_id, Keyword.get(opts, :supplier_id))
    |> maybe_filter(:status, Keyword.get(opts, :status))
    |> order_by([i], desc: i.inserted_at)
    |> Repo.all()
  end

  def list_invoices_paginated(opts \\ %{}, page \\ 1, per_page \\ 20) do
    invoices_query(opts)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_invoices(opts \\ %{}) do
    invoices_query(opts)
    |> Repo.aggregate(:count, :id)
  end

  def get_invoice!(id) do
    Invoice
    |> Repo.get!(id)
    |> Repo.preload([:purchase_order, :supplier, :approved_by, items: :purchase_order_item])
  end

  def get_invoice(id) do
    case Repo.get(Invoice, id) do
      nil ->
        nil

      inv ->
        Repo.preload(inv, [:purchase_order, :supplier, :approved_by, items: :purchase_order_item])
    end
  end

  defp maybe_filter(query, _field, nil), do: query
  defp maybe_filter(query, field, value), do: where(query, [q], field(q, ^field) == ^value)

  defp invoices_query(opts) do
    Invoice
    |> maybe_filter(:supplier_id, Map.get(opts, :supplier_id))
    |> maybe_filter(:status, Map.get(opts, :status))
    |> order_by([i], desc: i.inserted_at)
  end

  # ---------------------------------------------------------------------------
  # Create / update (draft)
  # ---------------------------------------------------------------------------

  def create(attrs) do
    {items, attrs} = pop_items(attrs)

    attrs =
      attrs
      |> Map.new()
      |> Map.put_new(:reference, References.next_invoice_reference())
      |> Map.put_new(:status, "draft")
      |> Map.put_new(:invoice_date, Date.utc_today())

    Multi.new()
    |> Multi.insert(:invoice, Invoice.changeset(%Invoice{}, attrs))
    |> Multi.run(:items, fn _repo, %{invoice: inv} -> insert_items(inv.id, items) end)
    |> Multi.run(:totals, fn _repo, %{invoice: inv} -> recalculate_totals(inv) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{totals: inv}} -> {:ok, Repo.preload(inv, items: :purchase_order_item)}
      {:error, _op, reason, _} -> {:error, reason}
    end
  end

  def update(%Invoice{} = inv, attrs) do
    {items, attrs} = pop_items(attrs)

    Multi.new()
    |> Multi.update(:invoice, Invoice.changeset(inv, attrs))
    |> Multi.run(:items, fn _repo, %{invoice: inv} ->
      if is_nil(items) do
        {:ok, []}
      else
        Repo.delete_all(from i in InvoiceItem, where: i.invoice_id == ^inv.id)
        insert_items(inv.id, items)
      end
    end)
    |> Multi.run(:totals, fn _repo, %{invoice: inv} -> recalculate_totals(inv) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{totals: inv}} -> {:ok, Repo.preload(inv, items: :purchase_order_item, force: true)}
      {:error, _op, reason, _} -> {:error, reason}
    end
  end

  defp pop_items(attrs) do
    attrs = Map.new(attrs)
    items = Map.get(attrs, :items) || Map.get(attrs, "items")
    {items, Map.drop(attrs, [:items, "items"])}
  end

  defp insert_items(_inv_id, nil), do: {:ok, []}

  defp insert_items(inv_id, items) do
    Enum.reduce_while(Enum.with_index(items, 1), {:ok, []}, fn {item, idx}, {:ok, acc} ->
      attrs =
        item
        |> Map.new()
        |> Map.put(:invoice_id, inv_id)
        |> Map.put_new(:position, idx)
        |> compute_line_total()

      %InvoiceItem{}
      |> InvoiceItem.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, rec} -> {:cont, {:ok, [rec | acc]}}
        {:error, cs} -> {:halt, {:error, cs}}
      end
    end)
  end

  defp compute_line_total(attrs) do
    qty = decimal(Map.get(attrs, :quantity_delivered) || Map.get(attrs, "quantity_delivered"))
    price = decimal(Map.get(attrs, :unit_price) || Map.get(attrs, "unit_price"))
    gross = Decimal.mult(qty, price)

    vat_rate = decimal(Map.get(attrs, :vat_rate) || Map.get(attrs, "vat_rate") || "0.16")
    vat = Decimal.mult(gross, vat_rate)

    attrs
    |> Map.put(:vat_amount, vat)
    |> Map.put(:total, Decimal.add(gross, vat))
    |> Map.put_new(:vat_rate, vat_rate)
  end

  defp recalculate_totals(%Invoice{} = inv) do
    items = Repo.all(from i in InvoiceItem, where: i.invoice_id == ^inv.id)

    subtotal =
      Enum.reduce(items, Decimal.new(0), fn i, acc ->
        qty = i.quantity_delivered || Decimal.new(0)
        price = i.unit_price || Decimal.new(0)
        Decimal.add(acc, Decimal.mult(qty, price))
      end)

    vat_amount =
      Enum.reduce(items, Decimal.new(0), fn i, acc ->
        Decimal.add(acc, i.vat_amount || Decimal.new(0))
      end)

    total = Decimal.add(subtotal, vat_amount)

    inv
    |> Invoice.changeset(%{subtotal: subtotal, vat_amount: vat_amount, total: total})
    |> Repo.update()
  end

  # ---------------------------------------------------------------------------
  # Submit
  # ---------------------------------------------------------------------------

  def submit(%Invoice{} = inv) do
    inv
    |> Invoice.changeset(%{status: "submitted"})
    |> Repo.update()
    |> case do
      {:ok, updated} ->
        broadcast_all({:invoice_submitted, updated})

        notify_procurement_team("invoice_submitted", %{
          title: "Invoice submitted: #{updated.reference}",
          body: "A supplier invoice is awaiting review.",
          resource_type: "invoice",
          resource_id: updated.id
        })

        {:ok, updated}

      error ->
        error
    end
  end

  # ---------------------------------------------------------------------------
  # Approve — triggers PO → delivered
  # ---------------------------------------------------------------------------

  def approve(%Invoice{status: "grn_confirmed"} = inv, %User{id: approver_id}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Multi.new()
    |> Multi.update(
      :invoice,
      Invoice.changeset(inv, %{status: "approved", approved_by_id: approver_id, approved_at: now})
    )
    |> Multi.run(:po, fn _repo, %{invoice: inv} ->
      case Repo.get(PurchaseOrder, inv.purchase_order_id) do
        nil -> {:ok, nil}
        po -> po |> PurchaseOrder.changeset(%{status: "delivered"}) |> Repo.update()
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{invoice: inv}} ->
        broadcast_all({:invoice_approved, inv})
        broadcast_supplier(inv.supplier_id, {:invoice_approved, inv})

        notify_supplier_users(inv.supplier_id, "invoice_approved", %{
          title: "Invoice approved: #{inv.reference}",
          body: "Your invoice has been approved and the purchase order has moved forward.",
          resource_type: "invoice",
          resource_id: inv.id
        })

        {:ok, inv}

      {:error, _op, reason, _} ->
        {:error, reason}
    end
  end

  def approve(%Invoice{}, _user), do: {:error, :not_grn_confirmed}

  def reject(%Invoice{} = inv, _user) do
    inv
    |> Invoice.changeset(%{status: "rejected"})
    |> Repo.update()
    |> case do
      {:ok, updated} ->
        broadcast_all({:invoice_rejected, updated})
        broadcast_supplier(updated.supplier_id, {:invoice_rejected, updated})

        notify_supplier_users(updated.supplier_id, "invoice_rejected", %{
          title: "Invoice rejected: #{updated.reference}",
          body: "Your invoice has been rejected. Please review and resubmit if needed.",
          resource_type: "invoice",
          resource_id: updated.id
        })

        {:ok, updated}

      error ->
        error
    end
  end

  @doc false
  def mark_pending_grn(%Invoice{} = inv) do
    inv |> Invoice.changeset(%{status: "pending_grn"}) |> Repo.update()
  end

  @doc false
  def mark_grn_confirmed(%Invoice{} = inv) do
    inv |> Invoice.changeset(%{status: "grn_confirmed"}) |> Repo.update()
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

  defp notify_procurement_team(type, attrs) do
    user_ids =
      from(u in User,
        where: u.role in ["procurement_officer", "stores_officer", "finance_officer", "admin"],
        select: u.id
      )
      |> Repo.all()

    Enum.each(user_ids, fn uid -> Notifications.notify(uid, type, attrs) end)
  end

  defp notify_supplier_users(supplier_id, type, attrs) do
    user_ids =
      from(u in User, where: u.supplier_id == ^supplier_id, select: u.id)
      |> Repo.all()

    Enum.each(user_ids, fn uid -> Notifications.notify(uid, type, attrs) end)
  end
end
