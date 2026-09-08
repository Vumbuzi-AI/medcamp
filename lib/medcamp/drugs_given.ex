defmodule Medcamp.DrugsGiven do
  @moduledoc """
  The DrugsGiven context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Batches.Batch
  alias Medcamp.DrugsGiven.DrugGiven
  alias Medcamp.DrugBatches
  alias Medcamp.DrugAllocations
  require Logger

  @doc """
  Returns the list of drugs_given.

  ## Examples

      iex> list_drugs_given()
      [%DrugGiven{}, ...]

  """
  def list_drugs_given do
    # Build a query that includes all the information you need
    query =
      from dg in DrugGiven,
        preload: [:drug_allocation, :drug, :pharmacist]

    # Execute the query
    Repo.all(query)
  end

  def list_drugs_given_for_sichi(id) do
    from(dg in DrugGiven,
      where: dg.id == ^id,
      preload: [batch_allocations: :batch]
    )
    |> Repo.all()
    |> Repo.preload([:drug, :pharmacist])
    |> Enum.map(fn drug_given ->
      %{
        drug_name: drug_given.drug.brand_name,
        id: drug_given.id,
        batch_info:
          Enum.map(drug_given.batch_allocations, fn allocation ->
            %{
              quantity: allocation.quantity,
              batch: allocation.batch.batch,
              id: allocation.batch.id,
              is_verified: allocation.is_verified
            }
          end)
      }
    end)
  end

  @doc """
  Returns a page of drugs_given for the given drug, most recent first.
  """
  def list_drugs_given_for_drug(drug_id, page \\ 1, per_page \\ 10) do
    drugs_given_for_drug_query(drug_id)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:pharmacist, drug_allocation: [:patient]])
  end

  @doc """
  Total count of drugs_given for the given drug, for pagination. See
  `list_drugs_given_for_drug/3`.
  """
  def count_drugs_given_for_drug(drug_id) do
    drugs_given_for_drug_query(drug_id)
    |> exclude(:order_by)
    |> select([dg], count(dg.id))
    |> Repo.one()
  end

  defp drugs_given_for_drug_query(drug_id) do
    from(dg in DrugGiven,
      where: dg.drug_id == ^drug_id,
      order_by: [desc: dg.inserted_at, desc: dg.id]
    )
  end

  def list_drugs_given_by_allocation(drug_allocation_id) do
    query =
      from dg in DrugGiven,
        where: dg.drug_allocation_id == ^drug_allocation_id,
        preload: [
          :drug,
          :pharmacist,
          # Make sure to explicitly preload drugs_assigned
          drug_allocation: [drugs_assigned: []]
        ]

    Repo.all(query)
  end

  def get_complete_drug_given_info_for_a_drug_given(drug_given_id, drug_allocation_id) do
    drugs_given = get_complete_drugs_given_info(drug_allocation_id)

    Enum.find(drugs_given, fn drug_given_info ->
      drug_given_info.drug_given.id == String.to_integer(drug_given_id)
    end)
  end

  def get_complete_drugs_given_info(drug_allocation_id) do
    # Query for drugs given with the allocation
    drugs_given =
      Repo.all(
        from dg in DrugGiven,
          where: dg.drug_allocation_id == ^drug_allocation_id,
          preload: [:drug, :pharmacist]
      )

    # Get the drug allocation once (with embedded drugs_assigned already included)
    drug_allocation = Repo.get!(Medcamp.DrugAllocations.DrugAllocation, drug_allocation_id)

    # Process each drug given to combine with drug_assigned info
    Enum.map(drugs_given, fn drug_given ->
      # Find the matching drug_assigned
      drug_assigned = find_matching_drug_assigned(drug_given, drug_allocation)

      # Create a complete info map
      %{
        drug_given: drug_given,
        drug_assigned: drug_assigned,
        batch_allocations: drug_given.batch_allocations,
        complete_info: %{
          id: drug_given.id,
          quantity: drug_given.quantity,
          price: drug_given.price,
          brand_name: drug_given.drug.brand_name,
          generic_name: drug_given.drug.generic_name,
          unit_of_measurement: drug_assigned && drug_assigned.unit_of_measurement,
          frequency: drug_assigned && drug_assigned.frequency,
          duration_in_days: drug_assigned && drug_assigned.duration_in_days,
          prescription_note: drug_assigned && drug_assigned.prescription_note,
          pharmacist_note: drug_assigned && drug_assigned.pharmacist_note,
          route_of_administration: drug_assigned && drug_assigned.route_of_administration,
          pharmacist_name: drug_given.pharmacist.name,
          pharmacist_id: drug_given.pharmacist_id,
          drug_allocation_id: drug_given.drug_allocation_id,
          patient_id: drug_allocation.patient_id,
          inserted_at: drug_given.inserted_at
        }
      }
    end)
  end

  # Finds the drug_assigned entry that best corresponds to a drug_given record.
  #
  # Matching priority (first non-nil wins):
  #   1. inventory_received_id matches AND has_been_given is true
  #   2. inventory_received_id matches (any)
  #   3. brand_name matches AND has_been_given is true
  #   4. brand_name matches (any)
  #   5. generic_name matches (any)
  #
  # Never raises — all comparisons guard against nil.
  defp find_matching_drug_assigned(drug_given, drug_allocation) do
    assigned = drug_allocation.drugs_assigned
    drug = drug_given.drug

    ir_id = drug && drug.inventory_received_id
    brand = drug && drug.brand_name
    generic = drug && drug.generic_name

    # 1. inventory_received_id + has_been_given (most precise — same drug, already dispensed)
    result =
      is_integer(ir_id) &&
        Enum.find(assigned, fn da ->
          da.inventory_received_id == ir_id && da.has_been_given
        end)

    # 2. inventory_received_id only (same drug, may still be pending)
    result =
      result ||
        (is_integer(ir_id) &&
           Enum.find(assigned, fn da ->
             da.inventory_received_id == ir_id
           end))

    # 3. brand_name + has_been_given
    result =
      result ||
        (is_binary(brand) && brand != "" &&
           Enum.find(assigned, fn da ->
             da.brand_name == brand && da.has_been_given
           end))

    # 4. brand_name only
    result =
      result ||
        (is_binary(brand) && brand != "" &&
           Enum.find(assigned, fn da ->
             da.brand_name == brand
           end))

    # 5. generic_name only (last resort)
    result ||
      (is_binary(generic) && generic != "" &&
         Enum.find(assigned, fn da ->
           da.generic_name == generic
         end))
  end

  def list_drugs_given_for_an_allocation(drug_allocation_id) do
    Repo.all(from dg in DrugGiven, where: dg.drug_allocation_id == ^drug_allocation_id)
    |> Repo.preload(drug: [drug_batches: :batch])
  end

  @doc """
  Gets a single drug_given.

  Raises `Ecto.NoResultsError` if the Drug given does not exist.

  ## Examples

      iex> get_drug_given!(123)
      %DrugGiven{}

      iex> get_drug_given!(456)
      ** (Ecto.NoResultsError)

  """
  def get_drug_given!(id), do: Repo.get!(DrugGiven, id)

  @doc """
  Finds a drug_given that has a pending (unverified) batch allocation for the given batch_id.
  Returns {:ok, drug_given, allocation_index} or {:error, :not_found}.
  Used for API check_verify and scan_verify.
  """
  def find_drug_given_with_pending_allocation_for_batch_and_gtin(batch_id, gtin)
      when is_integer(batch_id) and is_binary(gtin) do
    batch_id
    |> candidate_batch_ids_for_lookup(gtin)
    |> find_pending_drug_given_for_batch_ids()
  end

  def find_drug_given_with_pending_allocation_for_batch_and_gtin(_, _),
    do: {:error, :not_found}

  def find_drug_given_with_pending_allocation_for_batch(batch_id) when is_integer(batch_id) do
    [batch_id]
    |> find_pending_drug_given_for_batch_ids()
  end

  def find_drug_given_with_pending_allocation_for_batch(_), do: {:error, :not_found}

  defp candidate_batch_ids_for_lookup(batch_id, gtin) do
    normalized_gtin = normalize_gtin_to_14(gtin)

    case Repo.get(Batch, batch_id) do
      %Batch{} = batch ->
        matching_ids =
          Repo.all(
            from b in Batch,
              left_join: ir in assoc(b, :inventory_received),
              where:
                b.batch == ^batch.batch and
                  (fragment("lpad(?, 14, '0')", b.gtin) == ^normalized_gtin or
                     fragment("lpad(?, 14, '0')", ir.gtin) == ^normalized_gtin),
              order_by: [desc: b.id],
              select: b.id
          )

        if matching_ids == [], do: [batch_id], else: matching_ids

      nil ->
        [batch_id]
    end
  end

  defp find_pending_drug_given_for_batch_ids([]), do: {:error, :not_found}

  defp find_pending_drug_given_for_batch_ids(batch_ids) do
    batch_id_strings = Enum.map(batch_ids, &to_string/1)

    query =
      from dg in DrugGiven,
        where:
          fragment(
            "EXISTS (SELECT 1 FROM jsonb_array_elements(batch_allocations) AS elem WHERE (elem->>'batch_id') = ANY(?) AND (elem->>'is_verified') IN ('false', 'f'))",
            type(^batch_id_strings, {:array, :string})
          ),
        order_by: [desc: dg.inserted_at],
        limit: 1,
        preload: [:drug, :drug_allocation, :pharmacist]

    case Repo.one(query) do
      nil ->
        {:error, :not_found}

      drug_given ->
        idx =
          Enum.find_index(drug_given.batch_allocations, fn a ->
            a.batch_id in batch_ids and !a.is_verified
          end)

        if idx, do: {:ok, drug_given, idx}, else: {:error, :not_found}
    end
  end

  defp normalize_gtin_to_14(gtin) do
    if String.length(gtin) >= 14 do
      String.slice(gtin, -14, 14)
    else
      String.pad_leading(gtin, 14, "0")
    end
  end

  @doc """
  Marks the batch allocation for the given drug_given and batch_id as verified.
  Mirrors the logic on the drug allocation show page (verify_allocation).
  """
  def verify_batch_allocation(drug_given_id, batch_id) when is_integer(batch_id) do
    drug_given = get_drug_given!(drug_given_id)

    updated_allocations =
      Enum.map(drug_given.batch_allocations, fn allocation ->
        if allocation.batch_id == batch_id do
          allocation
          |> Map.from_struct()
          |> Map.put(:is_verified, true)
        else
          allocation
          |> Map.from_struct()
        end
      end)

    attrs = %{batch_allocations: updated_allocations}

    drug_given
    |> DrugGiven.changeset(attrs)
    |> Repo.update()
  end

  def verify_batch_allocation(_, _), do: {:error, :invalid_batch_id}

  @doc """
  Creates a drug_given.

  ## Examples

      iex> create_drug_given(%{field: value})
      {:ok, %DrugGiven{}}

      iex> create_drug_given(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_drug_given(attrs \\ %{}) do
    %DrugGiven{}
    |> DrugGiven.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a drug_given.

  ## Examples

      iex> update_drug_given(drug_given, %{field: new_value})
      {:ok, %DrugGiven{}}

      iex> update_drug_given(drug_given, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_drug_given(%DrugGiven{} = drug_given, attrs) do
    drug_given
    |> DrugGiven.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a drug_given.

  ## Examples

      iex> delete_drug_given(drug_given)
      {:ok, %DrugGiven{}}

      iex> delete_drug_given(drug_given)
      {:error, %Ecto.Changeset{}}

  """
  def delete_drug_given(%DrugGiven{} = drug_given) do
    Repo.delete(drug_given)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking drug_given changes.

  ## Examples

      iex> change_drug_given(drug_given)
      %Ecto.Changeset{data: %DrugGiven{}}

  """
  def change_drug_given(%DrugGiven{} = drug_given, attrs \\ %{}) do
    DrugGiven.changeset(drug_given, attrs)
  end

  def cancel_drug_given(drug_given_id) do
    # Get the drug_given record with batch allocations and drug
    drug_given = Repo.get(DrugGiven, drug_given_id)

    if is_nil(drug_given) do
      {:error, "Drug given record not found"}
    else
      drug_given = drug_given |> Repo.preload([:drug_allocation, :drug])

      # Get the relevant information
      drug_allocation = drug_given.drug_allocation

      Repo.transaction(fn ->
        # 1. Restore batch quantities
        restore_batch_quantities(drug_given.batch_allocations)

        # 2. Find the matching drug_assigned using inventory_received_id and quantity
        # First, preload the drug to get inventory_received_id if needed
        drug =
          if Ecto.assoc_loaded?(drug_given.drug),
            do: drug_given.drug,
            else: Repo.get!(Medcamp.Drugs.Drug, drug_given.drug_id)

        drugs_assigned =
          drug_allocation.drugs_assigned
          |> Enum.map(fn drug_assigned ->
            drug_assigned_map = ensure_map(drug_assigned)

            # Match based on inventory_received_id and possibly quantity
            if drug_assigned_map.inventory_received_id == drug.inventory_received_id &&
                 drug_assigned_map.quantity == drug_given.quantity do
              Map.put(drug_assigned_map, :has_been_given, false)
            else
              drug_assigned_map
            end
          end)

        case DrugAllocations.update_drug_allocation_after_dispense(
               drug_allocation,
               %{drugs_assigned: drugs_assigned}
             ) do
          {:ok, updated_allocation} ->
            Repo.delete!(drug_given)

            %{
              drug_given: drug_given,
              drug_allocation: updated_allocation
            }

          {:error, changeset} ->
            Repo.rollback(changeset)
        end
      end)
    end
  end

  # Helper function to ensure we have a map
  defp ensure_map(struct_or_map) do
    case struct_or_map do
      %{__struct__: _} -> Map.from_struct(struct_or_map)
      map when is_map(map) -> map
    end
  end

  # Helper function to restore batch quantities
  defp restore_batch_quantities(batch_allocations) do
    Enum.each(batch_allocations, fn allocation ->
      # Get the drug batch
      drug_batch = DrugBatches.get_drug_batch!(allocation.drug_batch_id)

      # Calculate new remaining quantity
      new_remaining_quantity = drug_batch.remaining_quantity + allocation.quantity

      # Update the batch
      DrugBatches.update_drug_batch(drug_batch, %{
        remaining_quantity: new_remaining_quantity
      })
    end)
  end

  def create_drug_given_by_brand(
        drug_allocation_id,
        brand_name,
        generic_name,
        pharmacist_id,
        drug_assigned_id,
        pharmacist_note \\ nil
      ) do
    drug_allocation = DrugAllocations.get_drug_allocation!(drug_allocation_id)

    case find_drug_assigned(
           drug_allocation.drugs_assigned,
           drug_assigned_id,
           brand_name,
           generic_name
         ) do
      nil ->
        {:error,
         "No drug with brand name '#{brand_name}' and generic name '#{generic_name}' found"}

      drug_assigned ->
        if drug_assigned.has_been_given do
          {:error, "This drug has already been dispensed"}
        else
          quantity_needed = drug_assigned.quantity

          allocate_and_create(
            drug_allocation,
            drug_allocation_id,
            drug_assigned,
            pharmacist_id,
            quantity_needed,
            pharmacist_note
          )
        end
    end
  end

  defp find_drug_assigned(drugs_assigned, drug_assigned_id, brand_name, generic_name) do
    Enum.find(drugs_assigned, fn drug ->
      to_string(drug.id) == to_string(drug_assigned_id)
    end) ||
      Enum.find(drugs_assigned, fn drug ->
        drug.brand_name == brand_name && drug.generic_name == generic_name
      end)
  end

  # Helper function to allocate batches and create drug_given record
  defp allocate_and_create(
         drug_allocation,
         drug_allocation_id,
         drug_assigned,
         pharmacist_id,
         quantity_needed,
         pharmacist_note
       ) do
    # Allocate from batches
    case allocate_from_batches_with_better_date_parsing(
           drug_assigned.inventory_received_id,
           quantity_needed
         ) do
      {:ok, allocations} ->
        # Calculate total price
        total_price =
          Enum.reduce(allocations, 0, fn allocation, acc ->
            acc + allocation.quantity_allocated * allocation.unit_price
          end)

        # Format batch allocations for embedding
        batch_allocations =
          Enum.map(allocations, fn allocation ->
            %{
              quantity: allocation.quantity_allocated,
              unit_price: allocation.unit_price,
              batch_id: allocation.batch_id,
              drug_batch_id: allocation.drug_batch_id
            }
          end)

        # Create drug given record with embedded batch allocations
        drug_given_params = %{
          quantity: quantity_needed,
          price: total_price,
          drug_id: allocations |> List.first() |> Map.get(:drug_id),
          drug_allocation_id: drug_allocation_id,
          pharmacist_id: pharmacist_id,
          batch_allocations: batch_allocations,
          # Store brand and generic name for reference
          brand_name: drug_assigned.brand_name,
          generic_name: drug_assigned.generic_name
        }

        Repo.transaction(fn ->
          case create_drug_given(drug_given_params) do
            {:ok, drug_given} ->
              Enum.each(batch_allocations, fn allocation ->
                update_batch_quantity(allocation.drug_batch_id, allocation.quantity)
              end)

              updated_drugs_assigned =
                Enum.map(drug_allocation.drugs_assigned, fn drug ->
                  drug_map = ensure_map(drug)

                  if to_string(drug_map.id) == to_string(drug_assigned.id) do
                    drug_map
                    |> Map.put(:has_been_given, true)
                    |> maybe_put_pharmacist_note(pharmacist_note)
                  else
                    drug_map
                  end
                end)

              case DrugAllocations.update_drug_allocation_after_dispense(
                     drug_allocation,
                     %{drugs_assigned: updated_drugs_assigned}
                   ) do
                {:ok, _updated_allocation} -> drug_given
                {:error, changeset} -> Repo.rollback(changeset)
              end

            {:error, changeset} ->
              Repo.rollback(changeset)
          end
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_put_pharmacist_note(drug_assigned, nil), do: drug_assigned
  defp maybe_put_pharmacist_note(drug_assigned, ""), do: drug_assigned

  defp maybe_put_pharmacist_note(drug_assigned, pharmacist_note),
    do: Map.put(drug_assigned, :pharmacist_note, pharmacist_note)

  defp update_batch_quantity(drug_batch_id, quantity_used) do
    drug_batch = DrugBatches.get_drug_batch!(drug_batch_id)
    new_remaining = drug_batch.remaining_quantity - quantity_used

    DrugBatches.update_drug_batch(drug_batch, %{remaining_quantity: new_remaining})
  end

  defp allocate_from_batches_with_better_date_parsing(inventory_received_id, quantity_needed) do
    # Query drug batches for this inventory_received with remaining quantity
    query =
      from db in Medcamp.DrugBatches.DrugBatch,
        where:
          db.inventory_received_id == ^inventory_received_id and db.remaining_quantity > 0 and
            db.is_active != false,
        join: b in Medcamp.Batches.Batch,
        on: db.batch_id == b.id,
        preload: [batch: b]

    batches = Repo.all(query)

    # Sort batches by expiry date after loading (handles various date formats)
    sorted_batches = DrugBatches.sort_active_batches_by_expiry(batches)

    # Rest of the function remains the same but uses sorted_batches
    total_available =
      Enum.reduce(sorted_batches, 0, fn batch, acc -> acc + batch.remaining_quantity end)

    if total_available < quantity_needed do
      {:error,
       "Insufficient quantity available. Needed: #{quantity_needed}, Available: #{total_available}"}
    else
      # Allocate from batches (FEFO order)
      {allocations, _} =
        Enum.reduce_while(sorted_batches, {[], quantity_needed}, fn batch, {result, remaining} ->
          if remaining <= 0 do
            {:halt, {result, 0}}
          else
            qty_from_batch = min(batch.remaining_quantity, remaining)

            # Check if this batch is expired
            is_expired =
              case DrugBatches.parse_batch_expiry(batch.batch.expiry) do
                {:ok, expiry_date} -> Date.compare(expiry_date, Date.utc_today()) == :lt
                {:error, _} -> false
              end

            allocation = %{
              drug_batch_id: batch.id,
              drug_id: batch.drug_id,
              batch_id: batch.batch_id,
              quantity_allocated: qty_from_batch,
              unit_price: batch.batch.price_per_unit,
              expiry_date: batch.batch.expiry,
              is_expired: is_expired,
              batch_number: batch.batch.batch,
              days_to_expiry: DrugBatches.batch_days_to_expiry(batch)
            }

            {:cont, {result ++ [allocation], remaining - qty_from_batch}}
          end
        end)

      {:ok, allocations}
    end
  end
end
