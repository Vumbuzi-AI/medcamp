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

  defp camp_fixture(user) do
    Medcamp.Tenancy.with_org(user.organisation_id, fn ->
      {:ok, camp} = Medcamp.Camps.create_camp(%{name: "Attendance Test Camp"})
      camp
    end)
  end

  test "defaults to this camp's roster and only widens to the org on search", %{
    conn: conn,
    receptionist: receptionist
  } do
    scope = fn f -> Medcamp.Tenancy.with_org(receptionist.organisation_id, f) end
    camp = camp_fixture(receptionist)

    {:ok, in_camp} =
      scope.(fn ->
        Medcamp.Patients.create_patient(%{
          "first_name" => "Incamp",
          "last_name" => "Patient",
          "phone_number" => "0700000001",
          "date_of_birth" => "1990-01-01",
          "gender" => "Female",
          "home_address" => "Nairobi",
          "creator_id" => receptionist.id
        })
      end)

    {:ok, _past} =
      scope.(fn ->
        Medcamp.Patients.create_patient(%{
          "first_name" => "Pastcamp",
          "last_name" => "Patient",
          "phone_number" => "0700000002",
          "date_of_birth" => "1990-01-01",
          "gender" => "Male",
          "home_address" => "Nairobi",
          "creator_id" => receptionist.id
        })
      end)

    scope.(fn -> Medcamp.CampAttendances.record(in_camp.id, camp.id) end)

    {:ok, view, html} = live(conn, ~p"/receptionist/patients")

    # Default view: only the patient attending the active camp.
    assert html =~ "Incamp Patient"
    refute html =~ "Pastcamp Patient"
    assert html =~ "Showing this camp only"

    # Searching reaches the whole organisation.
    html =
      view
      |> form("form[phx-change='search']", %{"search" => "Pastcamp"})
      |> render_change()

    assert html =~ "Pastcamp Patient"
  end

  test "shows the patient list with registration as the only action", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/receptionist/patients")

    assert html =~ "Patients"
    assert html =~ "triage queue"
    assert has_element?(view, ~s(a[href="/receptionist/patients/new"]), "Add Patient")
    assert has_element?(view, "input[name='search']")
    refute has_element?(view, "#patient-form")
    refute html =~ "Visits"
    refute html =~ "Triage queue"
    refute html =~ "Edit"
  end

  test "search narrows the patient list", %{conn: conn} do
    receptionist = user_fixture(%{role: "receptionist"})
    scope = fn f -> Medcamp.Tenancy.with_org(receptionist.organisation_id, f) end

    scope.(fn ->
      Medcamp.Patients.create_patient(%{
        "first_name" => "Findme",
        "last_name" => "Mwangi",
        "phone_number" => "0700111222",
        "date_of_birth" => "1990-01-01",
        "gender" => "Male",
        "home_address" => "Nairobi",
        "creator_id" => receptionist.id
      })

      Medcamp.Patients.create_patient(%{
        "first_name" => "Someone",
        "last_name" => "Else",
        "phone_number" => "0700333444",
        "date_of_birth" => "1990-01-01",
        "gender" => "Female",
        "home_address" => "Nairobi",
        "creator_id" => receptionist.id
      })
    end)

    conn = log_in_user(conn, receptionist)
    {:ok, view, _html} = live(conn, ~p"/receptionist/patients")

    html =
      view
      |> form("form[phx-change='search']", %{"search" => "Findme"})
      |> render_change()

    assert html =~ "Findme Mwangi"
    refute html =~ "Someone Else"
  end

  test "registration starts on a National ID lookup step", %{conn: conn} do
    {:ok, view, html} = live(conn, ~p"/receptionist/patients/new")

    assert html =~ "National ID"
    assert has_element?(view, "form[phx-submit='lookup']")
    refute has_element?(view, "#patient-form")
  end

  test "an unknown ID drops straight into the new-patient form, ID pre-filled", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/receptionist/patients/new")

    html =
      view
      |> form("form[phx-submit='lookup']", %{"national_id" => "NOSUCH-123"})
      |> render_submit()

    assert has_element?(view, "#patient-form")
    assert html =~ ~s(value="NOSUCH-123")
  end

  test "adding a patient also creates a triage visit and a camp-attendance row", %{
    conn: conn,
    receptionist: receptionist
  } do
    camp = camp_fixture(receptionist)
    {:ok, view, _html} = live(conn, ~p"/receptionist/patients/new")

    view
    |> element("button[phx-click='register_new']")
    |> render_click()

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
    assert visit.status == "triage_pending"

    Medcamp.Tenancy.with_org(receptionist.organisation_id, fn ->
      assert Medcamp.CampAttendances.attended?(patient.id, camp.id)
    end)

    # Instead of navigating away, the receptionist gets a wristband to print.
    assert render(view) =~ "Amina Wanjiru is registered"
    assert has_element?(view, "#receptionist-registered-code-wrap")
    assert has_element?(view, "button[data-print-trigger]")
    assert render(view) =~ patient.gsrn
  end

  test "the patient list offers a per-row reprint of the wristband code", %{
    conn: conn,
    receptionist: receptionist
  } do
    scope = fn f -> Medcamp.Tenancy.with_org(receptionist.organisation_id, f) end

    {:ok, patient} =
      scope.(fn ->
        Medcamp.Patients.create_patient(%{
          "first_name" => "Reprint",
          "last_name" => "Me",
          "phone_number" => "0700111000",
          "date_of_birth" => "1990-01-01",
          "gender" => "Male",
          "home_address" => "Nairobi",
          "creator_id" => receptionist.id
        })
      end)

    {:ok, view, _html} = live(conn, ~p"/receptionist/patients")

    view
    |> element("button[phx-click='show_patient_code'][phx-value-patient_id='#{patient.id}']")
    |> render_click()

    assert has_element?(view, "#receptionist-reprint-code-wrap")
    assert render(view) =~ patient.gsrn
  end

  test "a known ID reuses the record and just opens a new visit", %{
    conn: conn,
    receptionist: receptionist
  } do
    _camp = camp_fixture(receptionist)

    {existing, _} =
      Medcamp.Tenancy.with_org(receptionist.organisation_id, fn ->
        Medcamp.Patients.register_for_camp(
          %{
            "first_name" => "Grace",
            "last_name" => "Otieno",
            "phone_number" => "0700999888",
            "date_of_birth" => "1985-02-02",
            "gender" => "Female",
            "home_address" => "Nakuru",
            "national_id" => "KE-987654"
          },
          receptionist
        )
        |> elem(1)
      end)

    {:ok, view, _html} = live(conn, ~p"/receptionist/patients/new")

    view
    |> form("form[phx-submit='lookup']", %{"national_id" => "ke-987654"})
    |> render_submit()

    assert render(view) =~ "Grace Otieno"

    view |> element("button[phx-click='register_visit']") |> render_click()

    visits =
      Medcamp.Tenancy.with_org(receptionist.organisation_id, fn ->
        Medcamp.PatientVisits.list_patient_visits_by_patient_id(existing.id)
      end)

    assert length(visits) == 2
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
