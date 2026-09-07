defmodule Medcamp.RoomAllocations do
  @moduledoc """
  The RoomAllocations context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.RoomAllocations.RoomAllocation

  @doc """
  Returns the list of room_allocations.

  ## Examples

      iex> list_room_allocations()
      [%RoomAllocation{}, ...]

  """
  def list_room_allocations(search \\ "") do
    RoomAllocation
    |> apply_room_allocation_search(search)
    |> Repo.all()
    |> Repo.preload([:patient, :nurse, :room])
  end

  defp apply_room_allocation_search(query, ""), do: query

  defp apply_room_allocation_search(query, search) do
    term = "%#{search}%"

    query
    |> join(:left, [r], p in assoc(r, :patient))
    |> join(:left, [r, p], room in assoc(r, :room))
    |> where(
      [r, p, room],
      ilike(p.first_name, ^term) or
        ilike(p.last_name, ^term) or
        ilike(room.room_number, ^term)
    )
  end

  def list_room_allocations_paginated(search \\ "", page \\ 1, per_page \\ 10) do
    from(r in RoomAllocation, order_by: [desc: r.inserted_at])
    |> apply_room_allocation_search(search)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:patient, :nurse, :room])
  end

  def count_room_allocations(search \\ "") do
    RoomAllocation
    |> apply_room_allocation_search(search)
    |> Repo.aggregate(:count, :id)
  end

  def list_room_allocations_by_patient(patient_id) do
    Repo.all(
      from r in RoomAllocation,
        where: r.patient_id == ^patient_id,
        order_by: [desc: r.inserted_at]
    )
    |> Repo.preload([:patient, :nurse, :room])
  end

  def list_room_allocations_by_patient_paginated(patient_id, page \\ 1, per_page \\ 10) do
    from(r in RoomAllocation,
      where: r.patient_id == ^patient_id,
      order_by: [desc: r.inserted_at]
    )
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:patient, :nurse, :room])
  end

  def count_room_allocations_by_patient(patient_id) do
    from(r in RoomAllocation, where: r.patient_id == ^patient_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Gets a single room_allocation.

  Raises `Ecto.NoResultsError` if the Room allocation does not exist.

  ## Examples

      iex> get_room_allocation!(123)
      %RoomAllocation{}

      iex> get_room_allocation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room_allocation!(id), do: Repo.get!(RoomAllocation, id)

  @doc """
  Creates a room_allocation.

  ## Examples

      iex> create_room_allocation(%{field: value})
      {:ok, %RoomAllocation{}}

      iex> create_room_allocation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room_allocation(attrs \\ %{}) do
    %RoomAllocation{}
    |> RoomAllocation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a room_allocation.

  ## Examples

      iex> update_room_allocation(room_allocation, %{field: new_value})
      {:ok, %RoomAllocation{}}

      iex> update_room_allocation(room_allocation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room_allocation(%RoomAllocation{} = room_allocation, attrs) do
    room_allocation
    |> RoomAllocation.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a room_allocation.

  ## Examples

      iex> delete_room_allocation(room_allocation)
      {:ok, %RoomAllocation{}}

      iex> delete_room_allocation(room_allocation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room_allocation(%RoomAllocation{} = room_allocation) do
    Repo.delete(room_allocation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room_allocation changes.

  ## Examples

      iex> change_room_allocation(room_allocation)
      %Ecto.Changeset{data: %RoomAllocation{}}

  """
  def change_room_allocation(%RoomAllocation{} = room_allocation, attrs \\ %{}) do
    RoomAllocation.changeset(room_allocation, attrs)
  end
end
