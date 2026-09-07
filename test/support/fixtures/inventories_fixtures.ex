defmodule Medcamp.InventoriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.Inventories` context.
  """

  @doc """
  Generate a general_inventory_item.
  """
  def general_inventory_item_fixture(attrs \\ %{}) do
    {:ok, general_inventory_item} =
      attrs
      |> Enum.into(%{
        category: "some category",
        current_quantity: "120.5",
        date_received: ~D[2025-11-01],
        gtin: "some gtin",
        manufacturer: "some manufacturer",
        name: "some name",
        notes: "some notes",
        reorder_level: "120.5",
        supplier: "some supplier",
        unit_cost: "120.5",
        unit_of_measure: "some unit_of_measure"
      })
      |> Medcamp.Inventories.create_general_inventory_item()

    general_inventory_item
  end

  @doc """
  Generate a general_inventory_transaction.
  """
  def general_inventory_transaction_fixture(attrs \\ %{}) do
    general_inventory_item =
      Map.get(attrs, :general_inventory_item) || Map.get(attrs, "general_inventory_item") ||
        general_inventory_item_fixture()

    {:ok, general_inventory_transaction} =
      attrs
      |> Map.drop([:general_inventory_item, "general_inventory_item"])
      |> Enum.into(%{
        notes: "some notes",
        quantity: "120.5",
        reason: "some reason",
        recorded_by: "some recorded_by",
        transaction_date: ~D[2025-11-01],
        transaction_type: "received",
        general_inventory_item_id: general_inventory_item.id
      })
      |> Medcamp.Inventories.create_general_inventory_transaction()

    general_inventory_transaction
  end
end
