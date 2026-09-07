defmodule Medcamp.NurseNotesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medcamp.NurseNotes` context.
  """

  @doc """
  Generate a nurse_note.
  """
  def nurse_note_fixture(attrs \\ %{}) do
    patient =
      Map.get(attrs, :patient) || Map.get(attrs, "patient") ||
        Medcamp.PatientsFixtures.patient_fixture()

    nurse =
      Map.get(attrs, :nurse) || Map.get(attrs, "nurse") || Medcamp.AccountsFixtures.user_fixture()

    {:ok, nurse_note} =
      attrs
      |> Map.drop([:patient, "patient", :nurse, "nurse"])
      |> Enum.into(%{
        content: "some content",
        patient_id: patient.id,
        nurse_id: nurse.id
      })
      |> Medcamp.NurseNotes.create_nurse_note()

    nurse_note
  end
end
