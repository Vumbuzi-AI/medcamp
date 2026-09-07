defmodule Medcamp.AllergyHistoriesTest do
  use Medcamp.DataCase

  alias Medcamp.AllergyHistories

  describe "allergy_histories" do
    alias Medcamp.AllergyHistories.AllergyHistory

    import Medcamp.AllergyHistoriesFixtures
    import Medcamp.PatientsFixtures
    import Medcamp.AccountsFixtures

    @invalid_attrs %{
      substance_name: nil,
      category: nil,
      type: nil,
      criticality: nil,
      patient_id: nil
    }

    test "list_allergy_histories_for_patient/1 returns only that patient's allergies, newest first" do
      patient = patient_fixture()
      other_patient = patient_fixture()

      older =
        allergy_history_fixture(%{patient: patient, substance_name: "Penicillin"})

      newer =
        allergy_history_fixture(%{patient: patient, substance_name: "Peanuts"})

      _other = allergy_history_fixture(%{patient: other_patient, substance_name: "Latex"})

      assert Enum.map(AllergyHistories.list_allergy_histories_for_patient(patient.id), & &1.id) ==
               [newer.id, older.id]
    end

    test "get_allergy_history!/1 returns the allergy history with given id" do
      allergy_history = allergy_history_fixture()
      assert AllergyHistories.get_allergy_history!(allergy_history.id).id == allergy_history.id
    end

    test "create_allergy_history/1 with valid data creates an allergy history" do
      patient = patient_fixture()
      recorder = user_fixture(%{role: "doctor"})

      valid_attrs = %{
        patient_id: patient.id,
        recorded_by_id: recorder.id,
        substance_name: "Penicillin",
        substance_code: "7980",
        substance_code_system: "http://snomed.info/sct",
        category: "medication",
        type: "allergy",
        clinical_status: "active",
        verification_status: "confirmed",
        criticality: "high",
        reaction_manifestation: "Hives",
        reaction_severity: "moderate",
        onset_date: ~D[2020-01-01],
        notes: "Reported by patient"
      }

      assert {:ok, %AllergyHistory{} = allergy_history} =
               AllergyHistories.create_allergy_history(valid_attrs)

      assert allergy_history.substance_name == "Penicillin"
      assert allergy_history.substance_code == "7980"
      assert allergy_history.category == "medication"
      assert allergy_history.type == "allergy"
      assert allergy_history.criticality == "high"
      assert allergy_history.reaction_manifestation == "Hives"
      assert allergy_history.reaction_severity == "moderate"
      assert allergy_history.recorded_by_id == recorder.id
    end

    test "create_allergy_history/1 defaults clinical_status to active and verification_status to unconfirmed" do
      patient = patient_fixture()

      valid_attrs = %{
        patient_id: patient.id,
        substance_name: "Peanuts",
        category: "food",
        type: "allergy",
        criticality: "low"
      }

      assert {:ok, %AllergyHistory{} = allergy_history} =
               AllergyHistories.create_allergy_history(valid_attrs)

      assert allergy_history.clinical_status == "active"
      assert allergy_history.verification_status == "unconfirmed"
    end

    test "create_allergy_history/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = AllergyHistories.create_allergy_history(@invalid_attrs)
    end

    test "create_allergy_history/1 rejects an unrecognized category" do
      patient = patient_fixture()

      attrs = %{
        patient_id: patient.id,
        substance_name: "Peanuts",
        category: "not-a-real-category",
        type: "allergy",
        criticality: "low"
      }

      assert {:error, changeset} = AllergyHistories.create_allergy_history(attrs)
      assert "is invalid" in errors_on(changeset).category
    end

    test "create_allergy_history/1 returns error changeset for non-existent recorded_by_id" do
      patient = patient_fixture()

      attrs = %{
        patient_id: patient.id,
        recorded_by_id: 999_999,
        substance_name: "Latex",
        category: "environment",
        type: "allergy",
        criticality: "high"
      }

      assert {:error, changeset} = AllergyHistories.create_allergy_history(attrs)
      assert "does not exist" in errors_on(changeset).recorded_by_id
    end

    test "update_allergy_history/2 with valid data updates the allergy history" do
      allergy_history = allergy_history_fixture()

      update_attrs = %{
        clinical_status: "resolved",
        verification_status: "confirmed",
        notes: "No longer reactive on re-challenge"
      }

      assert {:ok, %AllergyHistory{} = allergy_history} =
               AllergyHistories.update_allergy_history(allergy_history, update_attrs)

      assert allergy_history.clinical_status == "resolved"
      assert allergy_history.verification_status == "confirmed"
      assert allergy_history.notes == "No longer reactive on re-challenge"
    end

    test "update_allergy_history/2 with invalid data returns error changeset" do
      allergy_history = allergy_history_fixture()

      assert {:error, %Ecto.Changeset{}} =
               AllergyHistories.update_allergy_history(allergy_history, @invalid_attrs)

      assert AllergyHistories.get_allergy_history!(allergy_history.id).substance_name ==
               allergy_history.substance_name
    end

    test "delete_allergy_history/1 deletes the allergy history" do
      allergy_history = allergy_history_fixture()
      assert {:ok, %AllergyHistory{}} = AllergyHistories.delete_allergy_history(allergy_history)

      assert_raise Ecto.NoResultsError, fn ->
        AllergyHistories.get_allergy_history!(allergy_history.id)
      end
    end

    test "change_allergy_history/1 returns an allergy history changeset" do
      allergy_history = allergy_history_fixture()
      assert %Ecto.Changeset{} = AllergyHistories.change_allergy_history(allergy_history)
    end
  end
end
