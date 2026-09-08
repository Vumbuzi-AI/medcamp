defmodule MedcampWeb.ReceptionistPatientLive.NewTest do
  use MedcampWeb.ConnCase, async: true

  import Medcamp.AccountsFixtures
  import Phoenix.LiveViewTest

  alias Medcamp.PatientVisits.PatientVisit
  alias Medcamp.Patients.Patient
  alias Medcamp.Repo

  setup %{conn: conn} do
    receptionist = user_fixture(%{role: "receptionist"})
    %{conn: log_in_user(conn, receptionist), receptionist: receptionist}
  end

  test "shows the patient list with registration as the only action", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/receptionist/patients")

    assert html =~ "All patients"
    assert has_element?(view, ~s(a[href="/receptionist/patients/new"]), "Add Patient")
    refute has_element?(view, "#patient-form")
    refute html =~ "Visits"
    refute html =~ "Triage"
    refute html =~ "Edit"
  end

  test "adding a patient also creates a triage visit", %{
    conn: conn,
    receptionist: receptionist
  } do
    {:ok, view, _html} = live(conn, ~p"/receptionist/patients/new")

    view
    |> form("#patient-form",
      patient: %{
        first_name: "Amina",
        last_name: "Wanjiru",
        phone_number: "0712345678",
        date_of_birth: "1990-04-11",
        gender: "Female",
        home_address: "Kibera"
      }
    )
    |> render_submit()

    patient = Repo.get_by!(Patient, first_name: "Amina", last_name: "Wanjiru")
    assert patient.creator_id == receptionist.id

    visit = Repo.get_by!(PatientVisit, patient_id: patient.id)
    assert visit.creator_id == receptionist.id
    assert visit.status == "triage_pending"
    assert_redirect(view, ~p"/receptionist/patients")
  end

  test "receptionists cannot enter the nurse workflow", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/receptionist/patients"}}} =
             live(conn, ~p"/nurse/patients")
  end

  test "other staff cannot enter the receptionist workflow", %{conn: conn} do
    nurse = user_fixture(%{role: "nurse"})
    nurse_conn = log_in_user(conn, nurse)

    assert {:error, {:redirect, %{to: "/nurse/scan"}}} =
             live(nurse_conn, ~p"/receptionist/patients/new")
  end
end
