defmodule Medcamp.InventoriesTest do
  use Medcamp.DataCase

  alias Medcamp.Inventories

  describe "general_inventory_items" do
    alias Medcamp.Inventories.GeneralInventoryItem

    import Medcamp.InventoriesFixtures

    @invalid_attrs %{
      name: nil,
      category: nil,
      unit_of_measure: nil,
      current_quantity: nil,
      reorder_level: nil,
      unit_cost: nil,
      supplier: nil,
      notes: nil
    }

    test "list_general_inventory_items/0 returns all general_inventory_items" do
      general_inventory_item = general_inventory_item_fixture()
      assert Inventories.list_general_inventory_items() == [general_inventory_item]
    end

    test "get_general_inventory_item!/1 returns the general_inventory_item with given id" do
      general_inventory_item = general_inventory_item_fixture()

      assert Inventories.get_general_inventory_item!(general_inventory_item.id) ==
               general_inventory_item
    end

    test "create_general_inventory_item/1 with valid data creates a general_inventory_item" do
      valid_attrs = %{
        name: "some name",
        category: "some category",
        unit_of_measure: "some unit_of_measure",
        current_quantity: "120.5",
        reorder_level: "120.5",
        unit_cost: "120.5",
        supplier: "some supplier",
        notes: "some notes",
        manufacturer: "some manufacturer",
        gtin: "some gtin",
        date_received: ~D[2025-11-01]
      }

      assert {:ok, %GeneralInventoryItem{} = general_inventory_item} =
               Inventories.create_general_inventory_item(valid_attrs)

      assert general_inventory_item.name == "some name"
      assert general_inventory_item.category == "some category"
      assert general_inventory_item.unit_of_measure == "some unit_of_measure"
      assert general_inventory_item.current_quantity == Decimal.new("120.5")
      assert general_inventory_item.reorder_level == Decimal.new("120.5")
      assert general_inventory_item.unit_cost == Decimal.new("120.5")
      assert general_inventory_item.supplier == "some supplier"
      assert general_inventory_item.notes == "some notes"
      assert general_inventory_item.manufacturer == "some manufacturer"
      assert general_inventory_item.gtin == "some gtin"
      assert general_inventory_item.date_received == ~D[2025-11-01]
    end

    test "create_general_inventory_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Inventories.create_general_inventory_item(@invalid_attrs)
    end

    test "update_general_inventory_item/2 with valid data updates the general_inventory_item" do
      general_inventory_item = general_inventory_item_fixture()

      update_attrs = %{
        name: "some updated name",
        category: "some updated category",
        unit_of_measure: "some updated unit_of_measure",
        current_quantity: "456.7",
        reorder_level: "456.7",
        unit_cost: "456.7",
        supplier: "some updated supplier",
        notes: "some updated notes"
      }

      assert {:ok, %GeneralInventoryItem{} = general_inventory_item} =
               Inventories.update_general_inventory_item(general_inventory_item, update_attrs)

      assert general_inventory_item.name == "some updated name"
      assert general_inventory_item.category == "some updated category"
      assert general_inventory_item.unit_of_measure == "some updated unit_of_measure"
      assert general_inventory_item.current_quantity == Decimal.new("456.7")
      assert general_inventory_item.reorder_level == Decimal.new("456.7")
      assert general_inventory_item.unit_cost == Decimal.new("456.7")
      assert general_inventory_item.supplier == "some updated supplier"
      assert general_inventory_item.notes == "some updated notes"
    end

    test "update_general_inventory_item/2 with invalid data returns error changeset" do
      general_inventory_item = general_inventory_item_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Inventories.update_general_inventory_item(general_inventory_item, @invalid_attrs)

      assert general_inventory_item ==
               Inventories.get_general_inventory_item!(general_inventory_item.id)
    end

    test "delete_general_inventory_item/1 deletes the general_inventory_item" do
      general_inventory_item = general_inventory_item_fixture()

      assert {:ok, %GeneralInventoryItem{}} =
               Inventories.delete_general_inventory_item(general_inventory_item)

      assert_raise Ecto.NoResultsError, fn ->
        Inventories.get_general_inventory_item!(general_inventory_item.id)
      end
    end

    test "change_general_inventory_item/1 returns a general_inventory_item changeset" do
      general_inventory_item = general_inventory_item_fixture()
      assert %Ecto.Changeset{} = Inventories.change_general_inventory_item(general_inventory_item)
    end
  end

  describe "general_inventory_transactions" do
    alias Medcamp.Inventories.GeneralInventoryTransaction

    import Medcamp.InventoriesFixtures

    @invalid_attrs %{
      reason: nil,
      transaction_type: nil,
      quantity: nil,
      notes: nil,
      recorded_by: nil,
      transaction_date: nil
    }

    test "list_general_inventory_transactions/0 returns all general_inventory_transactions" do
      general_inventory_transaction = general_inventory_transaction_fixture()
      assert Inventories.list_general_inventory_transactions() == [general_inventory_transaction]
    end

    test "get_general_inventory_transaction!/1 returns the general_inventory_transaction with given id" do
      general_inventory_transaction = general_inventory_transaction_fixture()

      assert Inventories.get_general_inventory_transaction!(general_inventory_transaction.id) ==
               general_inventory_transaction
    end

    test "create_general_inventory_transaction/1 with valid data creates a general_inventory_transaction" do
      general_inventory_item = general_inventory_item_fixture()

      valid_attrs = %{
        reason: "some reason",
        transaction_type: "received",
        quantity: "120.5",
        notes: "some notes",
        recorded_by: "some recorded_by",
        transaction_date: ~D[2025-11-01],
        general_inventory_item_id: general_inventory_item.id
      }

      assert {:ok, %GeneralInventoryTransaction{} = general_inventory_transaction} =
               Inventories.create_general_inventory_transaction(valid_attrs)

      assert general_inventory_transaction.reason == "some reason"
      assert general_inventory_transaction.transaction_type == "received"
      assert general_inventory_transaction.quantity == Decimal.new("120.5")
      assert general_inventory_transaction.notes == "some notes"
      assert general_inventory_transaction.recorded_by == "some recorded_by"
      assert general_inventory_transaction.transaction_date == ~D[2025-11-01]
    end

    test "create_general_inventory_transaction/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               Inventories.create_general_inventory_transaction(@invalid_attrs)
    end

    test "update_general_inventory_transaction/2 with valid data updates the general_inventory_transaction" do
      general_inventory_transaction = general_inventory_transaction_fixture()

      update_attrs = %{
        reason: "some updated reason",
        transaction_type: "adjustment",
        quantity: "456.7",
        notes: "some updated notes",
        recorded_by: "some updated recorded_by",
        transaction_date: ~D[2025-11-02]
      }

      assert {:ok, %GeneralInventoryTransaction{} = general_inventory_transaction} =
               Inventories.update_general_inventory_transaction(
                 general_inventory_transaction,
                 update_attrs
               )

      assert general_inventory_transaction.reason == "some updated reason"
      assert general_inventory_transaction.transaction_type == "adjustment"
      assert general_inventory_transaction.quantity == Decimal.new("456.7")
      assert general_inventory_transaction.notes == "some updated notes"
      assert general_inventory_transaction.recorded_by == "some updated recorded_by"
      assert general_inventory_transaction.transaction_date == ~D[2025-11-02]
    end

    test "update_general_inventory_transaction/2 with invalid data returns error changeset" do
      general_inventory_transaction = general_inventory_transaction_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Inventories.update_general_inventory_transaction(
                 general_inventory_transaction,
                 @invalid_attrs
               )

      assert general_inventory_transaction ==
               Inventories.get_general_inventory_transaction!(general_inventory_transaction.id)
    end

    test "delete_general_inventory_transaction/1 deletes the general_inventory_transaction" do
      general_inventory_transaction = general_inventory_transaction_fixture()

      assert {:ok, %GeneralInventoryTransaction{}} =
               Inventories.delete_general_inventory_transaction(general_inventory_transaction)

      assert_raise Ecto.NoResultsError, fn ->
        Inventories.get_general_inventory_transaction!(general_inventory_transaction.id)
      end
    end

    test "change_general_inventory_transaction/1 returns a general_inventory_transaction changeset" do
      general_inventory_transaction = general_inventory_transaction_fixture()

      assert %Ecto.Changeset{} =
               Inventories.change_general_inventory_transaction(general_inventory_transaction)
    end
  end
end
