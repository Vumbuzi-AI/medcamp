defmodule Medcamp.AdmissionRequestsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.AdmissionRequests` context.
  """

  @doc """
  Generate an admission_request.

  Requires `patient_id`, `doctor_id`, and `doctor_note_id` in attrs
  (e.g. from a test setup that creates those records).
  """
  def admission_request_fixture(attrs \\ %{}) do
    doctor_note =
      Map.get(attrs, :doctor_note) || Map.get(attrs, "doctor_note") ||
        Medcamp.DoctorNotesFixtures.doctor_note_fixture()

    {:ok, admission_request} =
      attrs
      |> Map.drop([:doctor_note, "doctor_note"])
      |> Enum.into(%{
        date: ~D[2025-04-12],
        has_paid: false,
        fully_paid: false,
        payment_type: nil,
        total_amount_paid: nil,
        patient_id: doctor_note.patient_id,
        doctor_id: doctor_note.doctor_id,
        doctor_note_id: doctor_note.id
      })
      |> Medcamp.AdmissionRequests.create_admission_request()

    admission_request
  end
end
