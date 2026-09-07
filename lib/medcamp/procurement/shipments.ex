defmodule Medcamp.Procurement.Shipments do
  @moduledoc """
  Shipment advice lifecycle: create → submit → received → grn_created.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Ecto.Multi

  alias Medcamp.Procurement.{
    ShipmentAdvice,
    ShipmentItem,
    References,
    Notifications
  }

  alias Medcamp.Accounts.User

  @pubsub Medcamp.PubSub

  def list_shipments(opts \\ []) do
    ShipmentAdvice
    |> maybe_filter(:supplier_id, Keyword.get(opts, :supplier_id))
    |> maybe_filter(:status, Keyword.get(opts, :status))
    |> order_by([s], desc: s.inserted_at)
    |> Repo.all()
  end

  def get_shipment!(id) do
    ShipmentAdvice
    |> Repo.get!(id)
    |> Repo.preload([:purchase_order, :invoice, :supplier, items: :purchase_order_item])
  end

  def get_shipment(id) do
    case Repo.get(ShipmentAdvice, id) do
      nil -> nil
      sa -> Repo.preload(sa, [:purchase_order, :invoice, :supplier, items: :purchase_order_item])
    end
  end

  defp maybe_filter(query, _field, nil), do: query
  defp maybe_filter(query, field, value), do: where(query, [q], field(q, ^field) == ^value)

  def create(attrs, _user \\ nil) do
    {items, attrs} = pop_items(attrs)

    attrs =
      attrs
      |> Map.new()
      |> Map.put_new(:reference, References.next_shipment_advice_reference())
      |> Map.put_new(:status, "submitted")

    Multi.new()
    |> Multi.insert(:sa, ShipmentAdvice.changeset(%ShipmentAdvice{}, attrs))
    |> Multi.run(:items, fn _repo, %{sa: sa} -> insert_items(sa.id, items) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{sa: sa}} -> {:ok, Repo.preload(sa, items: :purchase_order_item)}
      {:error, _op, reason, _} -> {:error, reason}
    end
  end

  def update(%ShipmentAdvice{} = sa, attrs) do
    {items, attrs} = pop_items(attrs)

    Multi.new()
    |> Multi.update(:sa, ShipmentAdvice.changeset(sa, attrs))
    |> Multi.run(:items, fn _repo, %{sa: sa} ->
      if is_nil(items) do
        {:ok, []}
      else
        Repo.delete_all(from i in ShipmentItem, where: i.shipment_advice_id == ^sa.id)
        insert_items(sa.id, items)
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{sa: sa}} -> {:ok, Repo.preload(sa, items: :purchase_order_item, force: true)}
      {:error, _op, reason, _} -> {:error, reason}
    end
  end

  defp pop_items(attrs) do
    attrs = Map.new(attrs)
    items = Map.get(attrs, :items) || Map.get(attrs, "items")
    {items, Map.drop(attrs, [:items, "items"])}
  end

  defp insert_items(_sa_id, nil), do: {:ok, []}

  defp insert_items(sa_id, items) do
    Enum.reduce_while(Enum.with_index(items, 1), {:ok, []}, fn {item, idx}, {:ok, acc} ->
      attrs =
        item
        |> Map.new()
        |> Map.put(:shipment_advice_id, sa_id)
        |> Map.put_new(:position, idx)

      %ShipmentItem{}
      |> ShipmentItem.changeset(attrs)
      |> Repo.insert()
      |> case do
        {:ok, rec} -> {:cont, {:ok, [rec | acc]}}
        {:error, cs} -> {:halt, {:error, cs}}
      end
    end)
  end

  def submit(%ShipmentAdvice{} = sa) do
    sa
    |> ShipmentAdvice.changeset(%{status: "submitted"})
    |> Repo.update()
    |> case do
      {:ok, updated} ->
        broadcast_all({:shipment_submitted, updated})

        notify_procurement_team(%{
          title: "Shipment submitted: #{updated.reference}",
          body: "A supplier has submitted a shipment advice.",
          resource_type: "shipment_advice",
          resource_id: updated.id
        })

        {:ok, updated}

      error ->
        error
    end
  end

  def mark_received(%ShipmentAdvice{} = sa) do
    sa |> ShipmentAdvice.changeset(%{status: "received"}) |> Repo.update()
  end

  def mark_grn_created(%ShipmentAdvice{} = sa) do
    sa |> ShipmentAdvice.changeset(%{status: "grn_created"}) |> Repo.update()
  end

  defp broadcast_all(msg), do: Phoenix.PubSub.broadcast(@pubsub, "procurement:all", msg)

  defp notify_procurement_team(attrs) do
    user_ids =
      from(u in User,
        where: u.role in ["procurement_officer", "stores_officer", "admin"],
        select: u.id
      )
      |> Repo.all()

    Enum.each(user_ids, fn uid ->
      Notifications.notify(uid, "shipment_submitted", attrs)
    end)
  end
end
