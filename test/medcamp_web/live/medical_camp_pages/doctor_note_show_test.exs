defmodule MedcampWeb.MedicalCampPages.DoctorNoteShowTest do
  use MedcampWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures
  import Medcamp.PatientsFixtures
  import Medcamp.DoctorNotesFixtures

  alias Medcamp.DoctorNotes

  setup %{conn: conn} do
    doctor = user_fixture(%{role: "doctor", name: "Dr. Test"})
    patient = patient_fixture()
    doctor_note = doctor_note_fixture(%{doctor: doctor, patient: patient})

    %{
      conn: log_in_user(conn, doctor),
      doctor: doctor,
      patient: patient,
      doctor_note: doctor_note,
      path: "/8018/#{patient.gsrn}/medical-camp/doctor_notes/#{doctor_note.id}"
    }
  end

  test "renders a draft key scoped to this patient and note once editing is toggled on", %{
    conn: conn,
    path: path,
    patient: patient,
    doctor_note: doctor_note
  } do
    {:ok, view, _html} = live(conn, path)

    html = view |> element(~s([phx-click="toggle_edit"]), "Edit Note") |> render_click()

    assert html =~ ~s(phx-hook="DraftPersistence")
    assert html =~ ~s(data-draft-key="doctor_note:#{patient.id}:#{doctor_note.id}")
  end

  test "updates the doctor note on valid submission", %{
    conn: conn,
    path: path,
    doctor_note: doctor_note
  } do
    {:ok, view, _html} = live(conn, path)

    view |> element(~s([phx-click="toggle_edit"]), "Edit Note") |> render_click()

    view
    |> form("#doctor_note-form", %{
      "doctor_note" => %{"symptoms" => "Updated symptoms"}
    })
    |> render_submit()

    updated = DoctorNotes.get_doctor_note!(doctor_note.id)
    assert updated.symptoms == "Updated symptoms"
  end
end
