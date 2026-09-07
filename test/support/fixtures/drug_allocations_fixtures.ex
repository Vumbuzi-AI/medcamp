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

    {:ok, drug_allocation} =
      attrs
      |> Map.drop([:patient, "patient"])
      |> Enum.into(%{
        has_been_assigned: false,
        patient_id: patient.id,
        prescription: "some prescription",
        quantity: 42
      })
      |> Medcamp.DrugAllocations.create_drug_allocation()

    drug_allocation
  end
end
