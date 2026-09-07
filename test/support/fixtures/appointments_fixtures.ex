defmodule Medcamp.AppointmentsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.Appointments` context.
  """

  alias Medcamp.Patients.Patient
  alias Medcamp.Repo

  @doc """
  Generate a appointment.
  """
  def appointment_fixture(attrs \\ %{}) do
    patient = public_booking_patient_fixture()

    {:ok, appointment} =
      attrs
      |> Enum.into(%{
        date: ~D[2025-04-05],
        patient_id: patient.id,
        reason: "some reason",
        time: ~T[14:00:00]
      })
      |> Medcamp.Appointments.create_appointment()

    appointment
  end

  defp public_booking_patient_fixture do
    unique_integer = System.unique_integer([:positive])

    {:ok, patient} =
      %Patient{}
      |> Patient.public_booking_changeset(%{
        first_name: "Public",
        last_name: "Patient#{unique_integer}",
        email: "public#{unique_integer}@example.com",
        phone_number: "071#{String.pad_leading(Integer.to_string(unique_integer), 7, "0")}"
      })
      |> Repo.insert()

    patient
  end
end
