defmodule MedcampWeb.NursesPages.PatientIndexTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures

  alias Medcamp.PatientVisits.PatientVisit
  alias Medcamp.Patients.Patient
  alias Medcamp.Repo

  setup %{conn: conn} do
    nurse = user_fixture(%{role: "nurse"})
    %{conn: log_in_user(conn, nurse), nurse: nurse}
  end

  test "nurse can add a patient and automatically open their triage visit", %{
    conn: conn,
    nurse: nurse
  } do
    {:ok, index_view, _html} = live(conn, ~p"/nurse/patients")
    assert has_element?(index_view, ~s(a[href="/nurse/patients/new"]), "Add Patient")

    {:ok, form_view, _html} = live(conn, ~p"/nurse/patients/new")
    refute has_element?(form_view, ~s(input[name="patient[birth_certificate_number]"]))
    refute has_element?(form_view, ~s(input[name="patient[has_insurance]"]))
    refute has_element?(form_view, ~s(input[name="patient[consent_agreement]"]))

    form_view
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
    assert_redirect(form_view, ~p"/nurse/#{patient.id}/patient_overview")
    assert patient.creator_id == nurse.id

    visit = Repo.get_by!(PatientVisit, patient_id: patient.id)
    assert visit.creator_id == nurse.id
    assert visit.status == "triage_pending"
    assert visit.date == Date.utc_today()
  end
end
