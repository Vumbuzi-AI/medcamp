defmodule Medcamp.ReferralsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.Referrals` context.
  """

  @doc """
  Generate a referral.
  """
  def referral_fixture(attrs \\ %{}) do
    doctor_note =
      Map.get(attrs, :doctor_note) || Map.get(attrs, "doctor_note") ||
        Medcamp.DoctorNotesFixtures.doctor_note_fixture()

    {:ok, referral} =
      attrs
      |> Map.drop([:doctor_note, "doctor_note"])
      |> Enum.into(%{
        date: ~D[2025-04-12],
        hospital: "some hospital",
        referral_note: "some referral_note",
        time: ~T[14:00:00],
        patient_id: doctor_note.patient_id,
        doctor_id: doctor_note.doctor_id,
        doctor_note_id: doctor_note.id
      })
      |> Medcamp.Referrals.create_referral()

    referral
  end
end
