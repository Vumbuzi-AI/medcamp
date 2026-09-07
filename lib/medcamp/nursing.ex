defmodule Medcamp.Nursing do
  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Medcamp.Repo
  alias Medcamp.NursingAllocations.NursingAllocation
  alias Medcamp.NursingConsumables.NursingConsumable
  alias Medcamp.PatientCharges

  def list_nursing_allocations do
    nursing_allocations_query(%{})
    |> Repo.all()
    |> preload_nursing_allocations()
  end

  @doc """
  Returns nursing allocations filtered by date range, allocated_by, allocated_to, expiry.
  """
  def filter_nursing_allocations(filters \\ %{}) do
    nursing_allocations_query(filters)
    |> Repo.all()
    |> preload_nursing_allocations()
  end

  def filter_nursing_allocations_paginated(filters \\ %{}, page \\ 1, per_page \\ 10) do
    nursing_allocations_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> preload_nursing_allocations()
  end

  def count_nursing_allocations(filters \\ %{}) do
    nursing_allocations_base_query(filters)
    |> select([na], count(na.id))
    |> Repo.one()
  end

  defp apply_nursing_date_from(query, nil), do: query
  defp apply_nursing_date_from(query, ""), do: query

  defp apply_nursing_date_from(query, date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, d} -> from(na in query, where: fragment("DATE(?)", na.inserted_at) >= ^d)
      _ -> query
    end
  end

  defp apply_nursing_date_from(query, _), do: query

  defp apply_nursing_date_to(query, nil), do: query
  defp apply_nursing_date_to(query, ""), do: query

  defp apply_nursing_date_to(query, date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, d} -> from(na in query, where: fragment("DATE(?)", na.inserted_at) <= ^d)
      _ -> query
    end
  end

  defp apply_nursing_date_to(query, _), do: query

  defp apply_nursing_allocated_by(query, nil), do: query
  defp apply_nursing_allocated_by(query, ""), do: query
  defp apply_nursing_allocated_by(query, id), do: from(na in query, where: na.allocated_by == ^id)
  defp apply_nursing_allocated_to(query, nil), do: query
  defp apply_nursing_allocated_to(query, ""), do: query
  defp apply_nursing_allocated_to(query, id), do: from(na in query, where: na.allocated_to == ^id)
  defp apply_nursing_expiry_from(query, nil), do: query
  defp apply_nursing_expiry_from(query, ""), do: query

  defp apply_nursing_expiry_from(query, date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, d} -> from(na in query, where: na.expiry_date >= ^d)
      _ -> query
    end
  end

  defp apply_nursing_expiry_from(query, _), do: query
  defp apply_nursing_expiry_to(query, nil), do: query
  defp apply_nursing_expiry_to(query, ""), do: query

  defp apply_nursing_expiry_to(query, date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, d} -> from(na in query, where: na.expiry_date <= ^d)
      _ -> query
    end
  end

  defp apply_nursing_expiry_to(query, _), do: query

  # The preset status and the custom from/to range narrow to their intersection
  # (see `Medcamp.ExpiryFilter.bounds/4`), so neither overrides the other.
  defp apply_nursing_expiry(query, filters) do
    {from, to} =
      Medcamp.ExpiryFilter.bounds(
        filters[:expiry_status],
        filters[:expiry_from],
        filters[:expiry_to]
      )

    query
    |> apply_nursing_expiry_from(from)
    |> apply_nursing_expiry_to(to)
  end

  def create_nursing_allocation(attrs \\ %{}) do
    %NursingAllocation{} |> NursingAllocation.changeset(attrs) |> Repo.insert()
  end

  @doc """
  Finds an existing allocation for the nurse and drug and tops it up.
  Creates a new one if none exists.
  """
  def add_to_nursing_allocation(nurse_id, inventory_received_id, quantity, attrs \\ %{}) do
    existing =
      NursingAllocation
      |> where(
        [na],
        na.allocated_to == ^nurse_id and na.inventory_received_id == ^inventory_received_id
      )
      |> order_by([na], desc: na.inserted_at)
      |> limit(1)
      |> Repo.one()

    case existing do
      nil ->
        %NursingAllocation{}
        |> NursingAllocation.changeset(
          Map.merge(attrs, %{
            allocated_to: nurse_id,
            inventory_received_id: inventory_received_id,
            allocated_quantity: quantity,
            remaining_quantity: quantity
          })
        )
        |> Repo.insert()

      allocation ->
        allocation
        |> NursingAllocation.changeset(%{
          remaining_quantity: allocation.remaining_quantity + quantity,
          allocated_quantity: allocation.allocated_quantity + quantity,
          batch_id: Map.get(attrs, :batch_id) || allocation.batch_id
        })
        |> Repo.update()
    end
  end

  def get_nursing_allocation!(id) do
    NursingAllocation
    |> Repo.get!(id)
    |> Repo.preload([
      :inventory_received,
      :batch,
      :inventory_issued,
      :allocated_by_user,
      :allocated_to_user,
      [inventory_issued: [:inventory_received, batch: :supplier]]
    ])
  end

  def list_consumables_for_allocation(allocation_id) do
    NursingConsumable
    |> where(nursing_allocation_id: ^allocation_id)
    |> order_by([consumable], desc: consumable.inserted_at)
    |> preload([:patient, :doctor_note, :patient_charge])
    |> Repo.all()
  end

  def update_nursing_allocation(%NursingAllocation{} = allocation, attrs) do
    allocation |> NursingAllocation.changeset(attrs) |> Repo.update()
  end

  def change_nursing_allocation(allocation, attrs \\ %{}) do
    NursingAllocation.changeset(allocation, attrs)
  end

  def create_nursing_consumable(attrs \\ %{}) do
    %NursingConsumable{} |> NursingConsumable.changeset(attrs) |> Repo.insert()
  end

  def update_nursing_consumable(%NursingConsumable{} = consumable, attrs) do
    consumable
    |> NursingConsumable.changeset(attrs)
    |> Repo.update()
  end

  def record_nursing_usage(attrs, recorded_by_id \\ nil) do
    attrs = Map.new(attrs)
    allocation_id = attrs["nursing_allocation_id"] || attrs[:nursing_allocation_id]

    Multi.new()
    |> Multi.run(:allocation, fn repo, _changes ->
      allocation =
        NursingAllocation
        |> repo.get!(allocation_id)
        |> repo.preload([
          :inventory_issued,
          :allocated_by_user,
          :allocated_to_user,
          [inventory_issued: [:inventory_received, batch: :supplier]]
        ])

      consumed_quantity = parse_consumed_quantity(attrs)

      cond do
        is_nil(consumed_quantity) ->
          {:error, NursingConsumable.changeset(%NursingConsumable{}, attrs)}

        consumed_quantity > allocation.remaining_quantity ->
          changeset =
            %NursingConsumable{}
            |> NursingConsumable.changeset(attrs)
            |> Ecto.Changeset.add_error(
              :consumed_quantity,
              "cannot exceed available stock of #{allocation.remaining_quantity} #{allocation.uom}"
            )

          {:error, changeset}

        true ->
          {:ok, allocation}
      end
    end)
    |> Multi.insert(:consumable, fn %{allocation: allocation} ->
      attrs
      |> Map.put("nursing_allocation_id", allocation.id)
      |> then(&NursingConsumable.changeset(%NursingConsumable{}, &1))
    end)
    |> Multi.update(:allocation_update, fn %{allocation: allocation, consumable: consumable} ->
      NursingAllocation.changeset(allocation, %{
        remaining_quantity: allocation.remaining_quantity - consumable.consumed_quantity
      })
    end)
    |> Multi.run(:charge, fn _repo, %{consumable: consumable} ->
      PatientCharges.create_charge_for_nursing_consumable(consumable, recorded_by_id)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{consumable: consumable, allocation_update: allocation, charge: charge}} ->
        consumable = Repo.preload(consumable, [:patient, :doctor_note, :patient_charge])
        {:ok, %{consumable: consumable, allocation: allocation, charge: charge}}

      {:error, _step, reason, _changes} ->
        {:error, reason}
    end
  end

  def change_nursing_consumable(consumable, attrs \\ %{}) do
    NursingConsumable.changeset(consumable, attrs)
  end

  def unit_price_for_allocation(allocation) do
    case allocation do
      %{inventory_issued: %{batch: %{price_per_unit: price_per_unit}}}
      when is_integer(price_per_unit) ->
        price_per_unit

      _ ->
        0
    end
  end

  defp maybe_string(nil), do: nil
  defp maybe_string(""), do: nil

  defp maybe_string(s) when is_binary(s) do
    t = String.trim(s)
    if t == "", do: nil, else: t
  end

  defp maybe_string(n) when is_number(n), do: to_string(n)

  defp nursing_allocations_query(filters) do
    nursing_allocations_base_query(filters)
    |> order_by([na], desc: na.inserted_at)
  end

  defp nursing_allocations_base_query(filters) do
    NursingAllocation
    |> apply_nursing_search(filters[:search])
    |> apply_nursing_date_from(filters[:date_from])
    |> apply_nursing_date_to(filters[:date_to])
    |> apply_nursing_allocated_by(filters[:allocated_by_id])
    |> apply_nursing_allocated_to(filters[:allocated_to_id])
    |> apply_nursing_expiry(filters)
  end

  defp apply_nursing_search(query, nil), do: query
  defp apply_nursing_search(query, ""), do: query

  defp apply_nursing_search(query, term) do
    term = String.trim(term)

    if term == "" do
      query
    else
      pattern = "%#{term}%"

      from(na in query,
        left_join: ir in assoc(na, :inventory_received),
        where: ilike(ir.brand_name, ^pattern) or ilike(ir.generic_name, ^pattern)
      )
    end
  end

  defp preload_nursing_allocations(allocations) do
    allocations
    |> Repo.preload([
      :inventory_received,
      :batch,
      :inventory_issued,
      :allocated_by_user,
      :allocated_to_user,
      [inventory_issued: [:inventory_received, batch: :supplier]]
    ])
  end

  @doc """
  Returns a map of item description fields for display in nursing allocation UIs.
  Includes: brand_name, generic_name, batch_number, size_gauge, gtin.
  """
  def allocation_item_details(allocation) do
    inv = allocation.inventory_issued
    # Fall back to directly linked inventory_received / batch when no inventory_issued
    recv = (inv && inv.inventory_received) || allocation.inventory_received
    batch = (inv && inv.batch) || allocation.batch

    brand = recv && recv.brand_name
    generic = recv && recv.generic_name

    batch_num =
      batch &&
        (maybe_string(batch.batch) || maybe_string(batch.serial) || "Batch ##{batch.id}")

    gtin = (inv && inv.gtin) || (recv && recv.gtin)

    size_gauge =
      cond do
        recv && recv.strength && recv.strength != "" -> recv.strength
        recv && recv.weight && recv.uom -> "#{recv.weight} #{recv.uom}"
        recv && recv.weight -> "#{recv.weight}"
        batch && batch.weight && batch.uom -> "#{batch.weight} #{batch.uom}"
        true -> nil
      end

    %{
      brand_name: brand,
      generic_name: generic,
      batch_number: batch_num,
      size_gauge: size_gauge,
      gtin: gtin,
      display_name: brand || generic || "Unknown Item"
    }
  end

  defp parse_consumed_quantity(attrs) do
    case attrs["consumed_quantity"] || attrs[:consumed_quantity] do
      value when is_integer(value) and value > 0 ->
        value

      value when is_binary(value) ->
        case Integer.parse(String.trim(value)) do
          {parsed_value, ""} when parsed_value > 0 -> parsed_value
          _ -> nil
        end

      _ ->
        nil
    end
  end
end
