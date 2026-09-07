defmodule Medcamp.AllergyHistoriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.AllergyHistories` context.
  """

  @doc """
  Generate an allergy_history.
  """
  def allergy_history_fixture(attrs \\ %{}) do
    patient =
      Map.get(attrs, :patient) || Map.get(attrs, "patient") ||
        Medcamp.PatientsFixtures.patient_fixture()

    {:ok, allergy_history} =
      attrs
      |> Map.drop([:patient, "patient"])
      |> Enum.into(%{
        patient_id: patient.id,
        substance_name: "Penicillin",
        category: "medication",
        type: "allergy",
        criticality: "high"
      })
      |> Medcamp.AllergyHistories.create_allergy_history()

    allergy_history
  end
end
