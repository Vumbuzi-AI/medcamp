defmodule Medcamp.AssignedTagsTest do
  use Medcamp.DataCase

  alias Medcamp.AssignedTags

  describe "assigned_tags" do
    alias Medcamp.AssignedTags.AssignedTag

    import Medcamp.AssignedTagsFixtures

    @invalid_attrs %{date: nil, number: nil, remaining_number: nil}

    test "list_assigned_tags/0 returns all assigned_tags" do
      assigned_tag = assigned_tag_fixture()
      assert AssignedTags.list_assigned_tags() == [assigned_tag]
    end

    test "get_assigned_tag!/1 returns the assigned_tag with given id" do
      assigned_tag = assigned_tag_fixture()
      assert AssignedTags.get_assigned_tag!(assigned_tag.id) == assigned_tag
    end

    test "create_assigned_tag/1 with valid data creates a assigned_tag" do
      valid_attrs = %{date: ~D[2025-08-27], number: 42, remaining_number: 42}

      assert {:ok, %AssignedTag{} = assigned_tag} = AssignedTags.create_assigned_tag(valid_attrs)
      assert assigned_tag.date == ~D[2025-08-27]
      assert assigned_tag.number == 42
      assert assigned_tag.remaining_number == 42
    end

    test "create_assigned_tag/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = AssignedTags.create_assigned_tag(@invalid_attrs)
    end

    test "update_assigned_tag/2 with valid data updates the assigned_tag" do
      assigned_tag = assigned_tag_fixture()
      update_attrs = %{date: ~D[2025-08-28], number: 43, remaining_number: 43}

      assert {:ok, %AssignedTag{} = assigned_tag} =
               AssignedTags.update_assigned_tag(assigned_tag, update_attrs)

      assert assigned_tag.date == ~D[2025-08-28]
      assert assigned_tag.number == 43
      assert assigned_tag.remaining_number == 43
    end

    test "update_assigned_tag/2 with invalid data returns error changeset" do
      assigned_tag = assigned_tag_fixture()

      assert {:error, %Ecto.Changeset{}} =
               AssignedTags.update_assigned_tag(assigned_tag, @invalid_attrs)

      assert assigned_tag == AssignedTags.get_assigned_tag!(assigned_tag.id)
    end

    test "delete_assigned_tag/1 deletes the assigned_tag" do
      assigned_tag = assigned_tag_fixture()
      assert {:ok, %AssignedTag{}} = AssignedTags.delete_assigned_tag(assigned_tag)
      assert_raise Ecto.NoResultsError, fn -> AssignedTags.get_assigned_tag!(assigned_tag.id) end
    end

    test "change_assigned_tag/1 returns a assigned_tag changeset" do
      assigned_tag = assigned_tag_fixture()
      assert %Ecto.Changeset{} = AssignedTags.change_assigned_tag(assigned_tag)
    end
  end
end
