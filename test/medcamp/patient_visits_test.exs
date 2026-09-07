defmodule Medcamp.PatientVisitsTest do
  use Medcamp.DataCase

  alias Medcamp.PatientVisits
  alias Medcamp.PatientVisits.PatientVisit

  import Medcamp.PatientVisitsFixtures
  import Medcamp.PatientsFixtures
  import Medcamp.AccountsFixtures

  describe "patient_visits" do
    @invalid_attrs %{
      reason: nil,
      date: nil,
      patient_id: nil,
      creator_id: nil,
      payment_type: nil,
      has_paid: nil
    }

    test "list_patient_visits/0 returns all patient_visits" do
      patient_visit = patient_visit_fixture()
      assert Enum.map(PatientVisits.list_patient_visits(), & &1.id) == [patient_visit.id]
    end

    test "get_patient_visit!/1 returns the patient_visit with given id" do
      patient_visit = patient_visit_fixture()
      assert PatientVisits.get_patient_visit!(patient_visit.id).id == patient_visit.id
    end

    test "create_patient_visit/1 with valid data creates a patient_visit" do
      patient = patient_fixture()
      creator = user_fixture()

      valid_attrs = %{
        reason: "some reason",
        date: ~D[2025-02-24],
        patient_id: patient.id,
        creator_id: creator.id,
        payment_type: "some payment_type",
        has_paid: true
      }

      assert {:ok, %PatientVisit{} = patient_visit} =
               PatientVisits.create_patient_visit(valid_attrs)

      assert patient_visit.reason == "some reason"
      assert patient_visit.date == ~D[2025-02-24]
    end

    test "create_patient_visit/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = PatientVisits.create_patient_visit(@invalid_attrs)
    end

    test "update_patient_visit/2 with valid data updates the patient_visit" do
      patient_visit = patient_visit_fixture()
      update_attrs = %{reason: "some updated reason", date: ~D[2025-02-25]}

      assert {:ok, %PatientVisit{} = patient_visit} =
               PatientVisits.update_patient_visit(patient_visit, update_attrs)

      assert patient_visit.reason == "some updated reason"
      assert patient_visit.date == ~D[2025-02-25]
    end

    test "update_patient_visit/2 with invalid data returns error changeset" do
      patient_visit = patient_visit_fixture()

      assert {:error, %Ecto.Changeset{}} =
               PatientVisits.update_patient_visit(patient_visit, @invalid_attrs)

      assert patient_visit.id == PatientVisits.get_patient_visit!(patient_visit.id).id
    end

    test "delete_patient_visit/1 deletes the patient_visit" do
      patient_visit = patient_visit_fixture()
      assert {:ok, %PatientVisit{}} = PatientVisits.delete_patient_visit(patient_visit)

      assert_raise Ecto.NoResultsError, fn ->
        PatientVisits.get_patient_visit!(patient_visit.id)
      end
    end

    test "change_patient_visit/1 returns a patient_visit changeset" do
      patient_visit = patient_visit_fixture()
      assert %Ecto.Changeset{} = PatientVisits.change_patient_visit(patient_visit)
    end

    test "filter_patient_visits/1 with creator_id only returns visits created by that user" do
      creator_a = user_fixture()
      creator_b = user_fixture()
      visit_a = patient_visit_fixture(%{creator: creator_a})
      _visit_b = patient_visit_fixture(%{creator: creator_b})

      result = PatientVisits.filter_patient_visits(%{creator_id: creator_a.id})

      assert Enum.map(result, & &1.id) == [visit_a.id]
    end

    test "filter_patient_visits/1 with creator_id as a string filters the same way" do
      creator_a = user_fixture()
      creator_b = user_fixture()
      visit_a = patient_visit_fixture(%{creator: creator_a})
      _visit_b = patient_visit_fixture(%{creator: creator_b})

      result = PatientVisits.filter_patient_visits(%{creator_id: Integer.to_string(creator_a.id)})

      assert Enum.map(result, & &1.id) == [visit_a.id]
    end
  end

  describe "count_repeat_patients/0" do
    test "returns 0 when there are no visits" do
      assert PatientVisits.count_repeat_patients() == 0
    end

    test "does not count a patient with exactly one paid visit" do
      patient = patient_fixture()
      patient_visit_fixture(%{patient: patient, has_paid: true})

      assert PatientVisits.count_repeat_patients() == 0
    end

    test "does not count a patient with multiple visits if fewer than 2 are paid" do
      patient = patient_fixture()
      patient_visit_fixture(%{patient: patient, has_paid: true})
      patient_visit_fixture(%{patient: patient, has_paid: false})
      patient_visit_fixture(%{patient: patient, has_paid: false})

      assert PatientVisits.count_repeat_patients() == 0
    end

    test "counts a patient with 2+ paid visits exactly once" do
      patient = patient_fixture()
      patient_visit_fixture(%{patient: patient, has_paid: true})
      patient_visit_fixture(%{patient: patient, has_paid: true})
      patient_visit_fixture(%{patient: patient, has_paid: true})

      assert PatientVisits.count_repeat_patients() == 1
    end

    test "counts multiple distinct repeat patients" do
      patient_a = patient_fixture()
      patient_b = patient_fixture()
      patient_visit_fixture(%{patient: patient_a, has_paid: true})
      patient_visit_fixture(%{patient: patient_a, has_paid: true})
      patient_visit_fixture(%{patient: patient_b, has_paid: true})
      patient_visit_fixture(%{patient: patient_b, has_paid: true})

      # a third, non-repeat patient shouldn't affect the count
      patient_c = patient_fixture()
      patient_visit_fixture(%{patient: patient_c, has_paid: true})

      assert PatientVisits.count_repeat_patients() == 2
    end
  end
end
