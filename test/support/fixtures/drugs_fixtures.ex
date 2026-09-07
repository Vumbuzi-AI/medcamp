defmodule Medcamp.DrugsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.Drugs` context.
  """

  @doc """
  Generate a drug.
  """
  def drug_fixture(attrs \\ %{}) do
    inventory_received =
      Map.get(attrs, :inventory_received) ||
        Map.get(attrs, "inventory_received") ||
        Medcamp.InventoriesReceivedFixtures.inventory_received_fixture()

    inventory_manager =
      Map.get(attrs, :inventory_manager) ||
        Map.get(attrs, "inventory_manager") ||
        Medcamp.AccountsFixtures.user_fixture()

    {:ok, drug} =
      attrs
      |> Map.drop([
        :inventory_received,
        "inventory_received",
        :inventory_manager,
        "inventory_manager"
      ])
      |> Enum.into(%{
        brand_name: "some brand_name",
        generic_name: "some generic_name",
        inventory_received_id: inventory_received.id,
        inventory_manager_id: inventory_manager.id,
        is_otc: true,
        is_dangerous_drug: false
      })
      |> Medcamp.Drugs.create_drug()

    drug
  end
end
