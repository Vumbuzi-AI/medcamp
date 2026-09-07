defmodule MedcampWeb.DoctorsPagePatientLive.DoctorSignatureTest do
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
      base_path: "/doctor/patients/#{patient.id}/notes/#{doctor_note.id}"
    }
  end

  test "renders a signature pad on the consultation note form", %{
    conn: conn,
    base_path: base_path
  } do
    {:ok, _view, html} = live(conn, base_path)

    assert html =~ "Doctor&#39;s Signature" or html =~ "Doctor's Signature"
    assert html =~ "doctor_note-signature"
    assert html =~ ~s(phx-hook="SignaturePad")
  end

  test "saving the note with a captured signature stores it and stamps signed_at", %{
    conn: conn,
    base_path: base_path,
    doctor_note: doctor_note
  } do
    {:ok, view, _html} = live(conn, base_path)

    signature_data_url = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAUA"

    view
    |> element("#doctor_note-form")
    |> render_submit(%{
      "doctor_note" => %{
        "date" => Date.to_iso8601(doctor_note.date),
        "time" => Time.to_iso8601(doctor_note.time) |> String.slice(0, 5),
        "symptoms" => doctor_note.symptoms,
        "doctor_signature" => signature_data_url
      }
    })

    updated = DoctorNotes.get_doctor_note!(doctor_note.id)
    assert updated.doctor_signature == signature_data_url
    assert updated.signed_at != nil
  end

  test "saving the note without touching the signature leaves it unset", %{
    conn: conn,
    base_path: base_path,
    doctor_note: doctor_note
  } do
    {:ok, view, _html} = live(conn, base_path)

    view
    |> element("#doctor_note-form")
    |> render_submit(%{
      "doctor_note" => %{
        "date" => Date.to_iso8601(doctor_note.date),
        "time" => Time.to_iso8601(doctor_note.time) |> String.slice(0, 5),
        "symptoms" => doctor_note.symptoms
      }
    })

    updated = DoctorNotes.get_doctor_note!(doctor_note.id)
    assert updated.doctor_signature == nil
    assert updated.signed_at == nil
  end
end
