defmodule Medcamp.InventoriesIssuesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.InventoriesIssues` context.
  """

  @doc """
  Generate a inventory_issued.
  """
  def inventory_issued_fixture(attrs \\ %{}) do
    batch =
      Map.get(attrs, :batch) || Map.get(attrs, "batch") || Medcamp.BatchesFixtures.batch_fixture()

    inventory_received =
      Map.get(attrs, :inventory_received) || Map.get(attrs, "inventory_received") ||
        Medcamp.InventoriesReceivedFixtures.inventory_received_fixture()

    inventory_manager =
      Map.get(attrs, :inventory_manager) || Map.get(attrs, "inventory_manager") ||
        Medcamp.AccountsFixtures.user_fixture()

    assigned_to =
      Map.get(attrs, :assigned_to) || Map.get(attrs, "assigned_to") ||
        Medcamp.AccountsFixtures.user_fixture()

    {:ok, inventory_issued} =
      attrs
      |> Map.drop([
        :batch,
        "batch",
        :inventory_received,
        "inventory_received",
        :inventory_manager,
        "inventory_manager",
        :assigned_to,
        "assigned_to"
      ])
      |> Enum.into(%{
        description: "some description",
        gtin: "some gtin",
        location: "some location",
        quantity: 42,
        batch_id: batch.id,
        inventory_received_id: inventory_received.id,
        inventory_manager_id: inventory_manager.id,
        assigned_to_id: assigned_to.id
      })
      |> Medcamp.InventoriesIssues.create_inventory_issued()

    inventory_issued
  end
end
