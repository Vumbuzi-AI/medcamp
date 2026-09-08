defmodule Medcamp.DoctorNotesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.DoctorNotes` context.
  """

  @doc """
  Generate a doctor_note.
  """
  def doctor_note_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})

    doctor =
      Map.get(attrs, :doctor) || Map.get(attrs, "doctor") ||
        Medcamp.AccountsFixtures.user_fixture()

    patient =
      Map.get(attrs, :patient) || Map.get(attrs, "patient") ||
        Medcamp.PatientsFixtures.patient_fixture()

    {:ok, doctor_note} =
      attrs
      |> Map.drop([:doctor, "doctor", :patient, "patient"])
      |> Enum.into(%{
        date: ~D[2025-02-21],
        doctor_id: doctor.id,
        lab_imaging_request: "some lab_imaging_request",
        lifestyle_recommendations: "some lifestyle_recommendations",
        patient_id: patient.id,
        prescribed_medication: "some prescribed_medication",
        reason_for_consulatation: "some reason_for_consulatation",
        symptoms: "some symptoms",
        time: ~T[16:55:33]
      })
      |> Medcamp.DoctorNotes.create_doctor_note()

    doctor_note
  end
end
