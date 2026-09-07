defmodule MedcampWeb.MedicalCampPages.DoctorNoteNewTest do
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
      path: "/8018/#{patient.gsrn}/medical-camp/doctor_notes/new"
    }
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

    created = DoctorNotes.list_doctor_notes() |> Enum.find(&(&1.patient_id == patient.id))
    assert created
    assert created.doctor_id == doctor.id
    assert created.symptoms == "Fever and cough"
  end
end
