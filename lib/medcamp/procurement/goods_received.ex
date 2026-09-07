defmodule Medcamp.Procurement.GoodsReceived do
  @moduledoc """
  Goods Received Note lifecycle: draft → pending_review → finalised|flagged.

  Finalisation is irreversible: it updates the related invoice to
  `grn_confirmed` and broadcasts `{:grn_finalised, grn}`.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Ecto.Multi

  alias Medcamp.Procurement.{
    GoodsReceivedNote,
    GrnItem,
    Invoice,
    ShipmentAdvice,
    References,
    Notifications
  }

  alias Medcamp.Accounts.User

  @pubsub Medcamp.PubSub

  def list_grns(opts \\ %{}) do
    grns_query(opts)
    |> Repo.all()
    |> Repo.preload([:invoice, :supplier, :received_by, :finalised_by])
  end

  def list_grns_paginated(opts \\ %{}, page \\ 1, per_page \\ 20) do
    grns_query(opts)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:invoice, :supplier, :received_by, :finalised_by])
  end

  def count_grns(opts \\ %{}) do
    grns_query(opts)
    |> Repo.aggregate(:count, :id)
  end

  def get_grn!(id) do
    GoodsReceivedNote
    |> Repo.get!(id)
    |> Repo.preload([
      :purchase_order,
      :invoice,
      :shipment_advice,
      :supplier,
      :received_by,
      :finalised_by,
      items: :purchase_order_item
    ])
  end

  def get_grn(id) do
    case Repo.get(GoodsReceivedNote, id) do
      nil ->
        nil

      grn ->
        Repo.preload(grn, [
          :purchase_order,
          :invoice,
          :shipment_advice,
          :supplier,
          :received_by,
          :finalised_by,
          items: :purchase_order_item
        ])
    end
  end

  defp maybe_filter(query, _field, nil), do: query
  defp maybe_filter(query, field, value), do: where(query, [q], field(q, ^field) == ^value)

  defp grns_query(opts) do
    search = Map.get(opts, :search)

    GoodsReceivedNote
    |> join(:left, [g], inv in assoc(g, :invoice))
    |> join(:left, [g, inv], sup in assoc(g, :supplier))
    |> join(:left, [g, inv, sup], received in assoc(g, :received_by))
    |> join(:left, [g, inv, sup, received], finalised in assoc(g, :finalised_by))
    |> maybe_filter(:supplier_id, Map.get(opts, :supplier_id))
    |> maybe_filter(:status, Map.get(opts, :status))
    |> maybe_filter_search(search)
    |> order_by([g], desc: g.inserted_at)
  end

  defp maybe_filter_search(query, nil), do: query
  defp maybe_filter_search(query, ""), do: query

  defp maybe_filter_search(query, search) do
    pattern = "%#{String.trim(search)}%"

    from [g, inv, sup, received, finalised] in query,
      where:
        ilike(g.reference, ^pattern) or
          ilike(inv.reference, ^pattern) or
          ilike(sup.legal_name, ^pattern) or
          ilike(sup.name, ^pattern) or
          ilike(received.name, ^pattern) or
          ilike(finalised.name, ^pattern)
  end

  # ---------------------------------------------------------------------------
  # Create (pre-populates items from the shipment)
  # ---------------------------------------------------------------------------

  def create(attrs, %User{id: user_id}) do
    {items, attrs} = pop_items(attrs)

    attrs =
      attrs
      |> Map.new()
      |> Map.put_new(:reference, References.next_grn_reference())
      |> Map.put(:received_by_id, user_id)
      |> Map.put_new(:status, "draft")
      |> Map.put_new(:received_date, Date.utc_today())
      |> Map.put_new(:received_time, Time.utc_now() |> Time.truncate(:second))

    Multi.new()
    |> Multi.insert(:grn, GoodsReceivedNote.changeset(%GoodsReceivedNote{}, attrs))
    |> Multi.run(:items, fn _repo, %{grn: grn} -> insert_items(grn.id, items) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{grn: grn}} -> {:ok, Repo.preload(grn, items: :purchase_order_item)}
      {:error, _op, reason, _} -> {:error, reason}
    end
  end

  defp pop_items(attrs) do
    attrs = Map.new(attrs)
    items = Map.get(attrs, :items) || Map.get(attrs, "items")
    {items, Map.drop(attrs, [:items, "items"])}
  end

  defp insert_items(_grn_id, nil), do: {:ok, []}

  defp insert_items(grn_id, items) do
    Enum.reduce_while(Enum.with_index(items, 1), {:ok, []}, fn {item, idx}, {:ok, acc} ->
      attrs =
        item
        |> Map.new()
        |> Map.put(:grn_id, grn_id)
        |> Map.put_new(:position, idx)

      %GrnItem{}
      |> GrnItem.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, rec} -> {:cont, {:ok, [rec | acc]}}
        {:error, cs} -> {:halt, {:error, cs}}
      end
    end)
  end

  # ---------------------------------------------------------------------------
  # Update items (inspection)
  # ---------------------------------------------------------------------------

  def update_grn(%GoodsReceivedNote{} = grn, attrs) do
    grn
    |> GoodsReceivedNote.changeset(attrs)
    |> Repo.update()
  end

  def update_item(%GrnItem{} = item, attrs) do
    item
    |> GrnItem.changeset(attrs)
    |> Repo.update()
  end

  # ---------------------------------------------------------------------------
  # Flag
  # ---------------------------------------------------------------------------

  def flag_for_review(%GoodsReceivedNote{} = grn) do
    grn
    |> GoodsReceivedNote.changeset(%{status: "flagged"})
    |> Repo.update()
    |> case do
      {:ok, updated} ->
        broadcast_all({:grn_flagged, updated})
        {:ok, updated}

      error ->
        error
    end
  end

  # ---------------------------------------------------------------------------
  # Finalise — irreversible, updates invoice → grn_confirmed + broadcasts
  # ---------------------------------------------------------------------------

  def finalise(%GoodsReceivedNote{status: "finalised"} = grn, _user), do: {:ok, grn}

  def finalise(%GoodsReceivedNote{} = grn, %User{id: user_id}) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Multi.new()
    |> Multi.update(
      :grn,
      GoodsReceivedNote.changeset(grn, %{
        status: "finalised",
        finalised_by_id: user_id,
        finalised_at: now
      })
    )
    |> Multi.run(:invoice, fn _repo, %{grn: grn} ->
      case Repo.get(Invoice, grn.invoice_id) do
        nil -> {:ok, nil}
        inv -> Invoice.changeset(inv, %{status: "grn_confirmed"}) |> Repo.update()
      end
    end)
    |> Multi.run(:shipment, fn _repo, %{grn: grn} ->
      case Repo.get(ShipmentAdvice, grn.shipment_advice_id) do
        nil -> {:ok, nil}
        sa -> ShipmentAdvice.changeset(sa, %{status: "grn_created"}) |> Repo.update()
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{grn: grn, invoice: invoice}} ->
        full = Repo.preload(grn, [:supplier, items: :purchase_order_item], force: true)
        broadcast_all({:grn_finalised, full})
        broadcast_supplier(full.supplier_id, {:grn_finalised, full})

        if invoice do
          broadcast_all({:invoice_grn_confirmed, invoice})
          broadcast_supplier(invoice.supplier_id, {:invoice_grn_confirmed, invoice})
        end

        notify_supplier_users(full.supplier_id, "grn_finalised", %{
          title: "Goods received: #{full.reference}",
          body: "Your delivery has been confirmed.",
          resource_type: "grn",
          resource_id: full.id
        })

        notify_procurement_team("grn_finalised", %{
          title: "GRN finalised: #{full.reference}",
          body: "Goods received note has been finalised.",
          resource_type: "grn",
          resource_id: full.id
        })

        {:ok, full}

      {:error, _op, reason, _} ->
        {:error, reason}
    end
  end

  # ---------------------------------------------------------------------------
  # Summary / variance helpers
  # ---------------------------------------------------------------------------

  @doc """
  Summary of a GRN's items: accepted/partial/rejected counts, total qty received.
  """
  def compute_summary(%GoodsReceivedNote{} = grn) do
    items = load_items(grn)

    accepted = Enum.count(items, &(&1.condition == "accepted"))
    partial = Enum.count(items, &(&1.condition == "partial"))
    rejected = Enum.count(items, &(&1.condition == "rejected"))

    qty_received =
      Enum.reduce(items, Decimal.new(0), fn i, acc ->
        Decimal.add(acc, i.quantity_received || Decimal.new(0))
      end)

    value =
      Enum.reduce(items, Decimal.new(0), fn i, acc ->
        price =
          case i.purchase_order_item do
            %{unit_price: p} when not is_nil(p) -> p
            _ -> Decimal.new(0)
          end

        Decimal.add(acc, Decimal.mult(i.quantity_received || Decimal.new(0), price))
      end)

    %{
      accepted: accepted,
      partial: partial,
      rejected: rejected,
      quantity_received: qty_received,
      value: value
    }
  end

  def has_variances?(%GoodsReceivedNote{} = grn) do
    grn
    |> load_items()
    |> Enum.any?(fn item ->
      item.variance && not Decimal.equal?(item.variance, 0)
    end)
  end

  defp load_items(%GoodsReceivedNote{items: %Ecto.Association.NotLoaded{}} = grn) do
    Repo.preload(grn, items: :purchase_order_item).items
  end

  defp load_items(%GoodsReceivedNote{items: items}) when is_list(items) do
    if Enum.all?(items, &match?(%{purchase_order_item: %{}}, &1)) do
      items
    else
      items
      |> Repo.preload(:purchase_order_item)
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

  defp notify_procurement_team(type, attrs) do
    user_ids =
      from(u in User,
        where: u.role in ["procurement_officer", "stores_officer", "finance_officer", "admin"],
        select: u.id
      )
      |> Repo.all()

    Enum.each(user_ids, fn uid -> Notifications.notify(uid, type, attrs) end)
  end
end
