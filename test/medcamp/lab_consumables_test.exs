defmodule Medcamp.LabConsumablesTest do
  use Medcamp.DataCase

  alias Medcamp.LabConsumables

  describe "lab_consumables" do
    alias Medcamp.LabConsumables.LabConsumable

    import Medcamp.LabConsumablesFixtures

    @invalid_attrs %{date: nil, consumed_quantity: nil, purpose: nil}

    test "list_lab_consumables/0 returns all lab_consumables" do
      lab_consumable = lab_consumable_fixture()
      assert LabConsumables.list_lab_consumables() == [lab_consumable]
    end

    test "get_lab_consumable!/1 returns the lab_consumable with given id" do
      lab_consumable = lab_consumable_fixture()
      assert LabConsumables.get_lab_consumable!(lab_consumable.id) == lab_consumable
    end

    test "create_lab_consumable/1 with valid data creates a lab_consumable" do
      valid_attrs = %{
        date: "some date",
        consumed_quantity: "some consumed_quantity",
        purpose: "some purpose"
      }

      assert {:ok, %LabConsumable{} = lab_consumable} =
               LabConsumables.create_lab_consumable(valid_attrs)

      assert lab_consumable.date == "some date"
      assert lab_consumable.consumed_quantity == "some consumed_quantity"
      assert lab_consumable.purpose == "some purpose"
    end

    test "create_lab_consumable/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = LabConsumables.create_lab_consumable(@invalid_attrs)
    end

    test "update_lab_consumable/2 with valid data updates the lab_consumable" do
      lab_consumable = lab_consumable_fixture()

      update_attrs = %{
        date: "some updated date",
        consumed_quantity: "some updated consumed_quantity",
        purpose: "some updated purpose"
      }

      assert {:ok, %LabConsumable{} = lab_consumable} =
               LabConsumables.update_lab_consumable(lab_consumable, update_attrs)

      assert lab_consumable.date == "some updated date"
      assert lab_consumable.consumed_quantity == "some updated consumed_quantity"
      assert lab_consumable.purpose == "some updated purpose"
    end

    test "update_lab_consumable/2 with invalid data returns error changeset" do
      lab_consumable = lab_consumable_fixture()

      assert {:error, %Ecto.Changeset{}} =
               LabConsumables.update_lab_consumable(lab_consumable, @invalid_attrs)

      assert lab_consumable == LabConsumables.get_lab_consumable!(lab_consumable.id)
    end

    test "delete_lab_consumable/1 deletes the lab_consumable" do
      lab_consumable = lab_consumable_fixture()
      assert {:ok, %LabConsumable{}} = LabConsumables.delete_lab_consumable(lab_consumable)

      assert_raise Ecto.NoResultsError, fn ->
        LabConsumables.get_lab_consumable!(lab_consumable.id)
      end
    end

    test "change_lab_consumable/1 returns a lab_consumable changeset" do
      lab_consumable = lab_consumable_fixture()
      assert %Ecto.Changeset{} = LabConsumables.change_lab_consumable(lab_consumable)
    end
  end
end
