defmodule Medcamp.RoomEquipmentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.RoomEquipments` context.
  """

  @doc """
  Generate a room_equipment.
  """
  def room_equipment_fixture(attrs \\ %{}) do
    room = Map.get(attrs, :room) || Map.get(attrs, "room") || Medcamp.RoomsFixtures.room_fixture()

    {:ok, room_equipment} =
      attrs
      |> Map.drop([:room, "room"])
      |> Enum.into(%{
        description: "some description",
        image: "some image",
        name: "some name",
        room_id: room.id
      })
      |> Medcamp.RoomEquipments.create_room_equipment()

    room_equipment
  end
end
