defmodule Medcamp.RoomEquipmentsTest do
  use Medcamp.DataCase

  alias Medcamp.RoomEquipments

  describe "room_equipments" do
    alias Medcamp.RoomEquipments.RoomEquipment

    import Medcamp.RoomEquipmentsFixtures

    @invalid_attrs %{name: nil, description: nil, image: nil, room_id: nil}

    test "list_room_equipments/0 returns all room_equipments" do
      room_equipment = room_equipment_fixture()
      assert [%RoomEquipment{id: id}] = RoomEquipments.list_room_equipments()
      assert id == room_equipment.id
    end

    test "get_room_equipment!/1 returns the room_equipment with given id" do
      room_equipment = room_equipment_fixture()
      assert RoomEquipments.get_room_equipment!(room_equipment.id).id == room_equipment.id
    end

    test "create_room_equipment/1 with valid data creates a room_equipment" do
      room = Medcamp.RoomsFixtures.room_fixture()

      valid_attrs = %{
        name: "some name",
        description: "some description",
        image: "some image",
        room_id: room.id
      }

      assert {:ok, %RoomEquipment{} = room_equipment} =
               RoomEquipments.create_room_equipment(valid_attrs)

      assert room_equipment.name == "some name"
      assert room_equipment.description == "some description"
      assert room_equipment.image == "some image"
      assert room_equipment.room_id == room.id
    end

    test "create_room_equipment/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = RoomEquipments.create_room_equipment(@invalid_attrs)
    end

    test "update_room_equipment/2 with valid data updates the room_equipment" do
      room_equipment = room_equipment_fixture()

      update_attrs = %{
        name: "some updated name",
        description: "some updated description",
        image: "some updated image"
      }

      assert {:ok, %RoomEquipment{} = room_equipment} =
               RoomEquipments.update_room_equipment(room_equipment, update_attrs)

      assert room_equipment.name == "some updated name"
      assert room_equipment.description == "some updated description"
      assert room_equipment.image == "some updated image"
    end

    test "update_room_equipment/2 with invalid data returns error changeset" do
      room_equipment = room_equipment_fixture()

      assert {:error, %Ecto.Changeset{}} =
               RoomEquipments.update_room_equipment(room_equipment, @invalid_attrs)

      assert RoomEquipments.get_room_equipment!(room_equipment.id).name == room_equipment.name
    end

    test "delete_room_equipment/1 deletes the room_equipment" do
      room_equipment = room_equipment_fixture()
      assert {:ok, %RoomEquipment{}} = RoomEquipments.delete_room_equipment(room_equipment)

      assert_raise Ecto.NoResultsError, fn ->
        RoomEquipments.get_room_equipment!(room_equipment.id)
      end
    end

    test "change_room_equipment/1 returns a room_equipment changeset" do
      room_equipment = room_equipment_fixture()
      assert %Ecto.Changeset{} = RoomEquipments.change_room_equipment(room_equipment)
    end
  end
end
