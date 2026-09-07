defmodule Medcamp.RadiologyResultsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.RadiologyResults` context.
  """

  @doc """
  Generate a radiology_result.
  """
  def radiology_result_fixture(attrs \\ %{}) do
    doctor_note =
      Map.get(attrs, :doctor_note) || Map.get(attrs, "doctor_note") ||
        Medcamp.DoctorNotesFixtures.doctor_note_fixture()

    {:ok, radiology_result} =
      attrs
      |> Map.drop([:doctor_note, "doctor_note"])
      |> Enum.into(%{
        description: "some description",
        findings: "some findings",
        has_paid: true,
        payment_type: "some payment_type",
        urgency: "some urgency",
        radiology_report: "some radiology_report",
        report_complete: true,
        total_amount_paid: 42,
        patient_id: doctor_note.patient_id,
        doctor_id: doctor_note.doctor_id,
        doctor_note_id: doctor_note.id
      })
      |> Medcamp.RadiologyResults.create_radiology_result()

    radiology_result
  end
end
