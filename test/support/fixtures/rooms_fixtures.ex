defmodule Medcamp.RoomsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.Rooms` context.
  """

  @doc """
  Generate a room.
  """
  def room_fixture(attrs \\ %{}) do
    user =
      Map.get(attrs, :user) || Map.get(attrs, "user") || Medcamp.AccountsFixtures.user_fixture()

    {:ok, room} =
      attrs
      |> Map.drop([:user, "user"])
      |> Enum.into(%{
        added_by: user.id,
        is_free: true,
        name: "some name",
        type: "ward",
        room_number: "some room_number"
      })
      |> Medcamp.Rooms.create_room()

    room
  end
end
