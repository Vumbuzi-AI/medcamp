defmodule Medcamp.PatientVisitsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.PatientVisits` context.
  """

  @doc """
  Generate a patient_visit.
  """
  def patient_visit_fixture(attrs \\ %{}) do
    patient =
      Map.get(attrs, :patient) || Map.get(attrs, "patient") ||
        Medcamp.PatientsFixtures.patient_fixture()

    creator =
      Map.get(attrs, :creator) || Map.get(attrs, "creator") ||
        Medcamp.AccountsFixtures.user_fixture()

    {:ok, patient_visit} =
      attrs
      |> Map.drop([:patient, "patient", :creator, "creator"])
      |> Enum.into(%{
        date: ~D[2025-02-24],
        reason: "some reason",
        payment_type: "some payment_type",
        has_paid: true,
        patient_id: patient.id,
        creator_id: creator.id
      })
      |> Medcamp.PatientVisits.create_patient_visit()

    patient_visit
  end
end
