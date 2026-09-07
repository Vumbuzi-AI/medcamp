defmodule Medcamp.NurseNotesTest do
  use Medcamp.DataCase

  alias Medcamp.NurseNotes

  describe "nurse_notes" do
    alias Medcamp.NurseNotes.NurseNote

    import Medcamp.NurseNotesFixtures
    import Medcamp.PatientsFixtures
    import Medcamp.AccountsFixtures

    @invalid_attrs %{content: nil, patient_id: nil, nurse_id: nil}

    test "list_nurse_notes/0 returns all nurse_notes" do
      nurse_note = nurse_note_fixture()
      assert Enum.map(NurseNotes.list_nurse_notes(), & &1.id) == [nurse_note.id]
    end

    test "get_nurse_note!/1 returns the nurse_note with given id" do
      nurse_note = nurse_note_fixture()
      assert NurseNotes.get_nurse_note!(nurse_note.id).id == nurse_note.id
    end

    test "create_nurse_note/1 with valid data creates a nurse_note" do
      patient = patient_fixture()
      nurse = user_fixture()

      valid_attrs = %{
        content: "some content",
        patient_id: patient.id,
        nurse_id: nurse.id
      }

      assert {:ok, %NurseNote{} = nurse_note} = NurseNotes.create_nurse_note(valid_attrs)
      assert nurse_note.content == "some content"
    end

    test "create_nurse_note/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = NurseNotes.create_nurse_note(@invalid_attrs)
    end

    test "update_nurse_note/2 with valid data updates the nurse_note" do
      nurse_note = nurse_note_fixture()
      update_attrs = %{content: "some updated content"}

      assert {:ok, %NurseNote{} = nurse_note} =
               NurseNotes.update_nurse_note(nurse_note, update_attrs)

      assert nurse_note.content == "some updated content"
    end

    test "update_nurse_note/2 with invalid data returns error changeset" do
      nurse_note = nurse_note_fixture()

      assert {:error, %Ecto.Changeset{}} =
               NurseNotes.update_nurse_note(nurse_note, @invalid_attrs)

      assert nurse_note.id == NurseNotes.get_nurse_note!(nurse_note.id).id
    end

    test "delete_nurse_note/1 deletes the nurse_note" do
      nurse_note = nurse_note_fixture()
      assert {:ok, %NurseNote{}} = NurseNotes.delete_nurse_note(nurse_note)
      assert_raise Ecto.NoResultsError, fn -> NurseNotes.get_nurse_note!(nurse_note.id) end
    end

    test "change_nurse_note/1 returns a nurse_note changeset" do
      nurse_note = nurse_note_fixture()
      assert %Ecto.Changeset{} = NurseNotes.change_nurse_note(nurse_note)
    end
  end
end
