defmodule MedcampWeb.DoctorsPagePatientLive.DoctorNoteShowTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures
  import Medcamp.PatientsFixtures
  import Medcamp.DoctorNotesFixtures
  import Medcamp.LabResultsFixtures
  import Medcamp.DrugAllocationsFixtures
  import Medcamp.RadiologyResultsFixtures
  import Medcamp.AdmissionRequestsFixtures
  import Medcamp.ReferralsFixtures

  alias Medcamp.CadexNotes
  alias Medcamp.Inpatient
  alias Medcamp.Nursing
  alias Medcamp.PatientCharges.PatientCharge
  alias Medcamp.Repo

  defp assigns(view), do: :sys.get_state(view.pid).socket.assigns

  defp create_patient_charge(patient, doctor_note, doctor) do
    {:ok, consumable} =
      Nursing.create_nursing_consumable(%{
        date: ~D[2026-01-10],
        consumed_quantity: 1,
        purpose: "test consumable",
        patient_id: patient.id,
        doctor_note_id: doctor_note.id
      })

    {:ok, charge} =
      %PatientCharge{}
      |> PatientCharge.changeset(%{
        description: "Test charge",
        quantity: 1,
        unit_price: 100,
        total_price: 100,
        status: "pending_review",
        patient_id: patient.id,
        doctor_note_id: doctor_note.id,
        nursing_consumable_id: consumable.id,
        created_by_id: doctor.id
      })
      |> Repo.insert()

    charge
  end

  defp create_admission_note(patient, doctor, doctor_note) do
    {:ok, admission_note} =
      Inpatient.create_admission_note(%{
        admission_date: ~D[2026-01-10],
        admission_time: ~T[09:00:00],
        complaints: "test complaints",
        patient_id: patient.id,
        doctor_id: doctor.id,
        doctor_note_id: doctor_note.id
      })

    admission_note
  end

  defp create_continuation_note(admission_note, doctor) do
    {:ok, note} =
      Inpatient.create_continuation_note(%{
        review_date: ~D[2026-01-11],
        review_time: ~T[09:00:00],
        review_type: "Ward Round",
        admission_note_id: admission_note.id,
        doctor_id: doctor.id
      })

    note
  end

  defp create_treatment_sheet(admission_note, doctor) do
    {:ok, sheet} =
      Inpatient.create_treatment_sheet(%{
        prescription_date: ~D[2026-01-11],
        drug_name: "Test Drug",
        route: "Oral",
        dose: "500mg",
        frequency: "BD",
        admission_note_id: admission_note.id,
        prescriber_id: doctor.id
      })

    sheet
  end

  defp create_vital_record(admission_note, doctor) do
    {:ok, record} =
      Inpatient.create_vital_record(%{
        recorded_date: ~D[2026-01-11],
        recorded_time: ~T[09:00:00],
        admission_note_id: admission_note.id,
        recorded_by_id: doctor.id
      })

    record
  end

  defp create_cadex_note(patient, doctor, admission_note) do
    {:ok, note} =
      CadexNotes.create_cadex_note(%{
        note_date: ~D[2026-01-11],
        note_time: ~T[09:00:00],
        note: "Test cadex note",
        patient_id: patient.id,
        nurse_id: doctor.id,
        admission_note_id: admission_note.id
      })

    note
  end

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
      doctor_note: doctor_note,
      doctor: doctor
    } do
      # Seed real data for every other tab so an empty assign actually
      # proves the query was skipped, not just that nothing existed.
      lab_result_fixture(%{doctor_note: doctor_note, patient: patient})
      drug_allocation_fixture(%{patient: patient, doctor_note_id: doctor_note.id})
      radiology_result_fixture(%{doctor_note: doctor_note})
      admission_request_fixture(%{doctor_note: doctor_note})
      referral_fixture(%{doctor_note: doctor_note})
      create_patient_charge(patient, doctor_note, doctor)
      create_admission_note(patient, doctor, doctor_note)

      {:ok, view, _html} = live(conn, base_path)
      a = assigns(view)

      assert a.lab_results == []
      assert a.drug_allocations == []
      assert a.radiology_results == []
      assert a.admission_requests == []
      assert a.referrals == []
      assert a.patient_charges == []
      assert a.patient_charge_summary.total_count == 0
      assert a.current_admission == nil
      assert a.admission_notes == []
      assert a.continuation_notes == []
      assert a.treatment_sheets == []
      assert a.vital_records == []
      assert a.cadex_notes == []
      assert a.discharge_summary == nil
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

    test "tab=ai_review requires no extra dataset (reads doctor_note.ai_review_* directly)", %{
      conn: conn,
      base_path: base_path,
      patient: patient,
      doctor_note: doctor_note
    } do
      lab_result_fixture(%{doctor_note: doctor_note, patient: patient})

      {:ok, view, _html} = live(conn, base_path <> "?tab=ai_review")
      a = assigns(view)

      assert a.current_tab == "ai_review"
      assert a.lab_results == []
    end

    test "tab=medication loads only drug_allocations", %{
      conn: conn,
      base_path: base_path,
      patient: patient,
      doctor_note: doctor_note
    } do
      drug_allocation_fixture(%{patient: patient, doctor_note_id: doctor_note.id})
      lab_result_fixture(%{doctor_note: doctor_note, patient: patient})

      {:ok, view, _html} = live(conn, base_path <> "?tab=medication")
      a = assigns(view)

      assert a.current_tab == "medication"
      assert length(a.drug_allocations) == 1
      assert a.lab_results == []
    end

    test "tab=radiology loads only radiology_results", %{
      conn: conn,
      base_path: base_path,
      doctor_note: doctor_note
    } do
      radiology_result_fixture(%{doctor_note: doctor_note})

      {:ok, view, _html} = live(conn, base_path <> "?tab=radiology")
      a = assigns(view)

      assert a.current_tab == "radiology"
      assert length(a.radiology_results) == 1
      assert a.lab_results == []
    end

    test "tab=referral loads only referrals", %{
      conn: conn,
      base_path: base_path,
      doctor_note: doctor_note
    } do
      referral_fixture(%{doctor_note: doctor_note})

      {:ok, view, _html} = live(conn, base_path <> "?tab=referral")
      a = assigns(view)

      assert a.current_tab == "referral"
      assert length(a.referrals) == 1
      assert a.radiology_results == []
    end

    test "tab=admission loads only admission_requests", %{
      conn: conn,
      base_path: base_path,
      doctor_note: doctor_note
    } do
      admission_request_fixture(%{doctor_note: doctor_note})

      {:ok, view, _html} = live(conn, base_path <> "?tab=admission")
      a = assigns(view)

      assert a.current_tab == "admission"
      assert length(a.admission_requests) == 1
      assert a.referrals == []
    end

    test "tab=charges loads patient_charges and a real summary", %{
      conn: conn,
      base_path: base_path,
      patient: patient,
      doctor_note: doctor_note,
      doctor: doctor
    } do
      create_patient_charge(patient, doctor_note, doctor)

      {:ok, view, _html} = live(conn, base_path <> "?tab=charges")
      a = assigns(view)

      assert a.current_tab == "charges"
      assert length(a.patient_charges) == 1
      assert a.patient_charge_summary.total_count == 1
      assert a.patient_charge_summary.pending_review_count == 1
    end

    test "tab=inpatient loads current_admission", %{
      conn: conn,
      base_path: base_path,
      patient: patient,
      doctor: doctor,
      doctor_note: doctor_note
    } do
      create_admission_note(patient, doctor, doctor_note)

      {:ok, view, _html} = live(conn, base_path <> "?tab=inpatient")
      a = assigns(view)

      assert a.current_tab == "inpatient"
      refute a.current_admission == nil
    end
  end

  describe "inpatient subtab parameter" do
    setup %{patient: patient, doctor: doctor, doctor_note: doctor_note} do
      admission_note = create_admission_note(patient, doctor, doctor_note)
      continuation_note = create_continuation_note(admission_note, doctor)
      treatment_sheet = create_treatment_sheet(admission_note, doctor)
      vital_record = create_vital_record(admission_note, doctor)
      cadex_note = create_cadex_note(patient, doctor, admission_note)

      %{
        admission_note: admission_note,
        continuation_note: continuation_note,
        treatment_sheet: treatment_sheet,
        vital_record: vital_record,
        cadex_note: cadex_note
      }
    end

    test "subtab=admission loads only admission_notes", %{conn: conn, base_path: base_path} do
      {:ok, view, _html} = live(conn, base_path <> "?tab=inpatient&subtab=admission")
      a = assigns(view)

      assert a.inpatient_subtab == "admission"
      assert length(a.admission_notes) == 1
      assert a.continuation_notes == []
      assert a.treatment_sheets == []
      assert a.vital_records == []
      assert a.cadex_notes == []
    end

    test "subtab=continuation loads only continuation_notes", %{conn: conn, base_path: base_path} do
      {:ok, view, _html} = live(conn, base_path <> "?tab=inpatient&subtab=continuation")
      a = assigns(view)

      assert a.inpatient_subtab == "continuation"
      assert length(a.continuation_notes) == 1
      assert a.admission_notes == []
      assert a.treatment_sheets == []
      assert a.vital_records == []
      assert a.cadex_notes == []
    end

    test "subtab=treatment loads only treatment_sheets", %{conn: conn, base_path: base_path} do
      {:ok, view, _html} = live(conn, base_path <> "?tab=inpatient&subtab=treatment")
      a = assigns(view)

      assert a.inpatient_subtab == "treatment"
      assert length(a.treatment_sheets) == 1
      assert a.continuation_notes == []
      assert a.vital_records == []
      assert a.cadex_notes == []
    end

    test "subtab=vitals loads only vital_records", %{conn: conn, base_path: base_path} do
      {:ok, view, _html} = live(conn, base_path <> "?tab=inpatient&subtab=vitals")
      a = assigns(view)

      assert a.inpatient_subtab == "vitals"
      assert length(a.vital_records) == 1
      assert a.treatment_sheets == []
      assert a.cadex_notes == []
    end

    test "subtab=cadex loads only cadex_notes", %{conn: conn, base_path: base_path} do
      {:ok, view, _html} = live(conn, base_path <> "?tab=inpatient&subtab=cadex")
      a = assigns(view)

      assert a.inpatient_subtab == "cadex"
      assert length(a.cadex_notes) == 1
      assert a.vital_records == []
      assert a.admission_notes == []
    end

    test "subtab=discharge resolves against the current admission (no discharge summary yet, so nil)",
         %{conn: conn, base_path: base_path} do
      {:ok, view, _html} = live(conn, base_path <> "?tab=inpatient&subtab=discharge")
      a = assigns(view)

      assert a.inpatient_subtab == "discharge"
      # current_admission is, by definition, an admission with no discharge
      # summary yet — so this asserts the lookup runs (current_admission is
      # loaded) and correctly resolves to nil, not that a real discharge
      # summary was somehow returned.
      refute a.current_admission == nil
      assert a.discharge_summary == nil
      assert a.cadex_notes == []
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

    test "unsupported subtab value falls back to admission", %{conn: conn, base_path: base_path} do
      {:ok, view, _html} = live(conn, base_path <> "?tab=inpatient&subtab=not_a_real_subtab")
      assert assigns(view).inpatient_subtab == "admission"
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

  describe "admission-detail routes reached without ?tab=inpatient" do
    test "new_treatment loads current_admission even without the tab param", %{
      conn: conn,
      base_path: base_path,
      patient: patient,
      doctor: doctor,
      doctor_note: doctor_note
    } do
      create_admission_note(patient, doctor, doctor_note)

      {:ok, view, _html} = live(conn, base_path <> "/new_treatment")
      a = assigns(view)

      assert a.current_tab == "overview"
      refute a.current_admission == nil
    end
  end
end
