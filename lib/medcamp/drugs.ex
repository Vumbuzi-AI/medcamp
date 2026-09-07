defmodule Medcamp.Drugs do
  @moduledoc """
  The Drugs context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Drugs.Drug
  alias Medcamp.DrugBatches.DrugBatch
  alias Medcamp.DrugBatches
  alias Medcamp.Batches.Batch
  alias Medcamp.ExpiryFilter

  @active_batches_query from(db in DrugBatch,
                          where: db.is_active != false,
                          order_by: [desc: db.inserted_at]
                        )

  @available_batches_query from(db in DrugBatch,
                             where:
                               db.is_active != false and
                                 db.is_confirmed == true and
                                 db.remaining_quantity > 0,
                             order_by: [desc: db.inserted_at]
                           )

  @doc """
  Returns the list of drugs.

  ## Examples

      iex> list_drugs()
      [%Drug{}, ...]

  """
  def list_drugs do
    Repo.all(Drug)
    |> Repo.preload([
      :inventory_received,
      :inventory_manager,
      drug_batches: {@active_batches_query, [batch: :supplier]}
    ])
    |> sort_preloaded_batches()
  end

  def list_register_drugs do
    from(d in Drug,
      left_join: ir in assoc(d, :inventory_received),
      where: d.is_dangerous_drug == true,
      order_by: [asc: ir.brand_name, asc: ir.generic_name, asc: d.id],
      preload: [inventory_received: ir]
    )
    |> Repo.all()
  end

  @doc false
  def search_drugs(query) do
    from(d in Drug,
      left_join: ir in assoc(d, :inventory_received),
      join: db in DrugBatch,
      on:
        db.drug_id == d.id and db.is_confirmed == true and db.is_active != false and
          db.remaining_quantity > 0,
      where:
        ilike(d.generic_name, ^"%#{query}%") or
          ilike(d.brand_name, ^"%#{query}%") or
          ilike(ir.gtin, ^"%#{query}%"),
      distinct: true,
      preload: [inventory_received: ir]
    )
    |> Repo.all()
    |> Repo.preload([
      :inventory_manager,
      drug_batches: {@available_batches_query, [batch: :supplier]}
    ])
    |> sort_preloaded_batches()
  end

  def search_otc_drugs(query) do
    from(d in Drug,
      where: d.is_otc == true,
      left_join: ir in assoc(d, :inventory_received),
      where:
        ilike(d.generic_name, ^"%#{query}%") or
          ilike(d.brand_name, ^"%#{query}%") or
          ilike(ir.gtin, ^"%#{query}%"),
      preload: [inventory_received: ir]
    )
    |> Repo.all()
    |> Repo.preload([
      :inventory_manager,
      drug_batches: {@available_batches_query, [batch: :supplier]}
    ])
    |> sort_preloaded_batches()
  end

  def list_drugs_by_otc(:all), do: list_drugs()

  def list_drugs_by_otc(:otc) do
    from(d in Drug, where: d.is_otc == true)
    |> Repo.all()
    |> Repo.preload([
      :inventory_received,
      :inventory_manager,
      drug_batches: {@active_batches_query, [batch: :supplier]}
    ])
    |> sort_preloaded_batches()
  end

  def list_drugs_by_otc(:non_otc) do
    from(d in Drug, where: d.is_otc == false or is_nil(d.is_otc))
    |> Repo.all()
    |> Repo.preload([
      :inventory_received,
      :inventory_manager,
      drug_batches: {@active_batches_query, [batch: :supplier]}
    ])
    |> sort_preloaded_batches()
  end

  def search_drugs_by_category(category) do
    from(d in Drug,
      join: ir in assoc(d, :inventory_received),
      join: db in DrugBatch,
      on:
        db.drug_id == d.id and db.is_confirmed == true and db.is_active != false and
          db.remaining_quantity > 0,
      where: ilike(ir.category, ^"%#{category}%"),
      distinct: true
    )
    |> Repo.all()
    |> Repo.preload([
      :inventory_received,
      :inventory_manager,
      drug_batches: {@available_batches_query, [batch: :supplier]}
    ])
    |> sort_preloaded_batches()
  end

  @doc """
  Returns filtered drugs by item search, category, supplier, type, OTC, expiry
  and stock. Filters apply only when the corresponding param is present/non-empty.
  """
  def filter_drugs(filters \\ %{}) do
    filtered_drugs_query(filters)
    |> Repo.all()
    |> preload_drugs()
  end

  def filter_drugs_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    filtered_drugs_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> preload_drugs()
  end

  def count_drugs(filters \\ %{}) do
    filtered_drugs_query(filters)
    |> exclude(:order_by)
    |> select([d, _ir], count(d.id))
    |> Repo.one()
  end

  @doc """
  Returns the distinct, non-blank category/type/supplier values already
  present on drugs' inventory-received records, for populating filter
  dropdowns (these are plain string columns, not linked to a lookup table).
  """
  def list_drug_categories_for_selection do
    distinct_inventory_received_values(:category)
  end

  def list_drug_types_for_selection do
    distinct_inventory_received_values(:type)
  end

  def list_drug_suppliers_for_selection do
    distinct_inventory_received_values(:supplier)
  end

  defp distinct_inventory_received_values(field) do
    Drug
    |> join(:inner, [d], ir in assoc(d, :inventory_received))
    |> where([_d, ir], not is_nil(field(ir, ^field)) and field(ir, ^field) != "")
    |> select([_d, ir], field(ir, ^field))
    |> distinct(true)
    |> order_by([_d, ir], field(ir, ^field))
    |> Repo.all()
  end

  defp filtered_drugs_query(filters) do
    query =
      from d in Drug,
        as: :drug,
        left_join: ir in assoc(d, :inventory_received),
        order_by: [asc: d.generic_name]

    query
    |> apply_item_search_filter(filters["item_search"] || filters[:item_search])
    |> apply_category_filter(filters["category"] || filters[:category])
    |> apply_supplier_filter(filters["supplier"] || filters[:supplier])
    |> apply_type_filter(filters["type"] || filters[:type])
    |> apply_otc_filter(filters["otc_filter"] || filters[:otc_filter])
    |> apply_dangerous_drug_filter(filters["dda_filter"] || filters[:dda_filter])
    |> apply_expiry_filter(filters)
    |> apply_inventory_manager_filter(
      filters["inventory_manager_id"] || filters[:inventory_manager_id]
    )
  end

  # A drug has no expiry of its own — it expires batch by batch — so the filter
  # keeps drugs that have at least one (non-discarded) batch whose expiry falls
  # in the requested window, e.g. "Expired" means "has expired stock". The
  # preset status and the custom from/to range intersect, see
  # `Medcamp.ExpiryFilter.bounds/4`.
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
          from db in DrugBatch,
            join: b in Batch,
            on: b.id == db.batch_id,
            where: db.drug_id == parent_as(:drug).id and db.is_active != false,
            select: 1

        batches =
          batches
          |> maybe_batch_expiry_from(from_date)
          |> maybe_batch_expiry_to(to_date)

        from [_d, _ir] in query, where: exists(batches)
    end
  end

  defp maybe_batch_expiry_from(query, nil), do: query

  defp maybe_batch_expiry_from(query, date),
    do: where(query, [_db, b], b.expiry >= ^date)

  defp maybe_batch_expiry_to(query, nil), do: query

  defp maybe_batch_expiry_to(query, date),
    do: where(query, [_db, b], b.expiry <= ^date)

  defp preload_drugs(drugs) do
    Repo.preload(drugs, [
      :inventory_received,
      :inventory_manager,
      drug_batches: {@active_batches_query, [batch: :supplier]}
    ])
  end

  defp apply_item_search_filter(query, nil), do: query
  defp apply_item_search_filter(query, ""), do: query

  defp apply_item_search_filter(query, term) do
    term = String.trim(term)
    if term == "", do: query, else: apply_item_search_filter_term(query, "%#{term}%")
  end

  defp apply_item_search_filter_term(query, pattern) do
    from [d, ir] in query,
      where:
        ilike(d.generic_name, ^pattern) or
          ilike(d.brand_name, ^pattern) or
          ilike(ir.gtin, ^pattern) or
          ilike(ir.brand_name, ^pattern) or
          ilike(ir.generic_name, ^pattern)
  end

  defp apply_category_filter(query, nil), do: query
  defp apply_category_filter(query, ""), do: query

  defp apply_category_filter(query, category) do
    pattern = "%#{String.trim(category)}%"
    from [d, ir] in query, where: ilike(ir.category, ^pattern)
  end

  defp apply_supplier_filter(query, nil), do: query
  defp apply_supplier_filter(query, ""), do: query

  defp apply_supplier_filter(query, supplier) do
    pattern = "%#{String.trim(supplier)}%"
    from [d, ir] in query, where: ilike(ir.supplier, ^pattern)
  end

  defp apply_type_filter(query, nil), do: query
  defp apply_type_filter(query, ""), do: query

  defp apply_type_filter(query, type) do
    pattern = "%#{String.trim(type)}%"
    from [d, ir] in query, where: ilike(ir.type, ^pattern)
  end

  defp apply_otc_filter(query, nil), do: query
  defp apply_otc_filter(query, ""), do: query
  defp apply_otc_filter(query, "all"), do: query
  defp apply_otc_filter(query, :all), do: query

  defp apply_otc_filter(query, "otc") do
    from [d, ir] in query, where: d.is_otc == true
  end

  defp apply_otc_filter(query, :otc) do
    from [d, ir] in query, where: d.is_otc == true
  end

  defp apply_otc_filter(query, "non_otc") do
    from [d, ir] in query, where: d.is_otc == false or is_nil(d.is_otc)
  end

  defp apply_otc_filter(query, :non_otc) do
    from [d, ir] in query, where: d.is_otc == false or is_nil(d.is_otc)
  end

  defp apply_otc_filter(query, _), do: query

  defp apply_dangerous_drug_filter(query, nil), do: query
  defp apply_dangerous_drug_filter(query, ""), do: query
  defp apply_dangerous_drug_filter(query, "all"), do: query
  defp apply_dangerous_drug_filter(query, :all), do: query

  defp apply_dangerous_drug_filter(query, "dda") do
    from [d, ir] in query, where: d.is_dangerous_drug == true
  end

  defp apply_dangerous_drug_filter(query, :dda) do
    from [d, ir] in query, where: d.is_dangerous_drug == true
  end

  defp apply_dangerous_drug_filter(query, "non_dda") do
    from [d, ir] in query, where: d.is_dangerous_drug == false or is_nil(d.is_dangerous_drug)
  end

  defp apply_dangerous_drug_filter(query, :non_dda) do
    from [d, ir] in query, where: d.is_dangerous_drug == false or is_nil(d.is_dangerous_drug)
  end

  defp apply_dangerous_drug_filter(query, _), do: query

  defp apply_inventory_manager_filter(query, nil), do: query
  defp apply_inventory_manager_filter(query, ""), do: query

  defp apply_inventory_manager_filter(query, id) when is_integer(id) do
    from(d in query, where: d.inventory_manager_id == ^id)
  end

  defp apply_inventory_manager_filter(query, id) when is_binary(id) do
    case Integer.parse(id) do
      {n, _} -> from(d in query, where: d.inventory_manager_id == ^n)
      _ -> query
    end
  end

  defp apply_inventory_manager_filter(query, _), do: query

  def get_or_create_drug_with_inventory_received_id(inventory_received, inventory_manager_id) do
    case Repo.get_by(Drug, inventory_received_id: inventory_received.id) do
      nil ->
        create_drug(%{
          inventory_received_id: inventory_received.id,
          inventory_manager_id: inventory_manager_id,
          generic_name: inventory_received.generic_name,
          brand_name: inventory_received.brand_name
        })

      drug ->
        {:ok, drug}
    end
  end

  @doc """
  Gets a single drug.

  Raises `Ecto.NoResultsError` if the Drug does not exist.

  ## Examples

      iex> get_drug!(123)
      %Drug{}

      iex> get_drug!(456)
      ** (Ecto.NoResultsError)

  """
  def get_drug!(id),
    do:
      Repo.get!(Drug, id)
      |> Repo.preload([
        :inventory_received,
        drug_batches: {@available_batches_query, [batch: :supplier]}
      ])
      |> sort_preloaded_batches()

  def display_name(%Drug{} = drug) do
    brand_name =
      present_string(drug.brand_name) ||
        present_string(drug.inventory_received && drug.inventory_received.brand_name)

    generic_name =
      present_string(drug.generic_name) ||
        present_string(drug.inventory_received && drug.inventory_received.generic_name)

    cond do
      brand_name && generic_name && brand_name != generic_name ->
        "#{brand_name} (#{generic_name})"

      brand_name ->
        brand_name

      generic_name ->
        generic_name

      true ->
        "Drug ##{drug.id}"
    end
  end

  defp sort_preloaded_batches(drugs) when is_list(drugs) do
    drugs
    |> Enum.map(&sort_preloaded_batches/1)
    |> Enum.sort_by(&drug_expiry_sort_key/1)
  end

  defp sort_preloaded_batches(%Drug{} = drug) do
    if Ecto.assoc_loaded?(drug.drug_batches) do
      %{drug | drug_batches: DrugBatches.sort_active_batches_by_expiry(drug.drug_batches)}
    else
      drug
    end
  end

  defp drug_expiry_sort_key(%Drug{} = drug) do
    case List.first(List.wrap(drug.drug_batches)) do
      nil ->
        {{1, Date.add(Date.utc_today(), 36500)}, drug.brand_name || "", drug.id || 0}

      batch ->
        {DrugBatches.expiry_sort_key(batch), drug.brand_name || "", drug.id || 0}
    end
  end

  defp present_string(nil), do: nil

  defp present_string(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      trimmed -> trimmed
    end
  end

  @doc """
  Creates a drug.

  ## Examples

      iex> create_drug(%{field: value})
      {:ok, %Drug{}}

      iex> create_drug(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_drug(attrs \\ %{}) do
    %Drug{}
    |> Drug.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a drug.

  ## Examples

      iex> update_drug(drug, %{field: new_value})
      {:ok, %Drug{}}

      iex> update_drug(drug, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_drug(%Drug{} = drug, attrs) do
    drug
    |> Drug.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a drug.

  ## Examples

      iex> delete_drug(drug)
      {:ok, %Drug{}}

      iex> delete_drug(drug)
      {:error, %Ecto.Changeset{}}

  """
  def delete_drug(%Drug{} = drug) do
    Repo.delete(drug)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking drug changes.

  ## Examples

      iex> change_drug(drug)
      %Ecto.Changeset{data: %Drug{}}

  """
  def change_drug(%Drug{} = drug, attrs \\ %{}) do
    Drug.changeset(drug, attrs)
  end
end
