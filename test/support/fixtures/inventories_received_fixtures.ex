defmodule Medcamp.InventoriesReceivedFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.InventoriesReceived` context.
  """

  @doc """
  Generate a inventory_received.
  """
  def inventory_received_fixture(attrs \\ %{}) do
    {:ok, inventory_received} =
      attrs
      |> Enum.into(%{
        brand_name: "some brand_name",
        description: "some description",
        generic_name: "some generic_name",
        gtin: "gtin-#{System.unique_integer([:positive])}",
        image: "some image",
        supplier: "some supplier",
        type: "some type",
        uom: "some uom",
        weight: 42
      })
      |> Medcamp.InventoriesReceived.create_inventory_received()

    inventory_received
  end
end
