defmodule Medcamp.AdmissionRequestsTest do
  use Medcamp.DataCase

  alias Medcamp.AdmissionRequests

  describe "admission_requests" do
    alias Medcamp.AdmissionRequests.AdmissionRequest

    import Medcamp.AdmissionRequestsFixtures
    import Medcamp.PatientsFixtures
    import Medcamp.AccountsFixtures
    import Medcamp.DoctorNotesFixtures

    @invalid_attrs %{date: nil, payment_type: nil, total_amount_paid: nil, has_paid: nil}

    setup do
      patient = patient_fixture()
      user = user_fixture()

      note =
        doctor_note_fixture(%{
          patient_id: patient.id,
          doctor_id: user.id,
          date: ~D[2025-02-21],
          symptoms: "symptoms",
          time: ~T[12:00:00]
        })

      %{patient: patient, user: user, doctor_note: note}
    end

    test "list_admission_requests/0 returns all admission_requests", %{
      patient: patient,
      user: user,
      doctor_note: note
    } do
      admission_request =
        admission_request_fixture(%{
          patient_id: patient.id,
          doctor_id: user.id,
          doctor_note_id: note.id
        })

      assert AdmissionRequests.list_admission_requests() == [admission_request]
    end

    test "get_admission_request!/1 returns the admission_request with given id", %{
      patient: patient,
      user: user,
      doctor_note: note
    } do
      admission_request =
        admission_request_fixture(%{
          patient_id: patient.id,
          doctor_id: user.id,
          doctor_note_id: note.id
        })

      assert AdmissionRequests.get_admission_request!(admission_request.id) == admission_request
    end

    test "create_admission_request/1 with valid data creates a admission_request", %{
      patient: patient,
      user: user,
      doctor_note: note
    } do
      valid_attrs = %{
        date: ~D[2025-04-12],
        payment_type: "Mpesa",
        total_amount_paid: 42,
        has_paid: true,
        patient_id: patient.id,
        doctor_id: user.id,
        doctor_note_id: note.id
      }

      assert {:ok, %AdmissionRequest{} = admission_request} =
               AdmissionRequests.create_admission_request(valid_attrs)

      assert admission_request.date == ~D[2025-04-12]
      assert admission_request.payment_type == "Mpesa"
      assert admission_request.total_amount_paid == 42
      assert admission_request.has_paid == true
    end

    test "create_admission_request/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} =
               AdmissionRequests.create_admission_request(@invalid_attrs)
    end

    test "update_admission_request/2 with valid data updates the admission_request", %{
      patient: patient,
      user: user,
      doctor_note: note
    } do
      admission_request =
        admission_request_fixture(%{
          patient_id: patient.id,
          doctor_id: user.id,
          doctor_note_id: note.id
        })

      update_attrs = %{
        date: ~D[2025-04-13],
        payment_type: "Insurance",
        total_amount_paid: 43,
        has_paid: false
      }

      assert {:ok, %AdmissionRequest{} = admission_request} =
               AdmissionRequests.update_admission_request(admission_request, update_attrs)

      assert admission_request.date == ~D[2025-04-13]
      assert admission_request.payment_type == "Insurance"
      assert admission_request.total_amount_paid == 43
      assert admission_request.has_paid == false
    end

    test "update_admission_request/2 with invalid data returns error changeset", %{
      patient: patient,
      user: user,
      doctor_note: note
    } do
      admission_request =
        admission_request_fixture(%{
          patient_id: patient.id,
          doctor_id: user.id,
          doctor_note_id: note.id
        })

      assert {:error, %Ecto.Changeset{}} =
               AdmissionRequests.update_admission_request(admission_request, @invalid_attrs)

      assert admission_request == AdmissionRequests.get_admission_request!(admission_request.id)
    end

    test "delete_admission_request/1 deletes the admission_request", %{
      patient: patient,
      user: user,
      doctor_note: note
    } do
      admission_request =
        admission_request_fixture(%{
          patient_id: patient.id,
          doctor_id: user.id,
          doctor_note_id: note.id
        })

      assert {:ok, %AdmissionRequest{}} =
               AdmissionRequests.delete_admission_request(admission_request)

      assert_raise Ecto.NoResultsError, fn ->
        AdmissionRequests.get_admission_request!(admission_request.id)
      end
    end

    test "change_admission_request/1 returns a admission_request changeset", %{
      patient: patient,
      user: user,
      doctor_note: note
    } do
      admission_request =
        admission_request_fixture(%{
          patient_id: patient.id,
          doctor_id: user.id,
          doctor_note_id: note.id
        })

      assert %Ecto.Changeset{} = AdmissionRequests.change_admission_request(admission_request)
    end
  end
end
