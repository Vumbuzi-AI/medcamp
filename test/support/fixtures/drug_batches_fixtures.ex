defmodule Medcamp.DrugBatchesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.DrugBatches` context.
  """

  @doc """
  Generate a drug_batch.
  """
  def drug_batch_fixture(attrs \\ %{}) do
    drug = Map.get(attrs, :drug) || Map.get(attrs, "drug") || Medcamp.DrugsFixtures.drug_fixture()

    batch =
      Map.get(attrs, :batch) || Map.get(attrs, "batch") || Medcamp.BatchesFixtures.batch_fixture()

    inventory_received =
      Map.get(attrs, :inventory_received) || Map.get(attrs, "inventory_received") ||
        Medcamp.InventoriesReceivedFixtures.inventory_received_fixture()

    inventory_manager =
      Map.get(attrs, :inventory_manager) || Map.get(attrs, "inventory_manager") ||
        Medcamp.AccountsFixtures.user_fixture()

    {:ok, drug_batch} =
      attrs
      |> Map.drop([
        :drug,
        "drug",
        :batch,
        "batch",
        :inventory_received,
        "inventory_received",
        :inventory_manager,
        "inventory_manager"
      ])
      |> Enum.into(%{
        drug_id: drug.id,
        batch_id: batch.id,
        inventory_received_id: inventory_received.id,
        inventory_manager_id: inventory_manager.id,
        remaining_quantity: 42
      })
      |> Medcamp.DrugBatches.create_drug_batch()

    drug_batch
  end
end
