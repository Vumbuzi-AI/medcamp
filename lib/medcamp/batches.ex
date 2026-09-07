defmodule Medcamp.Batches do
  @moduledoc """
  The Batches context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Batches.Batch
  alias Medcamp.ExpiryFilter
  alias Medcamp.InventoriesReceived.InventoryReceived

  @doc """
  Returns all InventoryReceived items together with their aggregated batch stats:
  total_remaining, batch_count, earliest_expiry.
  Only includes items that have at least one batch.
  Ordered by brand_name ascending.
  """
  def list_in_store do
    from(ir in InventoryReceived,
      join: b in Batch,
      on: b.inventory_received_id == ir.id,
      group_by: ir.id,
      having: coalesce(sum(b.remaining_quantity), 0) > 0,
      select: %{
        ir: ir,
        total_remaining: coalesce(sum(b.remaining_quantity), 0),
        batch_count: count(b.id),
        earliest_expiry: min(b.expiry)
      },
      order_by: [asc: ir.brand_name]
    )
    |> Repo.all()
  end

  @doc """
  Returns all batches for a given inventory_received_id, ordered by expiry ASC.
  """
  def get_batches_for_in_store(inventory_received_id) do
    Repo.all(
      from b in Batch,
        where: b.inventory_received_id == ^inventory_received_id,
        order_by: [asc: b.expiry]
    )
  end

  @doc """
  Returns the list of batches.

  ## Examples

      iex> list_batches()
      [%Batch{}, ...]

  """
  def list_batches do
    Repo.all(Batch)
    |> Repo.preload([:inventory_received])
  end

  @doc """
  Returns batches filtered by item_search (gtin, batch, brand/generic), expiry range.
  Filters: item_search, expiry_status (see `Medcamp.ExpiryFilter`),
  expiry_from, expiry_to (date strings), inventory_received_id.
  """
  def filter_batches(filters \\ %{}) do
    filters
    |> build_batches_filter_query()
    |> Repo.all()
    |> Repo.preload([:inventory_received])
  end

  @doc """
  Returns paginated list of batches with filters. page 1-based, per_page default 20.
  """
  def list_batches_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    query = build_batches_filter_query(filters)
    offset = max(0, (page - 1) * per_page)

    query
    |> limit(^per_page)
    |> offset(^offset)
    |> Repo.all()
    |> Repo.preload([:inventory_received])
  end

  @doc """
  Returns total count of batches matching filters.
  """
  def count_batches(filters \\ %{}) do
    filters
    |> build_batches_filter_query()
    |> Repo.aggregate(:count, :id)
  end

  defp build_batches_filter_query(filters) do
    base =
      from b in Batch,
        left_join: ir in assoc(b, :inventory_received),
        order_by: [desc: b.inserted_at]

    base
    |> apply_batch_item_search(filters["item_search"] || filters[:item_search])
    |> apply_batch_expiry(filters)
    |> apply_batch_inventory_received_filter(
      filters["inventory_received_id"] || filters[:inventory_received_id]
    )
  end

  # The preset status and the custom from/to range narrow to their intersection
  # (see `Medcamp.ExpiryFilter.bounds/4`), so neither silently overrides the other.
  defp apply_batch_expiry(query, filters) do
    {from, to} =
      normalize_expiry_range(
        filters["expiry_from"] || filters[:expiry_from],
        filters["expiry_to"] || filters[:expiry_to]
      )

    {from, to} =
      ExpiryFilter.bounds(filters["expiry_status"] || filters[:expiry_status], from, to)

    query
    |> apply_batch_expiry_from(from)
    |> apply_batch_expiry_to(to)
  end

  defp apply_batch_item_search(query, nil), do: query
  defp apply_batch_item_search(query, ""), do: query

  defp apply_batch_item_search(query, term) do
    term = String.trim(term)
    if term == "", do: query, else: apply_batch_item_search_term(query, "%#{term}%")
  end

  defp apply_batch_item_search_term(query, pattern) do
    from [b, ir] in query,
      where:
        ilike(b.gtin, ^pattern) or
          ilike(b.batch, ^pattern) or
          ilike(b.serial, ^pattern) or
          (not is_nil(ir) and
             (ilike(ir.brand_name, ^pattern) or ilike(ir.generic_name, ^pattern) or
                ilike(ir.gtin, ^pattern)))
  end

  # Guards against an inverted range (expiry_to before expiry_from) reaching the
  # query — the drawer's client-side min/max only reflects the last applied
  # state, so an inverted pair can still be submitted mid-edit.
  defp normalize_expiry_range(from, to) when is_binary(from) and is_binary(to) do
    with {:ok, from_date} <- Date.from_iso8601(from),
         {:ok, to_date} <- Date.from_iso8601(to),
         :gt <- Date.compare(from_date, to_date) do
      {to, from}
    else
      _ -> {from, to}
    end
  end

  defp normalize_expiry_range(from, to), do: {from, to}

  defp apply_batch_expiry_from(query, nil), do: query
  defp apply_batch_expiry_from(query, ""), do: query

  defp apply_batch_expiry_from(query, date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, _d} -> from b in query, where: b.expiry >= ^date
      _ -> query
    end
  end

  defp apply_batch_expiry_from(query, _), do: query

  defp apply_batch_expiry_to(query, nil), do: query
  defp apply_batch_expiry_to(query, ""), do: query

  defp apply_batch_expiry_to(query, date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, _d} -> from b in query, where: b.expiry <= ^date
      _ -> query
    end
  end

  defp apply_batch_expiry_to(query, _), do: query

  defp apply_batch_inventory_received_filter(query, nil), do: query
  defp apply_batch_inventory_received_filter(query, ""), do: query

  defp apply_batch_inventory_received_filter(query, id) when is_binary(id) do
    case Integer.parse(id) do
      {n, _} -> from [b, ir] in query, where: b.inventory_received_id == ^n
      _ -> query
    end
  end

  defp apply_batch_inventory_received_filter(query, id) when is_integer(id),
    do: from([b, ir] in query, where: b.inventory_received_id == ^id)

  defp apply_batch_inventory_received_filter(query, _), do: query

  @doc """
  Returns a map with `quantity_in_stock` (total remaining across all batches)
  for a given inventory_received_id. Returns nil if no batches exist.
  """
  def get_inventory_by_received_id(nil), do: nil
  def get_inventory_by_received_id(""), do: nil

  def get_inventory_by_received_id(inventory_received_id) do
    total =
      Repo.aggregate(
        from(b in Batch, where: b.inventory_received_id == ^inventory_received_id),
        :sum,
        :remaining_quantity
      )

    if total, do: %{quantity_in_stock: total}, else: nil
  end

  def list_batches_for_inventory_received(inventory_received_id) do
    Repo.all(from b in Batch, where: b.inventory_received_id == ^inventory_received_id)
      end

  def list_batches_for_inventory_received_paginated(
        inventory_received_id,
        page \\ 1,
        per_page \\ 20,
        filters \\ %{}
      ) do
    batches_for_inventory_received_query(inventory_received_id, filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
      end

  def count_batches_for_inventory_received(inventory_received_id, filters \\ %{}) do
    batches_for_inventory_received_query(inventory_received_id, filters)
    |> exclude(:order_by)
    |> select([b], count(b.id))
    |> Repo.one()
  end

  # Ordered by expiry ascending (first expiry, first out) rather than by
  # insertion like the cross-item listing, since this is the list a user picks
  # a batch to issue from.
  defp batches_for_inventory_received_query(inventory_received_id, filters) do
    from(b in Batch,
      where: b.inventory_received_id == ^inventory_received_id,
      order_by: [asc: b.expiry]
    )
    |> apply_batch_expiry(filters)
  end

  def list_batches_for_select_for_inventory_received(nil) do
    []
  end

  def list_batches_for_select_for_inventory_received("") do
    []
  end

  @doc """
  Returns options for batch select when issuing inventory: [{label, id}, ...].
  Label shows batch number and expiry (e.g. "BATCH123 (Exp: 2025-06-30)").
  Ordered by expiry ASC (first expiry, first out).
  """
  def list_batches_for_select_for_inventory_received(inventory_received_id) do
    list_batches_with_expiry_for_inventory_received(inventory_received_id)
    |> Enum.map(fn %{id: id, batch: batch, expiry: expiry} ->
      {format_batch_option_label(batch, expiry), id}
    end)
  end

  @doc """
  Returns list of batches with id, batch, expiry, remaining_quantity for display (e.g. issue form).
  Ordered by expiry ASC (first expiry, first out).
  """
  def list_batches_with_expiry_for_inventory_received(nil), do: []
  def list_batches_with_expiry_for_inventory_received(""), do: []

  def list_batches_with_expiry_for_inventory_received(inventory_received_id) do
    Repo.all(
      from b in Batch,
        where: b.inventory_received_id == ^inventory_received_id and b.remaining_quantity > 0,
        order_by: [asc: b.expiry],
        select: {b.id, b.batch, b.expiry, b.remaining_quantity}
    )
    |> Enum.map(fn {id, batch, expiry, remaining_quantity} ->
      %{id: id, batch: batch, expiry: expiry, remaining_quantity: remaining_quantity}
    end)
  end

  defp format_batch_option_label(batch, nil), do: "#{batch} (Exp: N/A)"
  defp format_batch_option_label(batch, ""), do: "#{batch} (Exp: N/A)"

  defp format_batch_option_label(batch, expiry) when is_binary(expiry) do
    "#{batch} (Exp: #{expiry})"
  end

  defp format_batch_option_label(batch, _), do: "#{batch} (Exp: N/A)"

  @doc """
  Gets a single batch.

  Raises `Ecto.NoResultsError` if the Batch does not exist.

  ## Examples

      iex> get_batch!(123)
      %Batch{}

      iex> get_batch!(456)
      ** (Ecto.NoResultsError)

  """
  def get_batch!(id), do: Repo.get!(Batch, id) |> Repo.preload([:inventory_received])

  @doc """
  Creates a batch.

  ## Examples

      iex> create_batch(%{field: value})
      {:ok, %Batch{}}

      iex> create_batch(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_batch(attrs \\ %{}) do
    %Batch{}
    |> Batch.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a batch.

  ## Examples

      iex> update_batch(batch, %{field: new_value})
      {:ok, %Batch{}}

      iex> update_batch(batch, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_batch(%Batch{} = batch, attrs) do
    batch
    |> Batch.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a batch.

  ## Examples

      iex> delete_batch(batch)
      {:ok, %Batch{}}

      iex> delete_batch(batch)
      {:error, %Ecto.Changeset{}}

  """
  def delete_batch(%Batch{} = batch) do
    Repo.delete(batch)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking batch changes.

  ## Examples

      iex> change_batch(batch)
      %Ecto.Changeset{data: %Batch{}}

  """
  def change_batch(%Batch{} = batch, attrs \\ %{}) do
    Batch.changeset(batch, attrs)
  end

  def get_batch_by_gtin_and_batch(nil, _batch) do
    nil
  end

  def get_batch_by_gtin_and_batch(_, nil) do
    nil
  end

  def get_batch_by_gtin_and_batch(nil, nil) do
    nil
  end

  def get_batch_by_gtin_and_batch(gtin, batch) do
    Repo.one(
      from b in Batch,
        where: b.gtin == ^gtin and b.batch == ^batch,
        limit: 1
    )
  end

  @doc """
  Finds a batch by GTIN (from inventory_received or batch) and batch number.
  Used for API verification lookup; matches DataMatrixParser logic.
  """
  def get_batch_by_gtin_and_batch_number(gtin, batch_number)
      when is_binary(gtin) and is_binary(batch_number) do
    # Try batch.gtin first, then join with inventory_received.gtin
    Repo.one(
      from b in Batch,
        left_join: ir in assoc(b, :inventory_received),
        where: b.batch == ^batch_number and (b.gtin == ^gtin or ir.gtin == ^gtin),
        preload: [inventory_received: ir],
        limit: 1
    )
  end

  def get_batch_by_gtin_and_batch_number(_, _), do: nil

  def get_batch_by_gtin_14_and_batch_number(gtin, batch_number)
      when is_binary(gtin) and is_binary(batch_number) do
    Repo.one(
      from b in Batch,
        left_join: ir in assoc(b, :inventory_received),
        where:
          b.batch == ^batch_number and
            (fragment("lpad(?, 14, '0')", b.gtin) == ^gtin or
               fragment("lpad(?, 14, '0')", ir.gtin) == ^gtin),
        preload: [inventory_received: ir],
        limit: 1
    )
  end

  def get_batch_by_gtin_14_and_batch_number(_, _), do: nil
end
