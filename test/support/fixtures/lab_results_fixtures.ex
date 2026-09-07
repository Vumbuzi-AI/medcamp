defmodule Medcamp.LabResultsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.LabResults` context.
  """

  @doc """
  Generate a lab_result.
  """
  def lab_result_fixture(attrs \\ %{}) do
    attrs = Enum.into(attrs, %{})

    doctor =
      Map.get(attrs, :doctor) || Map.get(attrs, "doctor") || Medcamp.AccountsFixtures.user_fixture()

    patient =
      Map.get(attrs, :patient) || Map.get(attrs, "patient") ||
        Medcamp.PatientsFixtures.patient_fixture()

    doctor_note =
      Map.get(attrs, :doctor_note) ||
        Map.get(attrs, "doctor_note") ||
        Medcamp.DoctorNotesFixtures.doctor_note_fixture(doctor: doctor, patient: patient)

    {:ok, lab_result} =
      attrs
      |> Map.drop([:doctor, "doctor", :patient, "patient", :doctor_note, "doctor_note"])
      |> Enum.into(%{
        date_of_test: ~D[2025-02-21],
        doctor_id: doctor.id,
        doctor_note_id: doctor_note.id,
        lab_report: "some lab_report",
        name: "some name",
        patient_id: patient.id,
        report_complete: true,
        sample_collection_date: ~D[2025-02-21],
        sample_collection_description: "some sample_collection_description",
        technician_name: "some technician_name",
        test_findings: "some test_findings",
        urgency: "some urgency"
      })
      |> Medcamp.LabResults.create_lab_result()

    lab_result
  end
end
