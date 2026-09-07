defmodule Medcamp.DoctorNotesTest do
  use Medcamp.DataCase

  alias Medcamp.DoctorNotes

  describe "doctor_notes" do
    alias Medcamp.DoctorNotes.DoctorNote

    import Medcamp.DoctorNotesFixtures
    import Medcamp.AccountsFixtures
    import Medcamp.PatientsFixtures

    @invalid_attrs %{
      date: nil,
      reason_for_consulatation: nil,
      symptoms: nil,
      prescribed_medication: nil,
      lifestyle_recommendations: nil,
      lab_imaging_request: nil
    }

    test "list_doctor_notes/0 returns all doctor_notes" do
      doctor_note = doctor_note_fixture()
      assert DoctorNotes.list_doctor_notes() == [Medcamp.Repo.preload(doctor_note, :doctor)]
    end

    test "get_doctor_note!/1 returns the doctor_note with given id" do
      doctor_note = doctor_note_fixture()

      assert DoctorNotes.get_doctor_note!(doctor_note.id) ==
               Medcamp.Repo.preload(doctor_note, [:doctor, child_notes: [:doctor]])
    end

    test "create_doctor_note/1 with valid data creates a doctor_note" do
      doctor = user_fixture()
      patient = patient_fixture()

      valid_attrs = %{
        date: ~D[2025-02-21],
        time: ~T[16:55:33],
        doctor_id: doctor.id,
        patient_id: patient.id,
        reason_for_consulatation: "some reason_for_consulatation",
        symptoms: "some symptoms",
        prescribed_medication: "some prescribed_medication",
        lifestyle_recommendations: "some lifestyle_recommendations",
        lab_imaging_request: "some lab_imaging_request"
      }

      assert {:ok, %DoctorNote{} = doctor_note} = DoctorNotes.create_doctor_note(valid_attrs)
      assert doctor_note.date == ~D[2025-02-21]
      assert doctor_note.reason_for_consulatation == "some reason_for_consulatation"
      assert doctor_note.symptoms == "some symptoms"
      assert doctor_note.prescribed_medication == "some prescribed_medication"
      assert doctor_note.lifestyle_recommendations == "some lifestyle_recommendations"
      assert doctor_note.lab_imaging_request == "some lab_imaging_request"
    end

    test "create_doctor_note/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = DoctorNotes.create_doctor_note(@invalid_attrs)
    end

    test "create_doctor_note/1 without a signature leaves doctor_signature and signed_at unset" do
      doctor = user_fixture()
      patient = patient_fixture()

      valid_attrs = %{
        date: ~D[2025-02-21],
        time: ~T[16:55:33],
        doctor_id: doctor.id,
        patient_id: patient.id,
        symptoms: "some symptoms"
      }

      assert {:ok, %DoctorNote{} = doctor_note} = DoctorNotes.create_doctor_note(valid_attrs)
      assert doctor_note.doctor_signature == nil
      assert doctor_note.signed_at == nil
    end

    test "create_doctor_note/1 with a signature stamps signed_at automatically" do
      doctor = user_fixture()
      patient = patient_fixture()

      valid_attrs = %{
        date: ~D[2025-02-21],
        time: ~T[16:55:33],
        doctor_id: doctor.id,
        patient_id: patient.id,
        symptoms: "some symptoms",
        doctor_signature: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA"
      }

      assert {:ok, %DoctorNote{} = doctor_note} = DoctorNotes.create_doctor_note(valid_attrs)
      assert doctor_note.doctor_signature == valid_attrs.doctor_signature
      assert %DateTime{} = doctor_note.signed_at
    end

    test "update_doctor_note/2 re-stamps signed_at when the signature changes" do
      doctor_note = doctor_note_fixture()
      assert doctor_note.signed_at == nil

      assert {:ok, updated} =
               DoctorNotes.update_doctor_note(doctor_note, %{
                 doctor_signature: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA"
               })

      assert %DateTime{} = updated.signed_at
    end

    test "update_doctor_note/2 clears signed_at when doctor_signature is set to nil or empty string" do
      doctor_note =
        doctor_note_fixture(%{
          doctor_signature: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA"
        })

      assert %DateTime{} = doctor_note.signed_at

      assert {:ok, cleared_nil} =
               DoctorNotes.update_doctor_note(doctor_note, %{doctor_signature: nil})

      assert cleared_nil.doctor_signature == nil
      assert cleared_nil.signed_at == nil

      doctor_note_2 =
        doctor_note_fixture(%{
          doctor_signature: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA"
        })

      assert {:ok, cleared_empty} =
               DoctorNotes.update_doctor_note(doctor_note_2, %{doctor_signature: ""})

      assert cleared_empty.doctor_signature == nil
      assert cleared_empty.signed_at == nil
    end

    test "update_doctor_note/2 preserves existing signed_at when doctor_signature is unchanged" do
      doctor_note =
        doctor_note_fixture(%{
          doctor_signature: "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA"
        })

      original_signed_at = doctor_note.signed_at

      assert {:ok, updated} =
               DoctorNotes.update_doctor_note(doctor_note, %{
                 symptoms: "new symptoms"
               })

      assert updated.signed_at == original_signed_at
    end

    test "update_doctor_note/2 with valid data updates the doctor_note" do
      doctor_note = doctor_note_fixture()

      update_attrs = %{
        date: ~D[2025-02-22],
        reason_for_consulatation: "some updated reason_for_consulatation",
        symptoms: "some updated symptoms",
        prescribed_medication: "some updated prescribed_medication",
        lifestyle_recommendations: "some updated lifestyle_recommendations",
        lab_imaging_request: "some updated lab_imaging_request"
      }

      assert {:ok, %DoctorNote{} = doctor_note} =
               DoctorNotes.update_doctor_note(doctor_note, update_attrs)

      assert doctor_note.date == ~D[2025-02-22]
      assert doctor_note.reason_for_consulatation == "some updated reason_for_consulatation"
      assert doctor_note.symptoms == "some updated symptoms"
      assert doctor_note.prescribed_medication == "some updated prescribed_medication"
      assert doctor_note.lifestyle_recommendations == "some updated lifestyle_recommendations"
      assert doctor_note.lab_imaging_request == "some updated lab_imaging_request"
    end

    test "update_doctor_note/2 with invalid data returns error changeset" do
      doctor_note = doctor_note_fixture()

      assert {:error, %Ecto.Changeset{}} =
               DoctorNotes.update_doctor_note(doctor_note, @invalid_attrs)

      assert Medcamp.Repo.preload(doctor_note, [:doctor, child_notes: [:doctor]]) ==
               DoctorNotes.get_doctor_note!(doctor_note.id)
    end

    test "delete_doctor_note/1 deletes the doctor_note" do
      doctor_note = doctor_note_fixture()
      assert {:ok, %DoctorNote{}} = DoctorNotes.delete_doctor_note(doctor_note)
      assert_raise Ecto.NoResultsError, fn -> DoctorNotes.get_doctor_note!(doctor_note.id) end
    end

    test "change_doctor_note/1 returns a doctor_note changeset" do
      doctor_note = doctor_note_fixture()
      assert %Ecto.Changeset{} = DoctorNotes.change_doctor_note(doctor_note)
    end

    test "list_doctor_notes_for_doctor/1 returns only notes written by that doctor" do
      doctor_a = user_fixture()
      doctor_b = user_fixture()
      note_a = doctor_note_fixture(%{doctor: doctor_a})
      _note_b = doctor_note_fixture(%{doctor: doctor_b})

      result = DoctorNotes.list_doctor_notes_for_doctor(doctor_a.id)

      assert Enum.map(result, & &1.id) == [note_a.id]
    end
  end
end
