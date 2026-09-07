defmodule Medcamp.InventoriesReceivedTest do
  use Medcamp.DataCase

  alias Medcamp.InventoriesReceived

  describe "inventories_received" do
    alias Medcamp.InventoriesReceived.InventoryReceived

    import Medcamp.InventoriesReceivedFixtures

    @invalid_attrs %{
      type: nil,
      description: nil,
      image: nil,
      gtin: nil,
      brand_name: nil,
      generic_name: nil,
      weight: nil,
      uom: nil,
      supplier: nil
    }

    test "list_inventories_received/0 returns all inventories_received" do
      inventory_received = inventory_received_fixture()
      assert [%InventoryReceived{id: id}] = InventoriesReceived.list_inventories_received()
      assert id == inventory_received.id
    end

    test "get_inventory_received!/1 returns the inventory_received with given id" do
      inventory_received = inventory_received_fixture()

      assert InventoriesReceived.get_inventory_received!(inventory_received.id).id ==
               inventory_received.id
    end

    test "create_inventory_received/1 with valid data creates a inventory_received" do
      valid_attrs = %{
        type: "some type",
        description: "some description",
        image: "some image",
        gtin: "some gtin",
        brand_name: "some brand_name",
        generic_name: "some generic_name",
        weight: 42,
        uom: "some uom",
        supplier: "some supplier"
      }

      assert {:ok, %InventoryReceived{} = inventory_received} =
               InventoriesReceived.create_inventory_received(valid_attrs)

      assert inventory_received.type == "some type"
      assert inventory_received.description == "some description"
      assert inventory_received.image == "some image"
      assert inventory_received.gtin == "some gtin"
      assert inventory_received.brand_name == "some brand_name"
      assert inventory_received.generic_name == "some generic_name"
      assert inventory_received.weight == 42
      assert inventory_received.uom == "some uom"
      assert inventory_received.supplier == "some supplier"
    end

    test "create_inventory_received/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               InventoriesReceived.create_inventory_received(@invalid_attrs)
    end

    test "update_inventory_received/2 with valid data updates the inventory_received" do
      inventory_received = inventory_received_fixture()

      update_attrs = %{
        type: "some updated type",
        description: "some updated description",
        image: "some updated image",
        gtin: "some updated gtin",
        brand_name: "some updated brand_name",
        generic_name: "some updated generic_name",
        weight: 43,
        uom: "some updated uom",
        supplier: "some updated supplier"
      }

      assert {:ok, %InventoryReceived{} = inventory_received} =
               InventoriesReceived.update_inventory_received(inventory_received, update_attrs)

      assert inventory_received.type == "some updated type"
      assert inventory_received.description == "some updated description"
      assert inventory_received.image == "some updated image"
      assert inventory_received.gtin == "some updated gtin"
      assert inventory_received.brand_name == "some updated brand_name"
      assert inventory_received.generic_name == "some updated generic_name"
      assert inventory_received.weight == 43
      assert inventory_received.uom == "some updated uom"
      assert inventory_received.supplier == "some updated supplier"
    end

    test "update_inventory_received/2 with invalid data returns error changeset" do
      inventory_received = inventory_received_fixture()

      assert {:error, %Ecto.Changeset{}} =
               InventoriesReceived.update_inventory_received(inventory_received, @invalid_attrs)

      assert InventoriesReceived.get_inventory_received!(inventory_received.id).gtin ==
               inventory_received.gtin
    end

    test "delete_inventory_received/1 deletes the inventory_received" do
      inventory_received = inventory_received_fixture()

      assert {:ok, %InventoryReceived{}} =
               InventoriesReceived.delete_inventory_received(inventory_received)

      assert_raise Ecto.NoResultsError, fn ->
        InventoriesReceived.get_inventory_received!(inventory_received.id)
      end
    end

    test "change_inventory_received/1 returns a inventory_received changeset" do
      inventory_received = inventory_received_fixture()
      assert %Ecto.Changeset{} = InventoriesReceived.change_inventory_received(inventory_received)
    end
  end
end
