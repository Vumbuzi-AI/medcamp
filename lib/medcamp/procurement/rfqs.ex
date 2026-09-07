defmodule Medcamp.Procurement.Rfqs do
  @moduledoc """
  Request for Quotation lifecycle: draft → sent → closed.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Ecto.Multi

  alias Medcamp.Procurement.{
    Rfq,
    RfqItem,
    RfqInvitation,
    References,
    Notifications
  }

  alias Medcamp.Accounts.User

  @pubsub Medcamp.PubSub

  # ---------------------------------------------------------------------------
  # Queries
  # ---------------------------------------------------------------------------

  def list_rfqs(opts \\ %{}) do
    rfqs_query(opts)
    |> preload([:items, :created_by, invitations: :supplier])
    |> Repo.all()
  end

  def list_rfqs_paginated(opts \\ %{}, page \\ 1, per_page \\ 20) do
    rfqs_query(opts)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:items, :created_by, invitations: :supplier])
  end

  def count_rfqs(opts \\ %{}) do
    rfqs_query(opts)
    |> Repo.aggregate(:count, :id)
  end

  def get_rfq!(id) do
    Rfq
    |> Repo.get!(id)
    |> Repo.preload([:items, :created_by, invitations: :supplier])
  end

  def get_rfq(id) do
    case Repo.get(Rfq, id) do
      nil -> nil
      rfq -> Repo.preload(rfq, [:items, :created_by, invitations: :supplier])
    end
  end

  @doc """
  RFQs the supplier has been invited to, with their invitation.
  """
  def list_for_supplier(supplier_id) do
    from(r in Rfq,
      join: inv in RfqInvitation,
      on: inv.rfq_id == r.id,
      where: inv.supplier_id == ^supplier_id,
      where: r.status in ["sent", "closed"],
      order_by: [asc: r.quote_deadline],
      preload: [
        :items,
        invitations: ^from(i in RfqInvitation, where: i.supplier_id == ^supplier_id)
      ]
    )
    |> Repo.all()
  end

  def days_until_deadline(%Rfq{quote_deadline: nil}), do: nil

  def days_until_deadline(%Rfq{quote_deadline: deadline}) do
    Date.diff(deadline, Date.utc_today())
  end

  defp rfqs_query(opts) do
    status = Map.get(opts, :status)
    search = Map.get(opts, :search)

    Rfq
    |> join(:left, [r], u in assoc(r, :created_by))
    |> maybe_filter(:status, status)
    |> maybe_filter_search(search)
    |> order_by([r], desc: r.inserted_at)
  end

  defp maybe_filter(query, _field, nil), do: query
  defp maybe_filter(query, field, value), do: where(query, [q], field(q, ^field) == ^value)

  defp maybe_filter_search(query, nil), do: query
  defp maybe_filter_search(query, ""), do: query

  defp maybe_filter_search(query, search) do
    pattern = "%#{String.trim(search)}%"

    from [r, u] in query,
      where:
        ilike(r.reference, ^pattern) or
          ilike(r.title, ^pattern) or
          ilike(r.department, ^pattern) or
          ilike(r.currency, ^pattern) or
          ilike(u.name, ^pattern)
  end

  # ---------------------------------------------------------------------------
  # Create
  # ---------------------------------------------------------------------------

  @doc """
  Create a new RFQ in draft status with nested items.

  `attrs` may include `items: [%{...}, ...]`.
  """
  def create(attrs, %User{id: user_id}) do
    {items, attrs} = pop_items(attrs)

    attrs =
      attrs
      |> Map.new()
      |> Map.put_new(:reference, References.next_rfq_reference())
      |> Map.put_new(:status, "draft")
      |> Map.put(:created_by_id, user_id)
      |> Map.put_new(:issue_date, Date.utc_today())

    Multi.new()
    |> Multi.insert(:rfq, Rfq.changeset(%Rfq{}, attrs))
    |> Multi.run(:items, fn _repo, %{rfq: rfq} -> insert_items(rfq.id, items) end)
    |> Repo.transaction()
    |> case do
      {:ok, %{rfq: rfq}} -> {:ok, Repo.preload(rfq, :items)}
      {:error, _op, reason, _} -> {:error, reason}
    end
  end

  def update(%Rfq{} = rfq, attrs) do
    {items, attrs} = pop_items(attrs)

    Multi.new()
    |> Multi.update(:rfq, Rfq.changeset(rfq, attrs))
    |> Multi.run(:items, fn _repo, %{rfq: rfq} ->
      if is_nil(items) do
        {:ok, []}
      else
        Repo.delete_all(from i in RfqItem, where: i.rfq_id == ^rfq.id)
        insert_items(rfq.id, items)
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{rfq: rfq}} -> {:ok, Repo.preload(rfq, :items, force: true)}
      {:error, _op, reason, _} -> {:error, reason}
    end
  end

  defp pop_items(attrs) do
    attrs = Map.new(attrs)
    items = Map.get(attrs, :items) || Map.get(attrs, "items")
    {items, Map.drop(attrs, [:items, "items"])}
  end

  defp insert_items(_rfq_id, nil), do: {:ok, []}

  defp insert_items(rfq_id, items) when is_list(items) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    entries =
      items
      |> Enum.with_index(1)
      |> Enum.map(fn {item, index} ->
        item
        |> Map.new()
        |> Map.put(:rfq_id, rfq_id)
        |> Map.put_new(:position, index)
      end)

    results =
      Enum.reduce_while(entries, {:ok, []}, fn attrs, {:ok, acc} ->
        %RfqItem{}
        |> RfqItem.changeset(attrs)
        |> Repo.insert()
        |> case do
          {:ok, item} -> {:cont, {:ok, [item | acc]}}
          {:error, cs} -> {:halt, {:error, cs}}
        end
      end)

    _ = now
    results
  end

  # ---------------------------------------------------------------------------
  # Send (create invitations + notify suppliers)
  # ---------------------------------------------------------------------------

  @doc """
  Transitions RFQ to `sent`, creates invitations for each supplier id, and
  notifies each supplier's users.
  """
  def send(%Rfq{} = rfq, supplier_ids) when is_list(supplier_ids) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    Multi.new()
    |> Multi.update(:rfq, Rfq.changeset(rfq, %{status: "sent"}))
    |> Multi.run(:invitations, fn _repo, %{rfq: rfq} ->
      results =
        Enum.map(supplier_ids, fn sid ->
          %RfqInvitation{}
          |> RfqInvitation.changeset(%{rfq_id: rfq.id, supplier_id: sid, sent_at: now})
          |> Repo.insert(
            on_conflict: [set: [sent_at: now]],
            conflict_target: [:rfq_id, :supplier_id]
          )
        end)

      if Enum.any?(results, &match?({:error, _}, &1)) do
        {:error, results}
      else
        {:ok, Enum.map(results, fn {:ok, inv} -> inv end)}
      end
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{rfq: rfq}} ->
        Enum.each(supplier_ids, fn sid ->
          broadcast_supplier(sid, {:rfq_sent, rfq})

          notify_supplier_users(sid, "rfq_issued", %{
            title: "New request for quotation: #{rfq.reference}",
            body: rfq.title,
            resource_type: "rfq",
            resource_id: rfq.id
          })
        end)

        broadcast_all({:rfq_sent, rfq})
        {:ok, Repo.preload(rfq, [:items, :invitations])}

      {:error, _op, reason, _} ->
        {:error, reason}
    end
  end

  def close(%Rfq{} = rfq) do
    rfq
    |> Rfq.changeset(%{status: "closed"})
    |> Repo.update()
    |> case do
      {:ok, updated} ->
        broadcast_all({:rfq_closed, updated})
        {:ok, updated}

      error ->
        error
    end
  end

  def mark_viewed(%RfqInvitation{viewed_at: nil} = inv) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    inv
    |> RfqInvitation.changeset(%{viewed_at: now})
    |> Repo.update()
  end

  def mark_viewed(%RfqInvitation{} = inv), do: {:ok, inv}

  # ---------------------------------------------------------------------------
  # PubSub
  # ---------------------------------------------------------------------------

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
