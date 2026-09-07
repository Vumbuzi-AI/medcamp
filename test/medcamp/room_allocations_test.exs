defmodule Medcamp.RoomAllocationsTest do
  use Medcamp.DataCase

  alias Medcamp.RoomAllocations

  describe "room_allocations" do
    alias Medcamp.RoomAllocations.RoomAllocation

    import Medcamp.RoomAllocationsFixtures
    import Medcamp.PatientsFixtures
    import Medcamp.AccountsFixtures
    import Medcamp.RoomsFixtures

    @invalid_attrs %{start_date: nil, end_date: nil}

    test "list_room_allocations/0 returns all room_allocations" do
      room_allocation = room_allocation_fixture()

      assert RoomAllocations.list_room_allocations() == [
               Medcamp.Repo.preload(room_allocation, [:patient, :nurse, :room])
             ]
    end

    test "get_room_allocation!/1 returns the room_allocation with given id" do
      room_allocation = room_allocation_fixture()
      assert RoomAllocations.get_room_allocation!(room_allocation.id) == room_allocation
    end

    test "create_room_allocation/1 with valid data creates a room_allocation" do
      patient = patient_fixture()
      nurse = user_fixture()
      room = room_fixture()

      valid_attrs = %{
        start_date: ~D[2025-03-02],
        end_date: ~D[2025-03-02],
        patient_id: patient.id,
        nurse_id: nurse.id,
        room_id: room.id
      }

      assert {:ok, %RoomAllocation{} = room_allocation} =
               RoomAllocations.create_room_allocation(valid_attrs)

      assert room_allocation.start_date == ~D[2025-03-02]
      assert room_allocation.end_date == ~D[2025-03-02]
      assert room_allocation.patient_id == patient.id
      assert room_allocation.nurse_id == nurse.id
      assert room_allocation.room_id == room.id
    end

    test "create_room_allocation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = RoomAllocations.create_room_allocation(@invalid_attrs)
    end

    test "update_room_allocation/2 with valid data updates the room_allocation" do
      room_allocation = room_allocation_fixture()
      update_attrs = %{start_date: ~D[2025-03-03], end_date: ~D[2025-03-03]}

      assert {:ok, %RoomAllocation{} = room_allocation} =
               RoomAllocations.update_room_allocation(room_allocation, update_attrs)

      assert room_allocation.start_date == ~D[2025-03-03]
      assert room_allocation.end_date == ~D[2025-03-03]
    end

    test "update_room_allocation/2 with invalid data returns error changeset" do
      room_allocation = room_allocation_fixture()

      assert {:error, %Ecto.Changeset{}} =
               RoomAllocations.update_room_allocation(room_allocation, @invalid_attrs)

      assert room_allocation == RoomAllocations.get_room_allocation!(room_allocation.id)
    end

    test "delete_room_allocation/1 deletes the room_allocation" do
      room_allocation = room_allocation_fixture()
      assert {:ok, %RoomAllocation{}} = RoomAllocations.delete_room_allocation(room_allocation)

      assert_raise Ecto.NoResultsError, fn ->
        RoomAllocations.get_room_allocation!(room_allocation.id)
      end
    end

    test "change_room_allocation/1 returns a room_allocation changeset" do
      room_allocation = room_allocation_fixture()
      assert %Ecto.Changeset{} = RoomAllocations.change_room_allocation(room_allocation)
    end
  end
end
