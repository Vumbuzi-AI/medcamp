defmodule Medcamp.InventoriesReceived do
  @moduledoc """
  The InventoriesReceived context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Batches.Batch
  alias Medcamp.ExpiryFilter
  alias Medcamp.InventoriesReceived.InventoryReceived

  @doc """
  Returns the list of inventories_received.

  ## Examples

      iex> list_inventories_received()
      [%InventoryReceived{}, ...]

  """
  def list_inventories_received do
    from(ir in InventoryReceived, order_by: [desc: ir.inserted_at])
    |> Repo.all()
  end

  @doc """
  Returns filtered inventories_received by item (brand/generic/gtin), category, supplier, and type.

  Filters:
  - :item_search - search in brand_name, generic_name, or gtin
  - :category - partial match on category
  - :supplier - partial match on supplier
  - :type - partial match on type
  - :expiry_status - keeps items with at least one batch expiring in that
    window (see `Medcamp.ExpiryFilter`)
  """
  def filter_inventories_received(filters \\ %{}) do
    filters
    |> build_inventories_received_query()
    |> Repo.all()
  end

  @doc """
  Returns paginated list of inventories_received with filters.
  Options: :page (1-based), :per_page (default 20).
  """
  def list_inventories_received_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    query = build_inventories_received_query(filters)
    offset = max(0, (page - 1) * per_page)

    query
    |> limit(^per_page)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc """
  Returns total count of inventories_received matching filters.
  """
  def count_inventories_received(filters \\ %{}) do
    filters
    |> build_inventories_received_query()
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Returns the distinct, non-blank category/type/supplier values already
  present on inventories received, for populating filter dropdowns (these
  are plain string columns, not linked to a lookup table).
  """
  def list_categories_for_selection do
    distinct_values(:category)
  end

  def list_types_for_selection do
    distinct_values(:type)
  end

  def list_suppliers_for_selection do
    distinct_values(:supplier)
  end

  defp distinct_values(field) do
    InventoryReceived
    |> where([ir], not is_nil(field(ir, ^field)) and field(ir, ^field) != "")
    |> select([ir], field(ir, ^field))
    |> distinct(true)
    |> order_by([ir], field(ir, ^field))
    |> Repo.all()
  end

  defp build_inventories_received_query(filters) do
    base =
      from ir in InventoryReceived,
        as: :inventory_received,
        order_by: [desc: ir.inserted_at]

    base
    |> apply_item_search_filter(filters["item_search"] || filters[:item_search])
    |> apply_category_filter(filters["category"] || filters[:category])
    |> apply_supplier_filter(filters["supplier"] || filters[:supplier])
    |> apply_type_filter(filters["type"] || filters[:type])
    |> apply_expiry_filter(filters)
  end

  # An item received has no expiry of its own — its stock expires batch by
  # batch — so the filter keeps items with at least one batch in the requested
  # window, e.g. "Expired" means "holds expired stock". The preset status and
  # the custom from/to range intersect, see `Medcamp.ExpiryFilter.bounds/4`.
  defp apply_expiry_filter(query, filters) do
    bounds =
      ExpiryFilter.bounds(
        filters["expiry_status"] || filters[:expiry_status],
        filters["expiry_from"] || filters[:expiry_from],
        filters["expiry_to"] || filters[:expiry_to]
      )

    case bounds do
      {nil, nil} ->
        query

      {from_date, to_date} ->
        batches =
          from b in Batch,
            where: b.inventory_received_id == parent_as(:inventory_received).id,
            select: 1

        batches =
          batches
          |> maybe_batch_expiry_from(from_date)
          |> maybe_batch_expiry_to(to_date)

        from [_ir] in query, where: exists(batches)
    end
  end

  defp maybe_batch_expiry_from(query, nil), do: query
  defp maybe_batch_expiry_from(query, date), do: where(query, [b], b.expiry >= ^date)

  defp maybe_batch_expiry_to(query, nil), do: query
  defp maybe_batch_expiry_to(query, date), do: where(query, [b], b.expiry <= ^date)

  defp apply_item_search_filter(query, nil), do: query
  defp apply_item_search_filter(query, ""), do: query

  defp apply_item_search_filter(query, term) do
    term = String.trim(term)
    if term == "", do: query, else: apply_item_search_filter_term(query, "%#{term}%")
  end

  defp apply_item_search_filter_term(query, pattern) do
    from [ir] in query,
      where:
        ilike(ir.brand_name, ^pattern) or
          ilike(ir.generic_name, ^pattern) or
          ilike(ir.gtin, ^pattern) or
          ilike(ir.description, ^pattern)
  end

  defp apply_category_filter(query, nil), do: query
  defp apply_category_filter(query, ""), do: query

  defp apply_category_filter(query, category) do
    pattern = "%#{String.trim(category)}%"
    from [ir] in query, where: ilike(ir.category, ^pattern)
  end

  defp apply_supplier_filter(query, nil), do: query
  defp apply_supplier_filter(query, ""), do: query

  defp apply_supplier_filter(query, supplier) do
    pattern = "%#{String.trim(supplier)}%"
    from [ir] in query, where: ilike(ir.supplier, ^pattern)
  end

  defp apply_type_filter(query, nil), do: query
  defp apply_type_filter(query, ""), do: query

  defp apply_type_filter(query, type) do
    pattern = "%#{String.trim(type)}%"
    from [ir] in query, where: ilike(ir.type, ^pattern)
  end

  def list_inventories_received_for_select do
    Repo.all(
      from ir in InventoryReceived,
        select: {
          fragment(
            "COALESCE(?, '') || ', ' || COALESCE(?, '')",
            ir.brand_name,
            ir.generic_name
          ),
          ir.id
        }
    )
  end

  def search_inventories_received(query) do
    InventoryReceived
    |> where([ir], ilike(ir.brand_name, ^"%#{query}%"))
    |> or_where([ir], ilike(ir.generic_name, ^"%#{query}%"))
    |> or_where([ir], ilike(ir.gtin, ^"%#{query}%"))
    |> or_where([ir], ilike(ir.supplier, ^"%#{query}%"))
    |> or_where([ir], ilike(ir.description, ^"%#{query}%"))
    |> Repo.all()
  end

  @doc """
  Gets a single inventory_received.

  Raises `Ecto.NoResultsError` if the Inventory received does not exist.

  ## Examples

      iex> get_inventory_received!(123)
      %InventoryReceived{}

      iex> get_inventory_received!(456)
      ** (Ecto.NoResultsError)

  """
  def get_inventory_received!(id),
    do: Repo.get!(InventoryReceived, id)

  @doc """
  Creates a inventory_received.

  ## Examples

      iex> create_inventory_received(%{field: value})
      {:ok, %InventoryReceived{}}

      iex> create_inventory_received(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_inventory_received(attrs \\ %{}) do
    %InventoryReceived{}
    |> InventoryReceived.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a inventory_received.

  ## Examples

      iex> update_inventory_received(inventory_received, %{field: new_value})
      {:ok, %InventoryReceived{}}

      iex> update_inventory_received(inventory_received, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_inventory_received(%InventoryReceived{} = inventory_received, attrs) do
    inventory_received
    |> InventoryReceived.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a inventory_received.

  ## Examples

      iex> delete_inventory_received(inventory_received)
      {:ok, %InventoryReceived{}}

      iex> delete_inventory_received(inventory_received)
      {:error, %Ecto.Changeset{}}

  """
  def delete_inventory_received(%InventoryReceived{} = inventory_received) do
    Repo.delete(inventory_received)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking inventory_received changes.

  ## Examples

      iex> change_inventory_received(inventory_received)
      %Ecto.Changeset{data: %InventoryReceived{}}

  """
  def change_inventory_received(%InventoryReceived{} = inventory_received, attrs \\ %{}) do
    InventoryReceived.changeset(inventory_received, attrs)
  end

  def strip_first_three_take_13(string) do
    string
    |> String.slice(2..-1//-1)
    |> String.slice(0..12)
  end

  def get_inventory_received_by_gtin(gtin) do
    InventoryReceived
    |> where([ir], ir.gtin == ^gtin)
    |> Repo.all()
    |> List.first()
  end

  def gtin_exists(gtin) do
    from(i in InventoryReceived,
      where: i.gtin == ^gtin,
      limit: 1,
      select: i.id
    )
    |> Repo.one()
  end

  def extract_batch(gtin_string) when is_binary(gtin_string) do
    case Regex.run(~r/10(.+?)17/, gtin_string) do
      [_, match] -> match
      _ -> nil
    end
  end

  # Usage:
  # extract_batch("0189061592502611014062015AH171121")
  # Result: "14062015AH"
end
