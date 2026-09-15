defmodule Medcamp.DrugAllocationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.DrugAllocations` context.
  """

  @doc """
  Generate a drug_allocation.
  """
  def drug_allocation_fixture(attrs \\ %{}) do
    patient =
      Map.get(attrs, :patient) || Map.get(attrs, "patient") ||
        Medcamp.PatientsFixtures.patient_fixture()

    drugs_assigned =
      case Map.get(attrs, :drugs_assigned) || Map.get(attrs, "drugs_assigned") do
        nil ->
          inventory_received = Medcamp.InventoriesReceivedFixtures.inventory_received_fixture()
          drug = Medcamp.DrugsFixtures.drug_fixture(%{inventory_received: inventory_received})

          Medcamp.DrugBatchesFixtures.drug_batch_fixture(%{
            inventory_received: inventory_received,
            drug: drug,
            remaining_quantity: 42
          })

          [
            %{
              brand_name: drug.brand_name,
              generic_name: drug.generic_name,
              inventory_received_id: inventory_received.id,
              quantity: 1,
              frequency: "OD",
              duration_in_days: 1,
              route_of_administration: "Oral"
            }
          ]

        assigned ->
          Enum.map(assigned, &put_default_route/1)
      end

    {:ok, drug_allocation} =
      attrs
      |> Map.drop([:patient, "patient", :drugs_assigned, "drugs_assigned"])
      |> Enum.into(%{
        has_been_assigned: false,
        patient_id: patient.id,
        prescription: "some prescription",
        drugs_assigned: drugs_assigned,
        quantity: 42
      })
      |> Medcamp.DrugAllocations.create_drug_allocation()

    drug_allocation
  end

  defp put_default_route(drug) do
    if Enum.any?(Map.keys(drug), &is_binary/1) do
      Map.put_new(drug, "route_of_administration", "Oral")
    else
      Map.put_new(drug, :route_of_administration, "Oral")
    end
  end
end
