defmodule Medcamp.RoomAllocationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.RoomAllocations` context.
  """

  @doc """
  Generate a room_allocation.
  """
  def room_allocation_fixture(attrs \\ %{}) do
    patient =
      Map.get(attrs, :patient) || Map.get(attrs, "patient") ||
        Medcamp.PatientsFixtures.patient_fixture()

    nurse =
      Map.get(attrs, :nurse) || Map.get(attrs, "nurse") || Medcamp.AccountsFixtures.user_fixture()

    room = Map.get(attrs, :room) || Map.get(attrs, "room") || Medcamp.RoomsFixtures.room_fixture()

    {:ok, room_allocation} =
      attrs
      |> Map.drop([:patient, "patient", :nurse, "nurse", :room, "room"])
      |> Enum.into(%{
        end_date: ~D[2025-03-02],
        start_date: ~D[2025-03-02],
        patient_id: patient.id,
        nurse_id: nurse.id,
        room_id: room.id
      })
      |> Medcamp.RoomAllocations.create_room_allocation()

    room_allocation
  end
end
