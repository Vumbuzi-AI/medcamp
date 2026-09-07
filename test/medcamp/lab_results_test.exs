defmodule Medcamp.LabResultsTest do
  use Medcamp.DataCase

  alias Medcamp.LabResults

  describe "lab_results" do
    alias Medcamp.LabResults.LabResult

    import Medcamp.LabResultsFixtures

    @invalid_attrs %{
      name: nil,
      date_of_test: nil,
      urgency: nil,
      lab_report: nil,
      test_findings: nil,
      sample_collection_date: nil,
      sample_collection_description: nil,
      technician_name: nil,
      report_complete: nil
    }

    test "list_lab_results/0 returns all lab_results" do
      lab_result = lab_result_fixture()
      assert [%LabResult{id: id}] = LabResults.list_lab_results()
      assert id == lab_result.id
    end

    test "get_lab_result!/1 returns the lab_result with given id" do
      lab_result = lab_result_fixture()
      assert LabResults.get_lab_result!(lab_result.id).id == lab_result.id
    end

    test "create_lab_result/1 with valid data creates a lab_result" do
      doctor = Medcamp.AccountsFixtures.user_fixture()
      patient = Medcamp.PatientsFixtures.patient_fixture()

      doctor_note =
        Medcamp.DoctorNotesFixtures.doctor_note_fixture(doctor: doctor, patient: patient)

      valid_attrs = %{
        name: "some name",
        date_of_test: ~D[2025-02-21],
        doctor_id: doctor.id,
        doctor_note_id: doctor_note.id,
        urgency: "some urgency",
        lab_report: "some lab_report",
        patient_id: patient.id,
        test_findings: "some test_findings",
        sample_collection_date: ~D[2025-02-21],
        sample_collection_description: "some sample_collection_description",
        technician_name: "some technician_name",
        report_complete: true
      }

      assert {:ok, %LabResult{} = lab_result} = LabResults.create_lab_result(valid_attrs)
      assert lab_result.name == "some name"
      assert lab_result.date_of_test == ~D[2025-02-21]
      assert lab_result.doctor_id == doctor.id
      assert lab_result.doctor_note_id == doctor_note.id
      assert lab_result.patient_id == patient.id
      assert lab_result.urgency == "some urgency"
      assert lab_result.lab_report == "some lab_report"
      assert lab_result.test_findings == "some test_findings"
      assert lab_result.sample_collection_date == ~D[2025-02-21]
      assert lab_result.sample_collection_description == "some sample_collection_description"
      assert lab_result.technician_name == "some technician_name"
      assert lab_result.report_complete == true
      assert lab_result.interpretation_payload == %{}
      assert lab_result.interpretation_status == "pending"
      assert is_nil(lab_result.interpretation_generated_at)
    end

    test "create_lab_result/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = LabResults.create_lab_result(@invalid_attrs)
    end

    test "update_lab_result/2 with valid data updates the lab_result" do
      lab_result = lab_result_fixture()

      update_attrs = %{
        name: "some updated name",
        date_of_test: ~D[2025-02-22],
        urgency: "some updated urgency",
        lab_report: "some updated lab_report",
        test_findings: "some updated test_findings",
        sample_collection_date: ~D[2025-02-22],
        sample_collection_description: "some updated sample_collection_description",
        technician_name: "some updated technician_name",
        report_complete: false
      }

      assert {:ok, %LabResult{} = lab_result} =
               LabResults.update_lab_result(lab_result, update_attrs)

      assert lab_result.name == "some updated name"
      assert lab_result.date_of_test == ~D[2025-02-22]
      assert lab_result.urgency == "some updated urgency"
      assert lab_result.lab_report == "some updated lab_report"
      assert lab_result.test_findings == "some updated test_findings"
      assert lab_result.sample_collection_date == ~D[2025-02-22]

      assert lab_result.sample_collection_description ==
               "some updated sample_collection_description"

      assert lab_result.technician_name == "some updated technician_name"
      assert lab_result.report_complete == false
      assert lab_result.interpretation_payload == %{}
      assert lab_result.interpretation_status == "pending"
      assert is_nil(lab_result.interpretation_generated_at)
    end

    test "update_lab_result/2 with invalid data returns error changeset" do
      lab_result = lab_result_fixture()

      assert {:error, %Ecto.Changeset{}} =
               LabResults.update_lab_result(lab_result, @invalid_attrs)

      assert LabResults.get_lab_result!(lab_result.id).name == lab_result.name
    end

    test "delete_lab_result/1 deletes the lab_result" do
      lab_result = lab_result_fixture()
      assert {:ok, %LabResult{}} = LabResults.delete_lab_result(lab_result)
      assert_raise Ecto.NoResultsError, fn -> LabResults.get_lab_result!(lab_result.id) end
    end

    test "change_lab_result/1 returns a lab_result changeset" do
      lab_result = lab_result_fixture()
      assert %Ecto.Changeset{} = LabResults.change_lab_result(lab_result)
    end
  end
end
