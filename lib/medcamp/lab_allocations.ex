defmodule Medcamp.LabAllocations do
  @moduledoc """
  The LabAllocations context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.LabAllocations.LabAllocation

  @doc """
  Returns the list of lab_allocations.

  ## Examples

      iex> list_lab_allocations()
      [%LabAllocation{}, ...]

  """
  def list_lab_allocations do
    lab_allocations_query(%{})
    |> Repo.all()
    |> preload_lab_allocations()
  end

  @doc """
  Returns lab allocations filtered by date range, allocated_by, allocated_to, expiry.
  """
  def filter_lab_allocations(filters \\ %{}) do
    lab_allocations_query(filters)
    |> Repo.all()
    |> preload_lab_allocations()
  end

  def filter_lab_allocations_paginated(filters \\ %{}, page \\ 1, per_page \\ 10) do
    lab_allocations_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> preload_lab_allocations()
  end

  def count_lab_allocations(filters \\ %{}) do
    lab_allocations_base_query(filters)
    |> select([la], count(la.id))
    |> Repo.one()
  end

  defp apply_lab_date_from(query, nil), do: query
  defp apply_lab_date_from(query, ""), do: query

  defp apply_lab_date_from(query, date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, d} -> from(la in query, where: fragment("DATE(?)", la.inserted_at) >= ^d)
      _ -> query
    end
  end

  defp apply_lab_date_from(query, _), do: query

  defp apply_lab_date_to(query, nil), do: query
  defp apply_lab_date_to(query, ""), do: query

  defp apply_lab_date_to(query, date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, d} -> from(la in query, where: fragment("DATE(?)", la.inserted_at) <= ^d)
      _ -> query
    end
  end

  defp apply_lab_date_to(query, _), do: query

  defp apply_lab_allocated_by(query, nil), do: query
  defp apply_lab_allocated_by(query, ""), do: query
  defp apply_lab_allocated_by(query, id), do: from(la in query, where: la.allocated_by == ^id)
  defp apply_lab_allocated_to(query, nil), do: query
  defp apply_lab_allocated_to(query, ""), do: query
  defp apply_lab_allocated_to(query, id), do: from(la in query, where: la.allocated_to == ^id)
  defp apply_lab_expiry_from(query, nil), do: query
  defp apply_lab_expiry_from(query, ""), do: query

  defp apply_lab_expiry_from(query, date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, d} -> from(la in query, where: la.expiry_date >= ^d)
      _ -> query
    end
  end

  defp apply_lab_expiry_from(query, _), do: query
  defp apply_lab_expiry_to(query, nil), do: query
  defp apply_lab_expiry_to(query, ""), do: query

  defp apply_lab_expiry_to(query, date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, d} -> from(la in query, where: la.expiry_date <= ^d)
      _ -> query
    end
  end

  defp apply_lab_expiry_to(query, _), do: query

  # The preset status and the custom from/to range narrow to their intersection
  # (see `Medcamp.ExpiryFilter.bounds/4`), so neither overrides the other.
  defp apply_lab_expiry(query, filters) do
    {from, to} =
      Medcamp.ExpiryFilter.bounds(
        filters[:expiry_status],
        filters[:expiry_from],
        filters[:expiry_to]
      )

    query
    |> apply_lab_expiry_from(from)
    |> apply_lab_expiry_to(to)
  end

  @doc """
  Gets a single lab_allocation.

  Raises `Ecto.NoResultsError` if the Lab allocation does not exist.

  ## Examples

      iex> get_lab_allocation!(123)
      %LabAllocation{}

      iex> get_lab_allocation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_lab_allocation!(id),
    do:
      Repo.get!(LabAllocation, id)
      |> Repo.preload([:allocated_by_user, :allocated_to_user])
      |> Repo.preload(inventory_issued: [:inventory_received, batch: :supplier])

  @doc """
  Creates a lab_allocation.

  ## Examples

      iex> create_lab_allocation(%{field: value})
      {:ok, %LabAllocation{}}

      iex> create_lab_allocation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_lab_allocation(attrs \\ %{}) do
    %LabAllocation{}
    |> LabAllocation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a lab_allocation.

  ## Examples

      iex> update_lab_allocation(lab_allocation, %{field: new_value})
      {:ok, %LabAllocation{}}

      iex> update_lab_allocation(lab_allocation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_lab_allocation(%LabAllocation{} = lab_allocation, attrs) do
    lab_allocation
    |> LabAllocation.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a lab_allocation.

  ## Examples

      iex> delete_lab_allocation(lab_allocation)
      {:ok, %LabAllocation{}}

      iex> delete_lab_allocation(lab_allocation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_lab_allocation(%LabAllocation{} = lab_allocation) do
    Repo.delete(lab_allocation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking lab_allocation changes.

  ## Examples

      iex> change_lab_allocation(lab_allocation)
      %Ecto.Changeset{data: %LabAllocation{}}

  """
  def change_lab_allocation(%LabAllocation{} = lab_allocation, attrs \\ %{}) do
    LabAllocation.changeset(lab_allocation, attrs)
  end

  defp lab_allocations_query(filters) do
    lab_allocations_base_query(filters)
    |> order_by([la], desc: la.inserted_at)
  end

  defp lab_allocations_base_query(filters) do
    LabAllocation
    |> apply_lab_search(filters[:search])
    |> apply_lab_date_from(filters[:date_from])
    |> apply_lab_date_to(filters[:date_to])
    |> apply_lab_allocated_by(filters[:allocated_by_id])
    |> apply_lab_allocated_to(filters[:allocated_to_id])
    |> apply_lab_expiry(filters)
  end

  defp apply_lab_search(query, nil), do: query
  defp apply_lab_search(query, ""), do: query

  defp apply_lab_search(query, term) do
    term = String.trim(term)

    if term == "" do
      query
    else
      pattern = "%#{term}%"

      from(la in query,
        left_join: ii in assoc(la, :inventory_issued),
        left_join: ir in assoc(ii, :inventory_received),
        where: ilike(ir.brand_name, ^pattern) or ilike(ir.generic_name, ^pattern)
      )
    end
  end

  defp preload_lab_allocations(lab_allocations) do
    lab_allocations
    |> Repo.preload([:allocated_by_user, :allocated_to_user])
    |> Repo.preload(inventory_issued: [:inventory_received, batch: :supplier])
  end
end
