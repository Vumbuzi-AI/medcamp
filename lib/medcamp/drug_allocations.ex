defmodule Medcamp.DrugAllocations do
  @moduledoc """
  The DrugAllocations context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.DrugAllocations.DrugAllocation
  alias Medcamp.DrugsGiven.DrugGiven

  alias Medcamp.DrugBatches
  alias Medcamp.DrugBatches.DrugBatch
  alias Medcamp.Batches.Batch

  def calculate_price(inventory_received_id, quantity) do
    query =
      from db in DrugBatch,
        where:
          db.inventory_received_id == ^inventory_received_id and db.remaining_quantity > 0 and
            db.is_active != false,
        join: b in Batch,
        on: db.batch_id == b.id,
        preload: [batch: b]

    batches =
      query
      |> Repo.all()
      |> DrugBatches.sort_active_batches_by_expiry()

    {allocations, _remaining} = allocate_from_batches(batches, quantity)

    total_price =
      Enum.reduce(allocations, 0, fn %{batch: batch, quantity_allocated: qty}, acc ->
        batch_price = batch.batch.price_per_unit * qty
        acc + batch_price
      end)

    %{
      total_price: total_price,
      allocations: allocations
    }
  end

  defp allocate_from_batches(batches, quantity) do
    Enum.reduce_while(batches, {[], quantity}, fn batch, {allocations, remaining_qty} ->
      if remaining_qty <= 0 do
        {:halt, {allocations, 0}}
      else
        qty_from_batch = min(batch.remaining_quantity, remaining_qty)

        updated_allocations =
          allocations ++
            [
              %{
                batch: batch,
                quantity_allocated: qty_from_batch,
                batch_id: batch.batch_id,
                drug_batch_id: batch.id
              }
            ]

        {:cont, {updated_allocations, remaining_qty - qty_from_batch}}
      end
    end)
  end

  @doc """
  Returns the list of drug_allocations.

  ## Examples

      iex> list_drug_allocations()
      [%DrugAllocation{}, ...]

  """
  def list_drug_allocations do
    from(d in DrugAllocation,
      order_by: [desc: d.inserted_at]
    )
    |> Repo.all()
    |> Repo.preload([:pharmacist, :patient])
  end

  def list_drug_allocations_paginated(page \\ 1, per_page \\ 20) do
    drug_allocations_query()
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:pharmacist, :patient, drugs_given: :drug])
  end

  def count_drug_allocations do
    drug_allocations_query()
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Returns drug allocations filtered by drug name, patient name, patient email,
  or a dispensed batch number.
  When search is empty, returns all allocations.
  Always preloads drugs_given with their drug for display.
  """
  def filter_drug_allocations(search \\ "") do
    search
    |> drug_allocations_search_query()
    |> Repo.all()
    |> Repo.preload([:pharmacist, :patient, drugs_given: :drug])
  end

  def filter_drug_allocations_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    filters
    |> drug_allocations_filter_query()
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:pharmacist, :patient, drugs_given: :drug])
  end

  def count_filtered_drug_allocations(filters \\ %{}) do
    filters
    |> drug_allocations_filter_query()
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Returns the distinct, non-nil payment types currently in use, for populating
  a filter dropdown without hardcoding values the data may not actually use.
  """
  def list_distinct_payment_types do
    DrugAllocation
    |> where([da], not is_nil(da.payment_type) and da.payment_type != "")
    |> distinct(true)
    |> select([da], da.payment_type)
    |> order_by([da], da.payment_type)
    |> Repo.all()
  end

  @doc """
  Reports drugs that were actually issued, grouped by their received inventory
  item. Prescribed drugs that have not been dispensed are intentionally excluded.

  Supported filters are `:search`, `:category`, `:inventory_type`, `:date_from`,
  and `:date_to`. String keys are accepted as well as atom keys.
  """
  def issued_drug_report(filters \\ %{}) do
    from(dg in DrugGiven,
      join: drug in assoc(dg, :drug),
      join: inventory in assoc(drug, :inventory_received),
      group_by: [
        inventory.id,
        inventory.brand_name,
        inventory.generic_name,
        inventory.gtin,
        inventory.category,
        inventory.type,
        inventory.uom
      ],
      select: %{
        inventory_received_id: inventory.id,
        brand_name: inventory.brand_name,
        generic_name: inventory.generic_name,
        gtin: inventory.gtin,
        category: inventory.category,
        inventory_type: inventory.type,
        unit_of_measurement: inventory.uom,
        issued_quantity: coalesce(sum(dg.quantity), 0),
        issue_count: count(dg.id),
        allocation_count: count(dg.drug_allocation_id, :distinct),
        last_issued_at: max(dg.inserted_at)
      },
      order_by: [desc: sum(dg.quantity), asc: inventory.brand_name]
    )
    |> apply_issued_drug_search(filter_value(filters, :search))
    |> apply_issued_drug_category(filter_value(filters, :category))
    |> apply_issued_drug_inventory_type(filter_value(filters, :inventory_type))
    |> apply_issued_drug_date_from(filter_value(filters, :date_from))
    |> apply_issued_drug_date_to(filter_value(filters, :date_to))
    |> Repo.all()
  end

  defp filter_value(filters, key), do: filters[key] || filters[Atom.to_string(key)]

  defp apply_issued_drug_search(query, value) when value in [nil, ""], do: query

  defp apply_issued_drug_search(query, value) do
    term = "%#{String.trim(to_string(value))}%"

    from [dg, drug, inventory] in query,
      where:
        ilike(inventory.brand_name, ^term) or
          ilike(inventory.generic_name, ^term) or
          ilike(inventory.gtin, ^term)
  end

  defp apply_issued_drug_category(query, value) when value in [nil, ""], do: query

  defp apply_issued_drug_category(query, value) do
    value = String.trim(to_string(value))
    from [dg, drug, inventory] in query, where: ilike(inventory.category, ^value)
  end

  defp apply_issued_drug_inventory_type(query, value) when value in [nil, ""], do: query

  defp apply_issued_drug_inventory_type(query, value) do
    value = String.trim(to_string(value))
    from [dg, drug, inventory] in query, where: ilike(inventory.type, ^value)
  end

  defp apply_issued_drug_date_from(query, value) do
    case parse_report_date(value) do
      {:ok, date} ->
        from_datetime = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
        from [dg, drug, inventory] in query, where: dg.inserted_at >= ^from_datetime

      :error ->
        query
    end
  end

  defp apply_issued_drug_date_to(query, value) do
    case parse_report_date(value) do
      {:ok, date} ->
        to_datetime = DateTime.new!(Date.add(date, 1), ~T[00:00:00], "Etc/UTC")
        from [dg, drug, inventory] in query, where: dg.inserted_at < ^to_datetime

      :error ->
        query
    end
  end

  defp parse_report_date(%Date{} = date), do: {:ok, date}
  defp parse_report_date(nil), do: :error
  defp parse_report_date(""), do: :error

  defp parse_report_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> {:ok, date}
      _ -> :error
    end
  end

  defp parse_report_date(_value), do: :error

  def list_drug_allocations_for_a_patient(patient_id) do
    Repo.all(
      from d in DrugAllocation,
        where: d.patient_id == ^patient_id,
        order_by: [desc: d.inserted_at]
    )
    |> Repo.preload([:pharmacist, :patient, :doctor, :drugs_given])
  end

  def list_drug_allocations_for_a_patient_paginated(patient_id, page \\ 1, per_page \\ 20) do
    from(d in DrugAllocation,
      where: d.patient_id == ^patient_id,
      order_by: [desc: d.inserted_at]
    )
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:pharmacist, :patient, :doctor, :drugs_given])
  end

  def count_drug_allocations_for_a_patient(patient_id) do
    from(d in DrugAllocation, where: d.patient_id == ^patient_id, select: count(d.id))
    |> Repo.one()
  end

  @doc """
  Returns a page of drug allocations that include the given drug (by its
  inventory_received_id) in their prescribed drugs_assigned list (JSONB),
  regardless of whether the drug has been dispensed yet, most recent first.

  Takes `inventory_received_id` directly (not `drug_id`) so a caller that
  already has the drug loaded, e.g. a LiveView holding `@drug`, doesn't force
  an extra round trip just to look up that field.

  `status` optionally narrows to `"given"` or `"pending"` (see
  `apply_drug_allocation_status/2`); any other value returns every allocation.
  """
  def list_drug_allocations_for_drug(
        inventory_received_id,
        status \\ nil,
        page \\ 1,
        per_page \\ 10
      ) do
    drug_allocations_for_ir_query(inventory_received_id, status)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:pharmacist, :patient, :doctor, drugs_given: :drug])
  end

  @doc """
  Total count of drug allocations matching `inventory_received_id`/`status`,
  for pagination. See `list_drug_allocations_for_drug/4`.
  """
  def count_drug_allocations_for_drug(inventory_received_id, status \\ nil) do
    drug_allocations_for_ir_query(inventory_received_id, status)
    |> exclude(:order_by)
    |> select([da], count(da.id))
    |> Repo.one()
  end

  defp drug_allocations_for_ir_query(inventory_received_id, status) do
    from(da in DrugAllocation,
      where:
        fragment(
          "EXISTS (SELECT 1 FROM jsonb_array_elements(?) AS elem WHERE (elem->>'inventory_received_id')::integer = ?)",
          da.drugs_assigned,
          ^inventory_received_id
        ),
      order_by: [desc: da.inserted_at, desc: da.id]
    )
    |> apply_drug_allocation_status(status)
  end

  @doc """
  Returns all drug allocations whose drugs_assigned list (JSONB) includes the
  given inventory_received_id.
  """
  def list_drug_allocations_for_inventory_received(inventory_received_id) do
    Repo.all(
      from da in DrugAllocation,
        where:
          fragment(
            "EXISTS (SELECT 1 FROM jsonb_array_elements(?) AS elem WHERE (elem->>'inventory_received_id')::integer = ?)",
            da.drugs_assigned,
            ^inventory_received_id
          ),
        order_by: [desc: da.inserted_at]
    )
    |> Repo.preload(drugs_given: :drug)
  end

  @doc """
  Returns true if the batch with the given batch number was dispensed in any
  drugs_given record.
  """
  def batch_given?(batch_number) do
    Repo.exists?(
      from dg in Medcamp.DrugsGiven.DrugGiven,
        where:
          fragment(
            "EXISTS (SELECT 1 FROM jsonb_array_elements(?) AS elem JOIN batches AS batch ON batch.id = (elem->>'batch_id')::bigint WHERE batch.batch = ?)",
            dg.batch_allocations,
            ^batch_number
          )
    )
  end

  @doc """
  Returns all drug allocations that dispensed the batch with the given batch number.
  """
  def list_drug_allocations_for_batch(batch_number) do
    Repo.all(
      from da in DrugAllocation,
        join: dg in assoc(da, :drugs_given),
        where:
          fragment(
            "EXISTS (SELECT 1 FROM jsonb_array_elements(?) AS elem JOIN batches AS batch ON batch.id = (elem->>'batch_id')::bigint WHERE batch.batch = ?)",
            dg.batch_allocations,
            ^batch_number
          ),
        distinct: true,
        order_by: [desc: da.inserted_at]
    )
    |> Repo.preload([:pharmacist, :patient, drugs_given: :drug])
  end

  def list_drug_allocations_for_a_doctor_note(doctor_note_id) do
    Repo.all(
      from d in DrugAllocation,
        where: d.doctor_note_id == ^doctor_note_id,
        order_by: [desc: d.inserted_at]
    )
    |> Repo.preload([:pharmacist, :patient, :doctor])
  end

  @doc """
  Gets a single drug_allocation.

  Raises `Ecto.NoResultsError` if the Drug allocation does not exist.

  ## Examples

      iex> get_drug_allocation!(123)
      %DrugAllocation{}

      iex> get_drug_allocation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_drug_allocation!(id),
    do:
      Repo.get!(DrugAllocation, id)
      |> Repo.preload([:pharmacist, :patient])
      |> Repo.preload(doctor_note: :doctor)

  @doc """
  Creates a drug_allocation.

  ## Examples

      iex> create_drug_allocation(%{field: value})
      {:ok, %DrugAllocation{}}

      iex> create_drug_allocation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_drug_allocation(attrs \\ %{}) do
    %DrugAllocation{}
    |> DrugAllocation.changeset(attrs)
    |> Repo.insert()
    |> Medcamp.CampFlow.advance("pharmacy_pending")
  end

  @doc """
  Updates a drug_allocation.

  ## Examples

      iex> update_drug_allocation(drug_allocation, %{field: new_value})
      {:ok, %DrugAllocation{}}

      iex> update_drug_allocation(drug_allocation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_drug_allocation(%DrugAllocation{} = drug_allocation, attrs) do
    drug_allocation
    |> DrugAllocation.changeset(normalize_drug_allocation_attrs(attrs))
    |> Repo.audited_update()
  end

  def update_drug_allocation_after_dispense(%DrugAllocation{} = drug_allocation, attrs) do
    drug_allocation
    |> DrugAllocation.changeset(normalize_drug_allocation_attrs(attrs),
      validate_available_quantity: false
    )
    |> Repo.audited_update()
  end

  @doc """
  Deletes a drug_allocation.

  ## Examples

      iex> delete_drug_allocation(drug_allocation)
      {:ok, %DrugAllocation{}}

      iex> delete_drug_allocation(drug_allocation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_drug_allocation(%DrugAllocation{} = drug_allocation) do
    cond do
      drug_allocation.has_paid ->
        {:error, :paid_prescription}

      prescription_has_dispensed_drugs?(drug_allocation) ->
        {:error, :dispensed_drugs}

      true ->
        Repo.delete(drug_allocation)
    end
  end

  def remove_drug_assigned(%DrugAllocation{} = drug_allocation, drug_assigned_id) do
    case Enum.find(drug_allocation.drugs_assigned || [], fn drug ->
           to_string(drug.id) == to_string(drug_assigned_id)
         end) do
      nil ->
        {:error, :not_found}

      drug ->
        if drug_has_been_given?(drug) do
          {:error, :already_dispensed}
        else
          updated_drugs =
            Enum.reject(drug_allocation.drugs_assigned || [], fn current_drug ->
              to_string(current_drug.id) == to_string(drug_assigned_id)
            end)

          update_drug_allocation(drug_allocation, %{drugs_assigned: updated_drugs})
        end
    end
  end

  def prescription_has_dispensed_drugs?(%DrugAllocation{} = drug_allocation) do
    Enum.any?(drug_allocation.drugs_assigned || [], &drug_has_been_given?/1)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking drug_allocation changes.

  ## Examples

      iex> change_drug_allocation(drug_allocation)
      %Ecto.Changeset{data: %DrugAllocation{}}

  """
  def change_drug_allocation(%DrugAllocation{} = drug_allocation, attrs \\ %{}) do
    DrugAllocation.changeset(drug_allocation, attrs)
  end

  defp normalize_drug_allocation_attrs(attrs) when is_map(attrs) do
    attrs
    |> maybe_normalize_drugs_assigned(:drugs_assigned)
    |> maybe_normalize_drugs_assigned("drugs_assigned")
  end

  defp normalize_drug_allocation_attrs(attrs), do: attrs

  defp maybe_normalize_drugs_assigned(attrs, key) do
    case Map.fetch(attrs, key) do
      {:ok, drugs_assigned} when is_list(drugs_assigned) ->
        Map.put(attrs, key, Enum.map(drugs_assigned, &normalize_drug_assigned/1))

      _ ->
        attrs
    end
  end

  defp normalize_drug_assigned(%{__struct__: _} = drug_assigned),
    do: drug_assigned |> Map.from_struct() |> Map.delete(:__struct__)

  defp normalize_drug_assigned(drug_assigned) when is_map(drug_assigned), do: drug_assigned

  defp drug_has_been_given?(drug_assigned) do
    Map.get(drug_assigned, :has_been_given, Map.get(drug_assigned, "has_been_given", false))
  end

  defp drug_allocations_query do
    from(da in DrugAllocation,
      order_by: [desc: da.inserted_at],
      preload: [:pharmacist, :patient, drugs_given: :drug]
    )
  end

  defp drug_allocations_filter_query(filters) do
    search = filters[:search] || filters["search"] || ""
    status = filters[:status] || filters["status"]
    payment_type = filters[:payment_type] || filters["payment_type"]

    search
    |> drug_allocations_search_query()
    |> apply_drug_allocation_status(status)
    |> apply_drug_allocation_payment_type(payment_type)
  end

  defp apply_drug_allocation_status(query, nil), do: query
  defp apply_drug_allocation_status(query, ""), do: query

  defp apply_drug_allocation_status(query, "given") do
    from([da] in query, where: da.has_been_assigned == true)
  end

  defp apply_drug_allocation_status(query, "pending") do
    from([da] in query, where: da.has_been_assigned == false)
  end

  defp apply_drug_allocation_status(query, _), do: query

  defp apply_drug_allocation_payment_type(query, nil), do: query
  defp apply_drug_allocation_payment_type(query, ""), do: query

  defp apply_drug_allocation_payment_type(query, payment_type) do
    from([da] in query, where: da.payment_type == ^payment_type)
  end

  defp drug_allocations_search_query(search) do
    search = search |> to_string() |> String.trim()

    base =
      from(da in DrugAllocation,
        join: p in assoc(da, :patient),
        order_by: [desc: da.inserted_at]
      )

    if search == "" do
      base
    else
      term = "%#{search}%"

      from([da, p] in base,
        left_join: dg in assoc(da, :drugs_given),
        left_join: d in assoc(dg, :drug),
        where:
          ilike(p.first_name, ^term) or
            ilike(p.last_name, ^term) or
            ilike(p.middle_name, ^term) or
            ilike(p.email, ^term) or
            ilike(d.brand_name, ^term) or
            ilike(d.generic_name, ^term) or
            fragment(
              "EXISTS (SELECT 1 FROM jsonb_array_elements(?) AS allocation JOIN batches AS batch ON batch.id = (allocation->>'batch_id')::bigint WHERE batch.batch ILIKE ?)",
              dg.batch_allocations,
              ^term
            ) or
            ilike(
              fragment("concat_ws(' ', ?, ?, ?)", p.first_name, p.middle_name, p.last_name),
              ^term
            ),
        order_by: [desc: da.inserted_at, asc: da.id],
        distinct: [desc: da.inserted_at, asc: da.id]
      )
    end
  end
end
