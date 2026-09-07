defmodule Medcamp.PatientsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.Patients` context.
  """

  @doc """
  Generate a patient.
  """
  def patient_fixture(attrs \\ %{}) do
    creator =
      Map.get(attrs, :creator) || Map.get(attrs, "creator") ||
        Medcamp.AccountsFixtures.user_fixture()

    {:ok, patient} =
      attrs
      |> Map.drop([:creator, "creator"])
      |> Enum.into(%{
        "date_of_birth" => ~D[2025-02-21],
        "email" => "patient#{System.unique_integer()}@example.com",
        "emergency_contact_relationship" => "some emergency_contact_relationship",
        "first_name" => "Some",
        "last_name" => "Patient",
        "gender" => "some gender",
        "home_address" => "some home_address",
        "phone_number" => "0712345678",
        "creator_id" => creator.id
      })
      |> Medcamp.Patients.create_patient()

    patient
  end
end
