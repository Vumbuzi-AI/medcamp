defmodule Medcamp.RadiologyResultsTest do
  use Medcamp.DataCase

  alias Medcamp.RadiologyResults

  describe "radiology_results" do
    alias Medcamp.RadiologyResults.RadiologyResult

    import Medcamp.RadiologyResultsFixtures
    import Medcamp.DoctorNotesFixtures

    @invalid_attrs %{
      description: nil,
      payment_type: nil,
      urgency: nil,
      total_amount_paid: nil,
      has_paid: nil,
      findings: nil,
      radiology_report: nil,
      report_complete: nil
    }

    test "list_radiology_results/0 returns all radiology_results" do
      radiology_result = radiology_result_fixture()
      assert [%RadiologyResult{id: id}] = RadiologyResults.list_radiology_results()
      assert id == radiology_result.id
    end

    test "get_radiology_result!/1 returns the radiology_result with given id" do
      radiology_result = radiology_result_fixture()
      assert RadiologyResults.get_radiology_result!(radiology_result.id).id == radiology_result.id
    end

    test "create_radiology_result/1 with valid data creates a radiology_result" do
      doctor_note = doctor_note_fixture()

      valid_attrs = %{
        description: "some description",
        payment_type: "some payment_type",
        urgency: "some urgency",
        total_amount_paid: 42,
        has_paid: true,
        findings: "some findings",
        radiology_report: "some radiology_report",
        report_complete: true,
        patient_id: doctor_note.patient_id,
        doctor_id: doctor_note.doctor_id,
        doctor_note_id: doctor_note.id
      }

      assert {:ok, %RadiologyResult{} = radiology_result} =
               RadiologyResults.create_radiology_result(valid_attrs)

      assert radiology_result.description == "some description"
      assert radiology_result.payment_type == "some payment_type"
      assert radiology_result.urgency == "some urgency"
      assert radiology_result.total_amount_paid == 42
      assert radiology_result.has_paid == true
      assert radiology_result.findings == "some findings"
      assert radiology_result.radiology_report == "some radiology_report"
      assert radiology_result.report_complete == true
      assert radiology_result.patient_id == doctor_note.patient_id
      assert radiology_result.doctor_id == doctor_note.doctor_id
      assert radiology_result.doctor_note_id == doctor_note.id
    end

    test "create_radiology_result/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               RadiologyResults.create_radiology_result(@invalid_attrs)
    end

    test "update_radiology_result/2 with valid data updates the radiology_result" do
      radiology_result = radiology_result_fixture()

      update_attrs = %{
        description: "some updated description",
        payment_type: "some updated payment_type",
        total_amount_paid: 43,
        has_paid: false,
        findings: "some updated findings",
        radiology_report: "some updated radiology_report",
        report_complete: false
      }

      assert {:ok, %RadiologyResult{} = radiology_result} =
               RadiologyResults.update_radiology_result(radiology_result, update_attrs)

      assert radiology_result.description == "some updated description"
      assert radiology_result.payment_type == "some updated payment_type"
      assert radiology_result.total_amount_paid == 43
      assert radiology_result.has_paid == false
      assert radiology_result.findings == "some updated findings"
      assert radiology_result.radiology_report == "some updated radiology_report"
      assert radiology_result.report_complete == false
    end

    test "update_radiology_result/2 with invalid data returns error changeset" do
      radiology_result = radiology_result_fixture()

      assert {:error, %Ecto.Changeset{}} =
               RadiologyResults.update_radiology_result(radiology_result, @invalid_attrs)

      assert radiology_result.id ==
               RadiologyResults.get_radiology_result!(radiology_result.id).id
    end

    test "delete_radiology_result/1 deletes the radiology_result" do
      radiology_result = radiology_result_fixture()

      assert {:ok, %RadiologyResult{}} =
               RadiologyResults.delete_radiology_result(radiology_result)

      assert_raise Ecto.NoResultsError, fn ->
        RadiologyResults.get_radiology_result!(radiology_result.id)
      end
    end

    test "change_radiology_result/1 returns a radiology_result changeset" do
      radiology_result = radiology_result_fixture()
      assert %Ecto.Changeset{} = RadiologyResults.change_radiology_result(radiology_result)
    end
  end
end
