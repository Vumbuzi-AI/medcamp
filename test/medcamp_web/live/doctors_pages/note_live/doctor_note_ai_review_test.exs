defmodule MedcampWeb.DoctorsPagePatientLive.DoctorNoteAiReviewTest do
  use MedcampWeb.ConnCase, async: false

  import Phoenix.LiveViewTest
  import Medcamp.AccountsFixtures
  import Medcamp.PatientsFixtures
  import Medcamp.DoctorNotesFixtures

  alias Medcamp.DoctorNotes

  defmodule FakeAIClient do
    @moduledoc false

    def request_json_to_gpt(_system_prompt, _user_prompt) do
      :counters.add(call_counter(), 1, 1)

      case :persistent_term.get({__MODULE__, :delay_ms}, 0) do
        0 -> :ok
        ms -> Process.sleep(ms)
      end

      case :persistent_term.get({__MODULE__, :response}, :not_configured) do
        :not_configured -> raise "no fake response configured for this test"
        response -> response
      end
    end

    def call_count, do: :counters.get(call_counter(), 1)

    defp call_counter do
      case :persistent_term.get({__MODULE__, :call_counter}, nil) do
        nil ->
          ref = :counters.new(1, [])
          :persistent_term.put({__MODULE__, :call_counter}, ref)
          ref

        ref ->
          ref
      end
    end
  end

  defp put_response(response), do: :persistent_term.put({FakeAIClient, :response}, response)
  defp put_delay_ms(ms), do: :persistent_term.put({FakeAIClient, :delay_ms}, ms)

  defp valid_assessment do
    {:ok,
     %{
       "case_summary" => "A patient with fever and cough.",
       "data_quality" => %{
         "sufficient_for_review" => true,
         "missing_critical_information" => [],
         "conflicting_information" => []
       },
       "urgency" => %{"level" => "routine", "red_flags" => []},
       "independent_impression" => %{
         "summary" => "Consistent with a viral upper respiratory infection.",
         "evidence_strength" => "moderate",
         "source_refs" => []
       },
       "differential_diagnoses" => [],
       "recommended_next_steps" => [],
       "medication_review" => %{
         "allergy_conflicts" => [],
         "interaction_warnings" => [],
         "existing_medication_concerns" => [],
         "options_to_consider" => []
       },
       "questions_for_clinician" => [],
       "safety_netting" => [],
       "limitations" => []
     }}
  end

  setup %{conn: conn} do
    Application.put_env(:medcamp, :ai_doc_reviewer_client, FakeAIClient)
    :persistent_term.put({FakeAIClient, :call_counter}, :counters.new(1, []))

    on_exit(fn ->
      Application.delete_env(:medcamp, :ai_doc_reviewer_client)
      :persistent_term.erase({FakeAIClient, :response})
      :persistent_term.erase({FakeAIClient, :delay_ms})
      :persistent_term.erase({FakeAIClient, :call_counter})
    end)

    doctor = user_fixture(%{role: "doctor", name: "Dr. Test"})
    patient = patient_fixture()
    doctor_note = doctor_note_fixture(%{doctor: doctor, patient: patient})

    %{
      conn: log_in_user(conn, doctor),
      doctor_note: doctor_note,
      base_path: "/doctor/patients/#{patient.id}/notes/#{doctor_note.id}?tab=ai_review"
    }
  end

  test "shows a loading state immediately, then clears it and renders the result on success", %{
    conn: conn,
    base_path: base_path,
    doctor_note: doctor_note
  } do
    put_response(valid_assessment())

    {:ok, view, _html} = live(conn, base_path)

    html = render_click(view, "run_ai_review")
    assert html =~ "Generating your AI review"

    final_html = render_async(view)
    refute final_html =~ "Generating your AI review"
    assert final_html =~ "AI review generated"
    assert final_html =~ "Consistent with a viral upper respiratory infection."

    reloaded = DoctorNotes.get_doctor_note!(doctor_note.id)
    assert reloaded.ai_review_status == "completed"
  end

  test "on failure, clears the loading state and surfaces an error flash", %{
    conn: conn,
    base_path: base_path,
    doctor_note: doctor_note
  } do
    put_response({:error, "AI service authorization failed. Check OPENAI_API_KEY."})

    {:ok, view, _html} = live(conn, base_path)

    html = render_click(view, "run_ai_review")
    assert html =~ "Generating your AI review"

    final_html = render_async(view)
    refute final_html =~ "Generating your AI review"
    assert final_html =~ "Could not generate the AI review right now"

    reloaded = DoctorNotes.get_doctor_note!(doctor_note.id)
    assert reloaded.ai_review_status != "completed"
  end

  test "a second click while a review is already in flight is ignored", %{
    conn: conn,
    base_path: base_path
  } do
    put_response(valid_assessment())
    put_delay_ms(150)

    {:ok, view, _html} = live(conn, base_path)

    html = render_click(view, "run_ai_review")
    assert html =~ "Generating your AI review"

    html_after_second_click = render_click(view, "run_ai_review")
    assert html_after_second_click =~ "Generating your AI review"

    final_html = render_async(view, 1000)
    assert final_html =~ "AI review generated"
    assert FakeAIClient.call_count() == 1
  end

  test "rejects run_ai_review server-side when the note lacks sufficient source data", %{
    conn: conn
  } do
    patient = patient_fixture()
    doctor_note = doctor_note_fixture(%{patient: patient, reason_for_consulatation: ""})
    path = "/doctor/patients/#{patient.id}/notes/#{doctor_note.id}?tab=ai_review"

    {:ok, view, _html} = live(conn, path)

    html = render_click(view, "run_ai_review")

    refute html =~ "Generating your AI review"
    assert html =~ "before running an AI review"
    assert FakeAIClient.call_count() == 0

    reloaded = DoctorNotes.get_doctor_note!(doctor_note.id)
    assert reloaded.ai_review_status != "completed"
  end
end
