defmodule Medcamp.RoomEquipments do
  @moduledoc """
  The RoomEquipments context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.RoomEquipments.RoomEquipment

  @doc """
  Returns the list of room_equipments.

  ## Examples

      iex> list_room_equipments()
      [%RoomEquipment{}, ...]

  """
  def list_room_equipments do
    room_equipments_query(nil) |> Repo.all()
  end

  def list_room_equipments_by_room(room_id) do
    room_equipments_query(room_id) |> Repo.all()
  end

  def list_room_equipments_by_room_paginated(room_id, page \\ 1, per_page \\ 10) do
    room_equipments_query(room_id)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_room_equipments_by_room(room_id) do
    room_equipments_base_query(room_id)
    |> select([re], count(re.id))
    |> Repo.one()
  end

  @doc """
  Gets a single room_equipment.

  Raises `Ecto.NoResultsError` if the Room equipment does not exist.

  ## Examples

      iex> get_room_equipment!(123)
      %RoomEquipment{}

      iex> get_room_equipment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room_equipment!(id), do: Repo.get!(RoomEquipment, id)

  @doc """
  Creates a room_equipment.

  ## Examples

      iex> create_room_equipment(%{field: value})
      {:ok, %RoomEquipment{}}

      iex> create_room_equipment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room_equipment(attrs \\ %{}) do
    %RoomEquipment{}
    |> RoomEquipment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a room_equipment.

  ## Examples

      iex> update_room_equipment(room_equipment, %{field: new_value})
      {:ok, %RoomEquipment{}}

      iex> update_room_equipment(room_equipment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room_equipment(%RoomEquipment{} = room_equipment, attrs) do
    room_equipment
    |> RoomEquipment.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a room_equipment.

  ## Examples

      iex> delete_room_equipment(room_equipment)
      {:ok, %RoomEquipment{}}

      iex> delete_room_equipment(room_equipment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room_equipment(%RoomEquipment{} = room_equipment) do
    Repo.delete(room_equipment)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room_equipment changes.

  ## Examples

      iex> change_room_equipment(room_equipment)
      %Ecto.Changeset{data: %RoomEquipment{}}

  """
  def change_room_equipment(%RoomEquipment{} = room_equipment, attrs \\ %{}) do
    RoomEquipment.changeset(room_equipment, attrs)
  end

  defp room_equipments_query(nil) do
    room_equipments_base_query(nil)
    |> order_by([re], desc: re.inserted_at)
  end

  defp room_equipments_query(room_id) do
    room_equipments_base_query(room_id)
    |> order_by([re], desc: re.inserted_at)
  end

  defp room_equipments_base_query(nil) do
    from(re in RoomEquipment)
  end

  defp room_equipments_base_query(room_id) do
    from(re in RoomEquipment, where: re.room_id == ^room_id)
  end
end
