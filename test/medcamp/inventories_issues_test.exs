defmodule Medcamp.InventoriesIssuesTest do
  use Medcamp.DataCase

  alias Medcamp.InventoriesIssues

  describe "inventories_issued" do
    alias Medcamp.InventoriesIssues.InventoryIssued

    import Medcamp.InventoriesIssuesFixtures

    @invalid_attrs %{description: nil, location: nil, gtin: nil, quantity: nil}

    test "list_inventories_issued/0 returns all inventories_issued" do
      inventory_issued = inventory_issued_fixture()
      assert [%InventoryIssued{id: id}] = InventoriesIssues.list_inventories_issued()
      assert id == inventory_issued.id
    end

    test "get_inventory_issued!/1 returns the inventory_issued with given id" do
      inventory_issued = inventory_issued_fixture()

      assert InventoriesIssues.get_inventory_issued!(inventory_issued.id).id ==
               inventory_issued.id
    end

    test "create_inventory_issued/1 with valid data creates a inventory_issued" do
      batch = Medcamp.BatchesFixtures.batch_fixture()
      inventory_received = Medcamp.InventoriesReceivedFixtures.inventory_received_fixture()
      inventory_manager = Medcamp.AccountsFixtures.user_fixture()
      assigned_to = Medcamp.AccountsFixtures.user_fixture()

      valid_attrs = %{
        description: "some description",
        location: "some location",
        gtin: "some gtin",
        quantity: 42,
        batch_id: batch.id,
        inventory_received_id: inventory_received.id,
        inventory_manager_id: inventory_manager.id,
        assigned_to_id: assigned_to.id
      }

      assert {:ok, %InventoryIssued{} = inventory_issued} =
               InventoriesIssues.create_inventory_issued(valid_attrs)

      assert inventory_issued.description == "some description"
      assert inventory_issued.location == "some location"
      assert inventory_issued.gtin == "some gtin"
      assert inventory_issued.quantity == 42
      assert inventory_issued.batch_id == batch.id
      assert inventory_issued.inventory_received_id == inventory_received.id
      assert inventory_issued.inventory_manager_id == inventory_manager.id
      assert inventory_issued.assigned_to_id == assigned_to.id
    end

    test "create_inventory_issued/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               InventoriesIssues.create_inventory_issued(@invalid_attrs)
    end

    test "update_inventory_issued/2 with valid data updates the inventory_issued" do
      inventory_issued = inventory_issued_fixture()

      update_attrs = %{
        description: "some updated description",
        location: "some updated location",
        gtin: "some updated gtin",
        quantity: 40
      }

      assert {:ok, %InventoryIssued{} = inventory_issued} =
               InventoriesIssues.update_inventory_issued(inventory_issued, update_attrs)

      assert inventory_issued.description == "some updated description"
      assert inventory_issued.location == "some updated location"
      assert inventory_issued.gtin == "some updated gtin"
      assert inventory_issued.quantity == 40
    end

    test "update_inventory_issued/2 with invalid data returns error changeset" do
      inventory_issued = inventory_issued_fixture()

      assert {:error, %Ecto.Changeset{}} =
               InventoriesIssues.update_inventory_issued(inventory_issued, @invalid_attrs)

      assert inventory_issued.id ==
               InventoriesIssues.get_inventory_issued!(inventory_issued.id).id
    end

    test "delete_inventory_issued/1 deletes the inventory_issued" do
      inventory_issued = inventory_issued_fixture()

      assert {:ok, %InventoryIssued{}} =
               InventoriesIssues.delete_inventory_issued(inventory_issued)

      assert_raise Ecto.NoResultsError, fn ->
        InventoriesIssues.get_inventory_issued!(inventory_issued.id)
      end
    end

    test "change_inventory_issued/1 returns a inventory_issued changeset" do
      inventory_issued = inventory_issued_fixture()
      assert %Ecto.Changeset{} = InventoriesIssues.change_inventory_issued(inventory_issued)
    end
  end
end
