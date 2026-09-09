defmodule MedcampWeb.MedicalCampPages.DoctorNotesTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures
  import Medcamp.PatientsFixtures

  alias Medcamp.DoctorNotes

  setup %{conn: conn} do
    doctor = user_fixture(%{role: "doctor", name: "Dr. Test"})
    patient = patient_fixture()

    %{
      conn: log_in_user(conn, doctor),
      doctor: doctor,
      patient: patient,
      path: "/8018/#{patient.gsrn}/medical-camp/doctor_notes"
    }
  end

  test "redirects visitors with no staff login to sign in", %{patient: patient} do
    conn = Phoenix.ConnTest.build_conn()

    assert {:error, {:redirect, %{to: "/users/log_in"}}} =
             live(conn, "/8018/#{patient.gsrn}/medical-camp/doctor_notes")
  end

  test "redirects a doctor from a different organisation", %{patient: patient} do
    other_org = Medcamp.OrganisationsFixtures.organisation_fixture(%{"name" => "Other Org"})

    outside_doctor =
      user_fixture(%{role: "doctor"})
      |> Ecto.Changeset.change(%{organisation_id: other_org.id})
      |> Medcamp.Repo.update!()

    conn = log_in_user(Phoenix.ConnTest.build_conn(), outside_doctor)

    assert {:error, {:redirect, %{to: "/users/log_in"}}} =
             live(conn, "/8018/#{patient.gsrn}/medical-camp/doctor_notes")
  end

  test "redirects a same-org user whose role is not a doctor", %{patient: patient} do
    nurse = user_fixture(%{role: "nurse"})
    conn = log_in_user(Phoenix.ConnTest.build_conn(), nurse)

    assert {:error, {:redirect, %{to: "/users/log_in"}}} =
             live(conn, "/8018/#{patient.gsrn}/medical-camp/doctor_notes")
  end

  test "renders a draft key scoped to this patient's new note", %{
    conn: conn,
    path: path,
    patient: patient
  } do
    {:ok, _view, html} = live(conn, path)

    assert html =~ ~s(phx-hook="DraftPersistence")
    assert html =~ ~s(data-draft-key="doctor_note:#{patient.id}:new")
  end

  test "creates the doctor note on valid submission", %{
    conn: conn,
    path: path,
    patient: patient,
    doctor: doctor
  } do
    {:ok, view, _html} = live(conn, path)

    view
    |> form("#doctor_note-form", %{
      "doctor_note" => %{"symptoms" => "Fever and cough"}
    })
    |> render_submit()

    created = DoctorNotes.doctor_notes_for_patient(patient.id) |> List.first()
    assert created
    assert created.doctor_id == doctor.id
    assert created.symptoms == "Fever and cough"
  end
end
