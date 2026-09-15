defmodule MedcampWeb.MedicalCampPages.HomeTest do
  @moduledoc """
  The patient camp-home / triage station page reached by scanning a wristband
  (`/8018/:gsrn/medical-camp`).

  Phase 7 gap 1 (PROD_READINESS_REVIEW_2): this route had zero tests.

  E8-1 (the hard 500 for every scanned patient) and S-2 (no org/role guard on
  the `:medical_camp` live_session) are both **fixed**: the session now runs
  `MedicalCampAuth.:require_camp_auth` (org + role match), the OTP modal /
  client-side blur are gone, and an unauthenticated visitor is sent to the
  station PIN screen instead of the record.
  """
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures
  import Medcamp.PatientsFixtures

  alias Medcamp.Repo

  setup %{conn: conn} do
    patient = patient_fixture()
    %{conn: conn, patient: patient, path: "/8018/#{patient.gsrn}/medical-camp"}
  end

  describe "mount redirects a signed-in clinician to their station route" do
    test "a nurse is sent to the new-triage route", %{conn: conn, path: path} do
      nurse = user_fixture(%{role: "nurse"})

      assert {:error, {:live_redirect, %{to: to}}} = live(log_in_user(conn, nurse), path)
      assert to == "#{path}/triages/new"
    end

    test "a doctor is sent to the doctor-notes route", %{conn: conn, path: path} do
      doctor = user_fixture(%{role: "doctor"})

      assert {:error, {:live_redirect, %{to: to}}} = live(log_in_user(conn, doctor), path)
      assert to == "#{path}/doctor_notes"
    end

    test "a same-org receptionist sees the patient overview (no PIN prompt)", %{
      conn: conn,
      patient: patient,
      path: path
    } do
      receptionist = user_fixture(%{role: "receptionist"})
      assert receptionist.organisation_id == patient.organisation_id

      {:ok, _view, html} = live(log_in_user(conn, receptionist), path)

      assert html =~ patient.gsrn
      assert html =~ patient.first_name
      refute html =~ "Enter your 4-digit"
    end
  end

  describe "the guard (S-2 fixed)" do
    test "no staff session -> redirected to the station PIN screen", %{conn: conn, path: path} do
      assert {:error, {:redirect, %{to: to}}} = live(conn, path)
      assert to == "#{path}/pin"
    end

    test "signed in for a DIFFERENT organisation -> denied, sent to full login", %{
      conn: conn,
      path: path
    } do
      other_org = Medcamp.OrganisationsFixtures.organisation_fixture(%{"name" => "Other Org"})

      outside_staff =
        user_fixture(%{role: "receptionist"})
        |> Ecto.Changeset.change(%{organisation_id: other_org.id})
        |> Repo.update!()

      assert {:error, {:redirect, %{to: "/users/log_in"}}} =
               live(log_in_user(conn, outside_staff), path)
    end

    test "an unknown GSRN redirects gracefully, no 500", %{conn: conn} do
      # No session -> PIN screen (which then shows 'not recognised'); with a
      # valid session -> the guard's :error branch -> full login.
      assert {:error, {:redirect, %{to: "/8018/NOSUCHGSRN/medical-camp/pin"}}} =
               live(conn, "/8018/NOSUCHGSRN/medical-camp")

      staff = user_fixture(%{role: "receptionist"})

      assert {:error, {:redirect, %{to: "/users/log_in"}}} =
               live(log_in_user(conn, staff), "/8018/NOSUCHGSRN/medical-camp")
    end

    test "the /triages/new route is guarded the same way", %{conn: conn, patient: patient} do
      assert {:error, {:redirect, %{to: to}}} =
               live(conn, "/8018/#{patient.gsrn}/medical-camp/triages/new")

      assert to == "/8018/#{patient.gsrn}/medical-camp/pin"
    end
  end
end
