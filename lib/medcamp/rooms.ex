defmodule Medcamp.Rooms do
  @moduledoc """
  The Rooms context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Rooms.Room
  alias Medcamp.RoomEquipments.RoomEquipment

  @spec list_rooms() :: nil | [%{optional(atom()) => any()}] | %{optional(atom()) => any()}
  @doc """
  Returns the list of rooms.

  ## Examples

      iex> list_rooms()
      [%Room{}, ...]



  """

  def get_room_by_room_number_with_equipments(room_number) do
    from(r in Room,
      where: r.room_number == ^room_number,
      preload: [room_equipments: ^from(re in RoomEquipment, order_by: re.name)]
    )
    |> Repo.all()
    |> List.first()
  end

  def list_rooms do
    rooms_query(%{})
    |> Repo.all()
    |> Repo.preload(:user)
  end

  def list_rooms_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    rooms_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload(:user)
  end

  def count_rooms(filters \\ %{}) do
    rooms_query(filters)
    |> exclude(:order_by)
    |> select([r], count(r.id))
    |> Repo.one()
  end

  def filter_rooms(filters) do
    rooms_query(filters)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  def filter_rooms_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    rooms_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload(:user)
  end

  def get_room_by_room_number!(room_number) do
    from(r in Room,
      where: r.room_number == ^room_number,
      select: r
    )
    |> Repo.all()
    |> List.first()
  end

  def open_rooms_for_selection do
    Repo.all(from r in Room, where: r.type == "Ward", select: {r.name, r.id})
  end

  def list_rooms_for_select do
    Repo.all(
      from r in Room,
        select: {r.name, r.id}
    )
  end

  @doc """
  Gets a single room.

  Raises `Ecto.NoResultsError` if the Room does not exist.

  ## Examples

      iex> get_room!(123)
      %Room{}

      iex> get_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room!(id), do: Repo.get!(Room, id)

  @doc """
  Creates a room.

  ## Examples

      iex> create_room(%{field: value})
      {:ok, %Room{}}

      iex> create_room(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_room(attrs \\ %{}) do
    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a room.

  ## Examples

      iex> update_room(room, %{field: new_value})
      {:ok, %Room{}}

      iex> update_room(room, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_room(%Room{} = room, attrs) do
    room
    |> Room.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a room.

  ## Examples

      iex> delete_room(room)
      {:ok, %Room{}}

      iex> delete_room(room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room(%Room{} = room) do
    Repo.delete(room)
  end

  def get_room_by_room_number(room_number) do
    from(r in Room,
      where: r.room_number == ^room_number,
      select: r
    )
    |> Repo.one()
  end

  defp rooms_query(filters) do
    Room
    |> maybe_filter_search(filters[:search])
    |> maybe_filter_date_from(filters[:date_from])
    |> maybe_filter_date_to(filters[:date_to])
    |> maybe_filter_type(filters[:type])
  end

  @doc """
  Returns the distinct, non-blank room types already in use, for
  populating a filter dropdown (plain string column, not a lookup table).
  """
  def list_room_types_for_selection do
    Room
    |> where([r], not is_nil(r.type) and r.type != "")
    |> select([r], r.type)
    |> distinct(true)
    |> order_by([r], r.type)
    |> Repo.all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking room changes.

  ## Examples

      iex> change_room(room)
      %Ecto.Changeset{data: %Room{}}

  """
  def change_room(%Room{} = room, attrs \\ %{}) do
    Room.changeset(room, attrs)
  end

  defp maybe_filter_search(query, nil), do: query
  defp maybe_filter_search(query, ""), do: query

  defp maybe_filter_search(query, search) do
    trimmed_search = String.trim(search)

    if trimmed_search == "" do
      query
    else
      pattern = "%#{trimmed_search}%"

      from(r in query,
        where: ilike(r.name, ^pattern) or ilike(r.room_number, ^pattern)
      )
    end
  end

  defp maybe_filter_date_from(query, value) do
    case parse_filter_date(value) do
      {:ok, date} -> from(r in query, where: fragment("date(?) >= ?", r.inserted_at, ^date))
      :error -> query
    end
  end

  defp maybe_filter_date_to(query, value) do
    case parse_filter_date(value) do
      {:ok, date} -> from(r in query, where: fragment("date(?) <= ?", r.inserted_at, ^date))
      :error -> query
    end
  end

  defp maybe_filter_type(query, nil), do: query
  defp maybe_filter_type(query, ""), do: query

  defp maybe_filter_type(query, type) do
    trimmed_type = String.trim(type)

    if trimmed_type == "" do
      query
    else
      from(r in query, where: ilike(r.type, ^trimmed_type))
    end
  end

  defp parse_filter_date(nil), do: :error
  defp parse_filter_date(""), do: :error
  defp parse_filter_date(%Date{} = date), do: {:ok, date}

  defp parse_filter_date(value) when is_binary(value) do
    case Date.from_iso8601(String.trim(value)) do
      {:ok, date} -> {:ok, date}
      _ -> :error
    end
  end
end
