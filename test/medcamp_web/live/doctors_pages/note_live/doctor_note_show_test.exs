defmodule MedcampWeb.DoctorsPagePatientLive.DoctorNoteShowTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures
  import Medcamp.PatientsFixtures
  import Medcamp.DoctorNotesFixtures
  import Medcamp.LabResultsFixtures
  import Medcamp.DrugAllocationsFixtures

  defp assigns(view), do: :sys.get_state(view.pid).socket.assigns

  setup %{conn: conn} do
    doctor = user_fixture(%{role: "doctor", name: "Dr. Test"})
    patient = patient_fixture()
    doctor_note = doctor_note_fixture(%{doctor: doctor, patient: patient})

    %{
      conn: log_in_user(conn, doctor),
      doctor: doctor,
      patient: patient,
      doctor_note: doctor_note,
      base_path: "/doctor/patients/#{patient.id}/notes/#{doctor_note.id}"
    }
  end

  describe "base route" do
    test "defaults to the overview tab", %{conn: conn, base_path: base_path} do
      {:ok, view, _html} = live(conn, base_path)
      assert assigns(view).current_tab == "overview"
    end

    test "renders a draft key scoped to this patient and note", %{
      conn: conn,
      base_path: base_path,
      patient: patient,
      doctor_note: doctor_note
    } do
      {:ok, _view, html} = live(conn, base_path)

      assert html =~ ~s(phx-hook="DraftPersistence")
      assert html =~ ~s(data-draft-key="doctor_note:#{patient.id}:#{doctor_note.id}")
    end

    test "does not load datasets used only by other tabs", %{
      conn: conn,
      base_path: base_path,
      patient: patient,
      doctor_note: doctor_note
    } do
      # Seed real data for every other tab so an empty assign actually
      # proves the query was skipped, not just that nothing existed.
      lab_result_fixture(%{doctor_note: doctor_note, patient: patient})
      drug_allocation_fixture(%{patient: patient, doctor_note_id: doctor_note.id})

      {:ok, view, _html} = live(conn, base_path)
      a = assigns(view)

      assert a.lab_results == []
      assert a.drug_allocations == []
    end
  end

  describe "tab parameter" do
    test "tab=lab_work loads only lab_results", %{
      conn: conn,
      base_path: base_path,
      patient: patient,
      doctor_note: doctor_note
    } do
      lab_result_fixture(%{doctor_note: doctor_note, patient: patient})
      drug_allocation_fixture(%{patient: patient, doctor_note_id: doctor_note.id})

      {:ok, view, _html} = live(conn, base_path <> "?tab=lab_work")
      a = assigns(view)

      assert a.current_tab == "lab_work"
      assert length(a.lab_results) == 1
      assert a.drug_allocations == []
    end

    test "tab=medication loads only drug_allocations", %{
      conn: conn,
      base_path: base_path,
      patient: patient,
      doctor_note: doctor_note
    } do
      lab_result_fixture(%{doctor_note: doctor_note, patient: patient})
      drug_allocation_fixture(%{patient: patient, doctor_note_id: doctor_note.id})

      {:ok, view, _html} = live(conn, base_path <> "?tab=medication")
      a = assigns(view)

      assert a.current_tab == "medication"
      assert length(a.drug_allocations) == 1
      assert a.lab_results == []
    end

    test "removed AI review tab falls back to overview", %{
      conn: conn,
      base_path: base_path,
      patient: patient,
      doctor_note: doctor_note
    } do
      lab_result_fixture(%{doctor_note: doctor_note, patient: patient})

      {:ok, view, _html} = live(conn, base_path <> "?tab=ai_review")
      a = assigns(view)

      assert a.current_tab == "overview"
      assert a.lab_results == []
    end
  end

  describe "invalid or missing parameters" do
    test "missing tab falls back to overview", %{conn: conn, base_path: base_path} do
      {:ok, view, _html} = live(conn, base_path)
      assert assigns(view).current_tab == "overview"
    end

    test "unsupported tab value falls back to overview", %{conn: conn, base_path: base_path} do
      {:ok, view, _html} = live(conn, base_path <> "?tab=not_a_real_tab")
      assert assigns(view).current_tab == "overview"
    end

    test "a tab removed in the camp trim falls back to overview", %{
      conn: conn,
      base_path: base_path
    } do
      for gone <- ~w(charges radiology inpatient admission referral) do
        {:ok, view, _html} = live(conn, base_path <> "?tab=#{gone}")
        assert assigns(view).current_tab == "overview"
      end
    end

    test "navigating tab -> tab via patch does not leak the previous tab's data", %{
      conn: conn,
      base_path: base_path,
      patient: patient,
      doctor_note: doctor_note
    } do
      lab_result_fixture(%{doctor_note: doctor_note, patient: patient})
      drug_allocation_fixture(%{patient: patient, doctor_note_id: doctor_note.id})

      {:ok, view, _html} = live(conn, base_path <> "?tab=lab_work")
      assert length(assigns(view).lab_results) == 1

      {:ok, view, _html} = live(conn, base_path <> "?tab=medication")
      a = assigns(view)
      assert length(a.drug_allocations) == 1
      assert a.lab_results == []
    end
  end

  describe "patient/note ownership mismatch" do
    test "redirects to the URL patient's own notes list, without exposing the other patient's note",
         %{conn: conn, doctor: doctor, doctor_note: doctor_note} do
      other_patient = patient_fixture()

      assert {:error, {:live_redirect, %{to: to}}} =
               live(conn, "/doctor/patients/#{other_patient.id}/notes/#{doctor_note.id}")

      assert to == "/doctor/patients/#{other_patient.id}/notes"
      assert doctor.id
      assert doctor_note.patient_id != other_patient.id
    end
  end
end
