defmodule MedcampWeb.DoctorNotesComponentsTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MedcampWeb.DoctorNotesComponents

  test "renders the language, recording, review, edit, and save modal workflow" do
    form = Phoenix.Component.to_form(%{"complaints" => ""}, as: :doctor_note)

    html =
      render_component(&DoctorNotesComponents.voice_textarea/1,
        field: form[:complaints],
        label: "Complaints"
      )

    assert html =~ ~s(data-role="voice-language-modal")
    assert html =~ ~s(data-role="voice-language")
    assert html =~ ~s(<optgroup label="Kenyan languages">)
    assert html =~ ~s(value="sw")
    assert html =~ ~s(value="ki")
    assert html =~ "Gikuyu (experimental)"
    assert html =~ ~s(data-role="voice-stop")
    assert html =~ ~s(data-role="voice-transcript")
    assert html =~ "English transcription"
    assert html =~ ~s(data-role="voice-retry")
    assert html =~ ~s(data-role="voice-save")
    assert html =~ "Save to note"

    [field_header] = Floki.find(html, ~s([data-role="voice-field-header"]))
    assert Floki.text(field_header) =~ "Complaints"
    assert [_button] = Floki.find(field_header, ~s([data-role="voice-btn"]))
  end

  describe "doctor_notes_form/1 draft_key" do
    setup do
      changeset = Medcamp.DoctorNotes.change_doctor_note(%Medcamp.DoctorNotes.DoctorNote{})

      %{
        patient: %{id: 1, gender: "female"},
        form: Phoenix.Component.to_form(changeset)
      }
    end

    test "renders phx-hook and data-draft-key when a draft_key is given", %{
      patient: patient,
      form: form
    } do
      html =
        render_component(&DoctorNotesComponents.doctor_notes_form/1,
          patient: patient,
          form: form,
          show_lab_imaging_request: false,
          draft_key: "doctor_note:1:new"
        )

      assert html =~ ~s(phx-hook="DraftPersistence")
      assert html =~ ~s(data-draft-key="doctor_note:1:new")
    end

    test "omits phx-hook and data-draft-key entirely when no draft_key is given", %{
      patient: patient,
      form: form
    } do
      html =
        render_component(&DoctorNotesComponents.doctor_notes_form/1,
          patient: patient,
          form: form,
          show_lab_imaging_request: false
        )

      refute html =~ "DraftPersistence"
      refute html =~ "data-draft-key"
    end
  end
end
