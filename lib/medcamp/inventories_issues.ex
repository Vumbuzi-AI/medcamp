defmodule Medcamp.InventoriesIssues do
  @moduledoc """
  The InventoriesIssues context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Medcamp.Batches
  alias Medcamp.DrugBatches

  alias Medcamp.InventoriesIssues.InventoryIssued

  @doc """
  Returns the list of inventories_issued.

  ## Examples

      iex> list_inventories_issued()
      [%InventoryIssued{}, ...]

  """
  def list_inventories_issued do
    from(ii in InventoryIssued, order_by: [desc: ii.inserted_at])
    |> Repo.all()
    |> Repo.preload([:batch, :inventory_received, :assigned_to, :inventory_manager, :requisition])
  end

  @doc """
  Returns filtered inventories_issued by department (location), quantity, and item (brand/generic/gtin/batch).

  Filters:
  - :location - department allocation (Pharmacy, Nurse, Laboratory, etc.)
  - :quantity_min - minimum quantity allocated
  - :quantity_max - maximum quantity allocated
  - :item_search - search in brand_name, generic_name, gtin, batch, or serial
  """
  def filter_inventories_issued(filters \\ %{}) do
    filters
    |> build_inventories_issued_query()
    |> Repo.all()
    |> Repo.preload([:batch, :inventory_received, :assigned_to, :inventory_manager, :requisition])
  end

  @doc """
  Returns paginated list of inventories_issued with filters.
  Options: page (1-based), per_page (default 20).
  """
  def list_inventories_issued_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    query = build_inventories_issued_query(filters)
    offset = max(0, (page - 1) * per_page)

    query
    |> limit(^per_page)
    |> offset(^offset)
    |> Repo.all()
    |> Repo.preload([:batch, :inventory_received, :assigned_to, :inventory_manager, :requisition])
  end

  @doc """
  Returns inventories issued specifically against a requisition.
  Ordered most recent first.
  """
  def list_inventories_issued_for_requisition(requisition_id) do
    from(ii in InventoryIssued,
      where: ii.requisition_id == ^requisition_id,
      order_by: [desc: ii.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload([:batch, :inventory_received, :assigned_to, :inventory_manager, :requisition])
  end

  @doc """
  Returns total count of inventories_issued matching filters.
  """
  def count_inventories_issued(filters \\ %{}) do
    filters
    |> build_inventories_issued_query()
    |> Repo.aggregate(:count, :id)
  end

  defp build_inventories_issued_query(filters) do
    base =
      from ii in InventoryIssued,
        left_join: b in assoc(ii, :batch),
        left_join: ir in assoc(ii, :inventory_received),
        order_by: [desc: ii.inserted_at]

    base
    |> apply_location_filter(filters["location"] || filters[:location])
    |> apply_quantity_min_filter(filters["quantity_min"] || filters[:quantity_min])
    |> apply_quantity_max_filter(filters["quantity_max"] || filters[:quantity_max])
    |> apply_item_search_filter(filters["item_search"] || filters[:item_search])
  end

  defp apply_location_filter(query, nil), do: query
  defp apply_location_filter(query, ""), do: query

  defp apply_location_filter(query, location) do
    from [ii, b, ir] in query, where: ii.location == ^location
  end

  defp apply_quantity_min_filter(query, nil), do: query
  defp apply_quantity_min_filter(query, ""), do: query

  defp apply_quantity_min_filter(query, min) when is_binary(min) do
    case Integer.parse(min) do
      {n, _} -> from [ii, b, ir] in query, where: ii.quantity >= ^n
      _ -> query
    end
  end

  defp apply_quantity_min_filter(query, min) when is_integer(min) do
    from [ii, b, ir] in query, where: ii.quantity >= ^min
  end

  defp apply_quantity_max_filter(query, nil), do: query
  defp apply_quantity_max_filter(query, ""), do: query

  defp apply_quantity_max_filter(query, max) when is_binary(max) do
    case Integer.parse(max) do
      {n, _} -> from [ii, b, ir] in query, where: ii.quantity <= ^n
      _ -> query
    end
  end

  defp apply_quantity_max_filter(query, max) when is_integer(max) do
    from [ii, b, ir] in query, where: ii.quantity <= ^max
  end

  defp apply_item_search_filter(query, nil), do: query
  defp apply_item_search_filter(query, ""), do: query

  defp apply_item_search_filter(query, term) do
    term = String.trim(term)
    if term == "", do: query, else: apply_item_search_filter_term(query, "%#{term}%")
  end

  defp apply_item_search_filter_term(query, pattern) do
    from [ii, b, ir] in query,
      where:
        ilike(ir.brand_name, ^pattern) or
          ilike(ir.generic_name, ^pattern) or
          ilike(ir.gtin, ^pattern) or
          ilike(ii.gtin, ^pattern) or
          ilike(b.batch, ^pattern) or
          ilike(b.serial, ^pattern)
  end

  @doc """
  Returns inventories issued for a specific inventory_received item, with optional filters.
  Filters: location, batch, quantity_min, quantity_max, date_from, date_to, assigned_to.
  """
  def list_inventories_issued_for_item(inventory_received_id, filters \\ %{}) do
    base =
      from ii in InventoryIssued,
        left_join: b in assoc(ii, :batch),
        left_join: ir in assoc(ii, :inventory_received),
        left_join: u in assoc(ii, :assigned_to),
        where: ii.inventory_received_id == ^inventory_received_id,
        order_by: [desc: ii.inserted_at]

    base
    |> apply_location_filter(filters["location"] || filters[:location])
    |> apply_quantity_min_filter(filters["quantity_min"] || filters[:quantity_min])
    |> apply_quantity_max_filter(filters["quantity_max"] || filters[:quantity_max])
    |> apply_date_from_filter(filters["date_from"] || filters[:date_from])
    |> apply_date_to_filter(filters["date_to"] || filters[:date_to])
    |> apply_assigned_to_filter(filters["assigned_to"] || filters[:assigned_to])
    |> Repo.all()
    |> Repo.preload([:batch, :inventory_received, :assigned_to, :inventory_manager, :requisition])
  end

  defp apply_date_from_filter(query, nil), do: query
  defp apply_date_from_filter(query, ""), do: query

  defp apply_date_from_filter(query, date_str) when is_binary(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} ->
        dt = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
        from [ii, b, ir] in query, where: ii.inserted_at >= ^dt

      _ ->
        query
    end
  end

  defp apply_date_to_filter(query, nil), do: query
  defp apply_date_to_filter(query, ""), do: query

  defp apply_date_to_filter(query, date_str) when is_binary(date_str) do
    case Date.from_iso8601(date_str) do
      {:ok, date} ->
        dt = DateTime.new!(date, ~T[23:59:59], "Etc/UTC")
        from [ii, b, ir] in query, where: ii.inserted_at <= ^dt

      _ ->
        query
    end
  end

  defp apply_assigned_to_filter(query, nil), do: query
  defp apply_assigned_to_filter(query, ""), do: query

  defp apply_assigned_to_filter(query, term) do
    pattern = "%#{String.trim(term)}%"

    from [ii, b, ir, u] in query,
      where: ilike(u.email, ^pattern) or ilike(u.name, ^pattern)
  end

  @doc """
  Gets a single inventory_issued.

  Raises `Ecto.NoResultsError` if the Inventory issued does not exist.

  ## Examples

      iex> get_inventory_issued!(123)
      %InventoryIssued{}

      iex> get_inventory_issued!(456)
      ** (Ecto.NoResultsError)

  """
  def get_inventory_issued!(id),
    do:
      Repo.get!(InventoryIssued, id)
      |> Repo.preload([
        :batch,
        :inventory_received,
        :assigned_to,
        :inventory_manager,
        :requisition
      ])

  @doc """
  Creates a inventory_issued.

  ## Examples

      iex> create_inventory_issued(%{field: value})
      {:ok, %InventoryIssued{}}

      iex> create_inventory_issued(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_inventory_issued(attrs \\ %{}) do
    drug_batch_id = Map.get(attrs, "drug_batch_id") || Map.get(attrs, :drug_batch_id)
    attrs_clean = Map.drop(attrs, ["drug_batch_id", :drug_batch_id])

    case %InventoryIssued{}
         |> InventoryIssued.changeset(attrs_clean)
         |> Repo.insert() do
      {:ok, inventory_issued} = result ->
        qty = inventory_issued.quantity || 0

        if drug_batch_id do
          # Issuing from pharmacy drug stock — reduce DrugBatch, not raw Batch
          drug_batch = DrugBatches.get_drug_batch!(drug_batch_id)
          new_remaining = max(0, (drug_batch.remaining_quantity || 0) - qty)
          DrugBatches.update_drug_batch(drug_batch, %{remaining_quantity: new_remaining})
        else
          # Issuing from raw inventory batch
          if inventory_issued.batch_id do
            batch = Batches.get_batch!(inventory_issued.batch_id)
            new_remaining = max(0, (batch.remaining_quantity || 0) - qty)

            Batches.update_batch(batch, %{
              has_been_issued: true,
              remaining_quantity: new_remaining
            })
          end
        end

        result

      error ->
        error
    end
  end

  @doc """
  Updates a inventory_issued.

  ## Examples

      iex> update_inventory_issued(inventory_issued, %{field: new_value})
      {:ok, %InventoryIssued{}}

      iex> update_inventory_issued(inventory_issued, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_inventory_issued(%InventoryIssued{} = inventory_issued, attrs) do
    inventory_issued
    |> InventoryIssued.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a inventory_issued.

  ## Examples

      iex> delete_inventory_issued(inventory_issued)
      {:ok, %InventoryIssued{}}

      iex> delete_inventory_issued(inventory_issued)
      {:error, %Ecto.Changeset{}}

  """
  def delete_inventory_issued(%InventoryIssued{} = inventory_issued) do
    Repo.delete(inventory_issued)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking inventory_issued changes.

  ## Examples

      iex> change_inventory_issued(inventory_issued)
      %Ecto.Changeset{data: %InventoryIssued{}}

  """
  def change_inventory_issued(%InventoryIssued{} = inventory_issued, attrs \\ %{}) do
    InventoryIssued.changeset(inventory_issued, attrs)
  end
end
