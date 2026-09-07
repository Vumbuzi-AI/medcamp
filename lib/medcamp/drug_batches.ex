defmodule Medcamp.DrugBatches do
  @moduledoc """
  The DrugBatches context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.DrugBatches.DrugBatch
  alias Medcamp.Drugs.Drug
  alias Medcamp.Batches.Batch

  @doc """
  Returns the list of drug_batches.

  ## Examples

      iex> list_drug_batches()
      [%DrugBatch{}, ...]

  """
  def list_drug_batches do
    Repo.all(DrugBatch)
  end

  def get_drugs_with_active_drug_batch do
    from(db in DrugBatch,
      where: db.is_confirmed == true and db.is_active != false,
      join: d in Drug,
      on: d.id == db.drug_id,
      join: b in Batch,
      on: b.id == db.batch_id,
      where: db.remaining_quantity > 0,
      limit: 1,
      select: %{
        drug: d,
        drug_batch: db,
        batch: b
      }
    )
    |> Repo.all()
  end

  def check_available_quantity(inventory_received_id) do
    query =
      from db in DrugBatch,
        where:
          db.inventory_received_id == ^inventory_received_id and db.remaining_quantity > 0 and
            db.is_confirmed == true and db.is_active != false,
        preload: [:batch, :drug]

    batches =
      query
      |> Repo.all()
      |> sort_active_batches_by_expiry()

    Enum.reduce(batches, 0, fn batch, acc ->
      acc + batch.remaining_quantity
    end)
  end

  def get_drug_with_active_drug_batch(drug_id) do
    from(db in DrugBatch,
      where: db.is_confirmed == true and db.is_active != false,
      join: d in Drug,
      on: d.id == db.drug_id,
      join: b in Batch,
      on: b.id == db.batch_id,
      where: db.drug_id == ^drug_id and db.remaining_quantity > 0,
      limit: 1,
      select: %{
        drug: d,
        drug_batch: db,
        batch: b
      }
    )
    |> Repo.one()
  end

  def get_drugs_with_active_drug_batch_for_selection do
    get_drugs_with_active_drug_batch()
    |> Enum.map(fn %{drug: drug, batch: _batch} ->
      {drug.generic_name <> " - " <> drug.brand_name, drug.id}
    end)
  end

  def list_active_drug_batches_for_inventory_received(inventory_received_id) do
    from(db in DrugBatch,
      where:
        db.inventory_received_id == ^inventory_received_id and
          db.remaining_quantity > 0 and
          db.is_confirmed == true and
          db.is_active != false,
      preload: [:batch]
    )
    |> Repo.all()
    |> sort_active_batches_by_expiry()
  end

  def sort_active_batches_by_expiry(drug_batches) when is_list(drug_batches) do
    Enum.sort_by(drug_batches, fn drug_batch ->
      {expiry_sort_key(drug_batch), fallback_sort_key(drug_batch)}
    end)
  end

  def expiry_sort_key(drug_batch) do
    case parse_batch_expiry(drug_batch) do
      {:ok, date} ->
        sortable_date = Date.to_gregorian_days(date)

        case Date.compare(date, Date.utc_today()) do
          :lt -> {2, sortable_date}
          _ -> {0, sortable_date}
        end

      {:error, _reason} ->
        {1, Date.to_gregorian_days(Date.add(Date.utc_today(), 36500))}
    end
  end

  def batch_days_to_expiry(drug_batch) do
    case parse_batch_expiry(drug_batch) do
      {:ok, date} -> Date.diff(date, Date.utc_today())
      {:error, _reason} -> nil
    end
  end

  def parse_batch_expiry(%DrugBatch{batch: batch}), do: parse_batch_expiry(batch)
  def parse_batch_expiry(%Batch{expiry: expiry}), do: parse_batch_expiry(expiry)
  def parse_batch_expiry(expiry), do: Medcamp.ExpiryFilter.parse(expiry)

  @doc """
  Keeps only the drug batches whose batch expiry matches the given
  `Medcamp.ExpiryFilter` preset status and custom from/to range. Filtered in
  memory (rather than in SQL) so the non-ISO expiry strings that
  `parse_batch_expiry/1` tolerates are classified the same way here as they are
  when sorting.
  """
  def filter_by_expiry(drug_batches, status, from \\ nil, to \\ nil)

  def filter_by_expiry(drug_batches, status, from, to) when is_list(drug_batches) do
    if Medcamp.ExpiryFilter.bounds(status, from, to) == {nil, nil} do
      drug_batches
    else
      Enum.filter(drug_batches, fn drug_batch ->
        case parse_batch_expiry(drug_batch) do
          {:ok, date} -> Medcamp.ExpiryFilter.matches?(date, status, from, to)
          {:error, _reason} -> false
        end
      end)
    end
  end

  defp fallback_sort_key(%DrugBatch{} = drug_batch) do
    {
      batch_number(drug_batch),
      drug_batch.inserted_at || ~U[9999-12-31 00:00:00Z]
    }
  end

  defp batch_number(%DrugBatch{batch: %Batch{batch: batch_number}}), do: batch_number || ""
  defp batch_number(_), do: ""

  def list_pending_drug_batches(filters \\ %{}) do
    Repo.all(
      from(db in DrugBatch,
        where: db.is_confirmed == false and db.is_active != false,
        order_by: [desc: db.inserted_at]
      )
      |> apply_pending_drug_batch_search(filters[:search])
    )
    |> Repo.preload([:drug, :batch, :inventory_received, :inventory_manager])
  end

  defp apply_pending_drug_batch_search(query, nil), do: query
  defp apply_pending_drug_batch_search(query, ""), do: query

  defp apply_pending_drug_batch_search(query, term) do
    term = String.trim(term)

    if term == "" do
      query
    else
      pattern = "%#{term}%"

      from(db in query,
        left_join: ir in assoc(db, :inventory_received),
        left_join: b in assoc(db, :batch),
        where:
          ilike(ir.brand_name, ^pattern) or ilike(ir.generic_name, ^pattern) or
            ilike(b.batch, ^pattern)
      )
    end
  end

  def list_pending_drug_batches_paginated(filters \\ %{}, page \\ 1, per_page \\ 10) do
    from(db in DrugBatch,
      where: db.is_confirmed == false and db.is_active != false,
      order_by: [desc: db.inserted_at]
    )
    |> apply_pending_drug_batch_search(filters[:search])
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:drug, :batch, :inventory_received, :inventory_manager])
  end

  def count_pending_drug_batches(filters \\ %{}) do
    from(db in DrugBatch, where: db.is_confirmed == false and db.is_active != false)
    |> apply_pending_drug_batch_search(filters[:search])
    |> Repo.aggregate(:count, :id)
  end

  def list_drug_batches_for_drug(drug_id) do
    Repo.all(
      from db in DrugBatch,
        where: db.drug_id == ^drug_id and db.is_active != false,
        order_by: [desc: db.inserted_at]
    )
    |> Repo.preload([:drug, :batch, :inventory_received, :inventory_manager])
  end

  def list_discarded_drug_batches_for_drug(drug_id) do
    Repo.all(
      from db in DrugBatch,
        where: db.drug_id == ^drug_id and db.is_active == false,
        order_by: [desc: db.inserted_at]
    )
    |> Repo.preload([:drug, :batch, :inventory_received, :inventory_manager])
  end

  @doc """
  Gets a single drug_batch.

  Raises `Ecto.NoResultsError` if the Drug batch does not exist.

  ## Examples

      iex> get_drug_batch!(123)
      %DrugBatch{}

      iex> get_drug_batch!(456)
      ** (Ecto.NoResultsError)

  """
  def get_drug_batch!(id),
    do:
      Repo.get!(DrugBatch, id)
      |> Repo.preload([:drug, :batch, :inventory_received, :inventory_manager])

  @doc """
  Creates a drug_batch.

  ## Examples

      iex> create_drug_batch(%{field: value})
      {:ok, %DrugBatch{}}

      iex> create_drug_batch(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_drug_batch(attrs \\ %{}) do
    %DrugBatch{}
    |> DrugBatch.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a drug_batch.

  ## Examples

      iex> update_drug_batch(drug_batch, %{field: new_value})
      {:ok, %DrugBatch{}}

      iex> update_drug_batch(drug_batch, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_drug_batch(%DrugBatch{} = drug_batch, attrs) do
    drug_batch
    |> DrugBatch.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a drug_batch.

  ## Examples

      iex> delete_drug_batch(drug_batch)
      {:ok, %DrugBatch{}}

      iex> delete_drug_batch(drug_batch)
      {:error, %Ecto.Changeset{}}

  """
  def delete_drug_batch(%DrugBatch{} = drug_batch) do
    Repo.delete(drug_batch)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking drug_batch changes.

  ## Examples

      iex> change_drug_batch(drug_batch)
      %Ecto.Changeset{data: %DrugBatch{}}

  """
  def change_drug_batch(%DrugBatch{} = drug_batch, attrs \\ %{}) do
    DrugBatch.changeset(drug_batch, attrs)
  end
end
