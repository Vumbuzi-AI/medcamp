defmodule Medcamp.RoomsTest do
  use Medcamp.DataCase

  alias Medcamp.Rooms

  describe "rooms" do
    alias Medcamp.Rooms.Room

    import Medcamp.RoomsFixtures

    @invalid_attrs %{room_number: nil, is_free: nil, added_by: nil, type: nil, name: nil}

    test "list_rooms/0 returns all rooms" do
      room = room_fixture()
      assert [%Room{id: id}] = Rooms.list_rooms()
      assert id == room.id
    end

    test "get_room!/1 returns the room with given id" do
      room = room_fixture()
      assert Rooms.get_room!(room.id) == room
    end

    test "create_room/1 with valid data creates a room" do
      user = Medcamp.AccountsFixtures.user_fixture()

      valid_attrs = %{
        added_by: user.id,
        is_free: true,
        name: "some name",
        room_number: "some room_number",
        type: "ward"
      }

      assert {:ok, %Room{} = room} = Rooms.create_room(valid_attrs)
      assert room.room_number == "some room_number"
      assert room.is_free == true
      assert room.added_by == user.id
      assert room.name == "some name"
      assert room.type == "ward"
    end

    test "create_room/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Rooms.create_room(@invalid_attrs)
    end

    test "update_room/2 with valid data updates the room" do
      room = room_fixture()

      update_attrs = %{
        room_number: "some updated room_number",
        is_free: false,
        name: "some updated name",
        type: "consultation"
      }

      assert {:ok, %Room{} = room} = Rooms.update_room(room, update_attrs)
      assert room.room_number == "some updated room_number"
      assert room.is_free == false
      assert room.name == "some updated name"
      assert room.type == "consultation"
    end

    test "update_room/2 with invalid data returns error changeset" do
      room = room_fixture()
      assert {:error, %Ecto.Changeset{}} = Rooms.update_room(room, @invalid_attrs)
      assert Rooms.get_room!(room.id).room_number == room.room_number
    end

    test "delete_room/1 deletes the room" do
      room = room_fixture()
      assert {:ok, %Room{}} = Rooms.delete_room(room)
      assert_raise Ecto.NoResultsError, fn -> Rooms.get_room!(room.id) end
    end

    test "change_room/1 returns a room changeset" do
      room = room_fixture()
      assert %Ecto.Changeset{} = Rooms.change_room(room)
    end
  end
end
