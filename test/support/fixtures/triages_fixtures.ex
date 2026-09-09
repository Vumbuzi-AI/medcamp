defmodule Medcamp.TriagesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.Triages` context.
  """

  @doc """
  Generate a triage.
  """
  def triage_fixture(attrs \\ %{}) do
    patient =
      Map.get(attrs, :patient) || Map.get(attrs, "patient") ||
        Medcamp.PatientsFixtures.patient_fixture()

    creator =
      Map.get(attrs, :creator) || Map.get(attrs, "creator") ||
        Medcamp.AccountsFixtures.user_fixture(%{role: "nurse"})

    {:ok, triage} =
      attrs
      |> Map.drop([:patient, "patient", :creator, "creator"])
      |> Enum.into(%{
        blood_pressure: "120/80",
        date: ~D[2025-02-21],
        height: 120.5,
        oxygen_saturation: 120.5,
        patient_id: patient.id,
        pulse_rate: 120.5,
        temperature: 120.5,
        triage_notes: "some triage_notes",
        weight: 120.5,
        creator_id: creator.id
      })
      |> Medcamp.Triages.create_triage()

    triage
  end
end
