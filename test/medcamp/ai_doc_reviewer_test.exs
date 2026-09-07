defmodule Medcamp.AIDocReviewerTest do
  use Medcamp.DataCase, async: true

  import Medcamp.DoctorNotesFixtures
  import Medcamp.DrugAllocationsFixtures
  import Medcamp.LabResultsFixtures
  import Medcamp.PatientsFixtures
  import Medcamp.TriagesFixtures

  alias Medcamp.AIDocReviewer
  alias Medcamp.DoctorNotes

  # Fake `request_json_to_gpt/2`; each test sets its response via the
  # process dictionary, so it stays test-local under `async: true`.
  defmodule FakeAIClient do
    @moduledoc false

    def request_json_to_gpt(system_prompt, _user_prompt) do
      key =
        if String.contains?(system_prompt, "previously formed an independent"),
          do: :fake_closeness_response,
          else: :fake_assessment_response

      Process.get(key) || raise "no fake #{key} configured for this test"
    end
  end

  defp put_assessment_response(response), do: Process.put(:fake_assessment_response, response)
  defp put_closeness_response(response), do: Process.put(:fake_closeness_response, response)

  defp valid_assessment do
    {:ok,
     %{
       "case_summary" => "A patient with fever and cough, likely a respiratory infection.",
       "data_quality" => %{
         "sufficient_for_review" => true,
         "missing_critical_information" => [],
         "conflicting_information" => []
       },
       "urgency" => %{"level" => "routine", "red_flags" => []},
       "independent_impression" => %{
         "summary" => "Findings are consistent with a lower respiratory tract infection.",
         "evidence_strength" => "moderate",
         "source_refs" => ["current.symptoms"]
       },
       "differential_diagnoses" => [
         %{
           "condition" => "Community-acquired pneumonia",
           "likelihood" => "most_likely",
           "rationale" => "Fever and cough with no other clear cause.",
           "evidence_for" => ["fever", "cough"],
           "evidence_against" => [],
           "source_refs" => ["current.symptoms"]
         }
       ],
       "recommended_next_steps" => [
         %{
           "type" => "investigation",
           "priority" => "routine",
           "action" => "Order a chest x-ray",
           "reason" => "To confirm consolidation",
           "source_refs" => ["current.symptoms"]
         }
       ],
       "medication_review" => %{
         "allergy_conflicts" => [],
         "interaction_warnings" => [],
         "existing_medication_concerns" => ["No documented allergies on file."],
         "options_to_consider" => [
           %{
             "generic_name" => "Amoxicillin",
             "indication" => "Community-acquired pneumonia",
             "rationale" => "First-line for typical presentations.",
             "preconditions" => ["No penicillin allergy"],
             "contraindications_or_cautions" => ["Penicillin allergy"],
             "monitoring" => ["Reassess in 48-72 hours"],
             "dose" => "500mg three times daily",
             "source_refs" => []
           }
         ]
       },
       "questions_for_clinician" => ["Has the patient traveled recently?"],
       "safety_netting" => [
         %{
           "trigger" => "worsening shortness of breath",
           "action" => "Return immediately for reassessment."
         }
       ],
       "limitations" => []
     }}
  end

  defp valid_closeness(score) do
    {:ok, %{"score" => score, "explanation" => "Both point toward a respiratory infection."}}
  end

  describe "build_context_for_doctor_note/1" do
    test "excludes direct patient identifiers" do
      patient =
        patient_fixture(%{
          "first_name" => "Jane",
          "last_name" => "Doe",
          "phone_number" => "0700000000",
          "national_id" => "12345678",
          "gsrn" => "GSRN-999"
        })

      doctor_note = doctor_note_fixture(%{patient: patient})

      context = AIDocReviewer.build_context_for_doctor_note(doctor_note)

      encoded = Jason.encode!(context.blind_context)

      refute encoded =~ "Jane"
      refute encoded =~ "Doe"
      refute encoded =~ "0700000000"
      refute encoded =~ "12345678"
      refute encoded =~ "GSRN-999"

      refute Map.has_key?(context.blind_context.patient_context, "patient_id")
      assert context.blind_context.patient_context["age"]
    end

    test "uses the six core doctor-note fields while withholding the diagnosis" do
      doctor_note =
        doctor_note_fixture(%{
          reason_for_consulatation: "Fever and chills",
          clinical_notes: "Patient is alert",
          past_medical_history: "No chronic illness",
          diagnosis: "Malaria",
          impression: "Likely malaria given the fever pattern",
          management: "Start antimalarials",
          investigations: "Malaria test ordered"
        })

      context = AIDocReviewer.build_context_for_doctor_note(doctor_note)
      current = context.blind_context.current_presentation

      assert current == %{
               "reason_for_consultation" => "Fever and chills",
               "clinical_notes" => "Patient is alert",
               "past_medical_history" => "No chronic illness",
               "impression" => "Likely malaria given the fever pattern",
               "management" => "Start antimalarials",
               "investigations" => "Malaria test ordered"
             }

      refute Map.has_key?(current, "diagnosis")

      # ... but it IS available for the post-comparison phase.
      assert context.doctor_assessment.diagnosis == "Malaria"
    end

    test "keys triage/lab/prior-note/prescription context by real database id, not as anonymous lists" do
      patient = patient_fixture()
      triage = triage_fixture(%{patient_id: patient.id})
      doctor_note = doctor_note_fixture(%{patient: patient})
      lab_result = lab_result_fixture(%{patient: patient, doctor_note: doctor_note})

      drug_allocation =
        drug_allocation_fixture(%{patient: patient, doctor_note_id: doctor_note.id})

      context = AIDocReviewer.build_context_for_doctor_note(doctor_note)

      assert Map.has_key?(context.blind_context.triage_history, to_string(triage.id))

      assert Map.has_key?(
               context.blind_context.current_note_lab_results,
               to_string(lab_result.id)
             )

      assert Map.has_key?(context.blind_context.patient_lab_history, to_string(lab_result.id))

      assert Map.has_key?(
               context.blind_context.existing_prescriptions,
               to_string(drug_allocation.id)
             )
    end

    test "includes full prior-note history, diagnosis included, for the same patient" do
      patient = patient_fixture()

      older_note =
        doctor_note_fixture(%{patient: patient, diagnosis: "Prior UTI", symptoms: "dysuria"})

      current_note = doctor_note_fixture(%{patient: patient, symptoms: "new symptoms"})

      context = AIDocReviewer.build_context_for_doctor_note(current_note)

      assert context.blind_context.prior_notes[to_string(older_note.id)]["diagnosis"] ==
               "Prior UTI"
    end

    test "includes the fuller prior-note field set, excluding the prior note's own ai_review metadata" do
      patient = patient_fixture()

      older_note =
        doctor_note_fixture(%{
          patient: patient,
          reason_for_consulatation: "Follow-up visit",
          investigations: "Urinalysis ordered",
          impression: "Likely resolving UTI",
          diagnosis_icd_code: "N39.0",
          clinical_notes: "Patient reports improvement",
          lifestyle_recommendations: "Increase fluid intake"
        })

      current_note = doctor_note_fixture(%{patient: patient})

      context = AIDocReviewer.build_context_for_doctor_note(current_note)
      normalized = context.blind_context.prior_notes[to_string(older_note.id)]

      assert normalized["reason_for_consultation"] == "Follow-up visit"
      assert normalized["investigations"] == "Urinalysis ordered"
      assert normalized["impression"] == "Likely resolving UTI"
      assert normalized["diagnosis_icd_code"] == "N39.0"
      assert normalized["clinical_notes"] == "Patient reports improvement"
      assert normalized["lifestyle_recommendations"] == "Increase fluid intake"
      refute Map.has_key?(normalized, "ai_review_status")
      refute Map.has_key?(normalized, "ai_review_payload")
    end

    test "includes full triage history for the patient" do
      patient = patient_fixture()
      older_triage = triage_fixture(%{patient_id: patient.id, temperature: 38.0})
      latest_triage = triage_fixture(%{patient_id: patient.id, temperature: 39.5})
      doctor_note = doctor_note_fixture(%{patient: patient})

      context = AIDocReviewer.build_context_for_doctor_note(doctor_note)

      assert context.blind_context.triage_history[to_string(older_triage.id)]["temperature"] ==
               38.0

      assert context.blind_context.triage_history[to_string(latest_triage.id)]["temperature"] ==
               39.5
    end

    test "includes patient-wide lab history separately from the current note's own labs" do
      patient = patient_fixture()
      doctor_note = doctor_note_fixture(%{patient: patient})

      context = AIDocReviewer.build_context_for_doctor_note(doctor_note)

      assert Map.has_key?(context.blind_context, :patient_lab_history)
      assert Map.has_key?(context.blind_context, :current_note_lab_results)
    end

    test "normalizes lab result fields (findings, dates, per-test results, prior interpretation)" do
      patient = patient_fixture()
      doctor_note = doctor_note_fixture(%{patient: patient})

      lab_result =
        lab_result_fixture(%{
          patient: patient,
          doctor_note: doctor_note,
          description: "Full blood count",
          urgency: "routine",
          report_complete: true,
          date_of_test: ~D[2026-01-10],
          sample_collection_date: ~D[2026-01-09],
          test_findings: "Mild leukocytosis",
          tests: [%{name: "CBC", price: 500, result: "WBC 12.5"}],
          interpretation_payload: %{"clinical_interpretation" => ["Within normal limits"]}
        })

      context = AIDocReviewer.build_context_for_doctor_note(doctor_note)

      normalized = context.blind_context.current_note_lab_results[to_string(lab_result.id)]

      assert normalized == %{
               "description" => "Full blood count",
               "urgency" => "routine",
               "report_complete" => true,
               "date_of_test" => ~D[2026-01-10],
               "sample_collection_date" => ~D[2026-01-09],
               "test_findings" => "Mild leukocytosis",
               "tests" => [%{"name" => "CBC", "result" => "WBC 12.5"}],
               "prior_ai_interpretation" => ["Within normal limits"]
             }

      assert context.blind_context.patient_lab_history[to_string(lab_result.id)] == normalized
    end

    test "normalizes existing drug allocations for the current note" do
      patient = patient_fixture()
      doctor_note = doctor_note_fixture(%{patient: patient})

      drug_allocation =
        drug_allocation_fixture(%{
          patient: patient,
          doctor_note_id: doctor_note.id,
          prescription: "Amoxicillin 500mg",
          has_been_assigned: true
        })

      context = AIDocReviewer.build_context_for_doctor_note(doctor_note)

      assert context.blind_context.existing_prescriptions[to_string(drug_allocation.id)] == %{
               "prescription" => "Amoxicillin 500mg",
               "has_been_assigned" => true
             }
    end
  end

  describe "refresh_doctor_note_review/2 — valid responses" do
    test "parses a valid response and persists it, closeness not_yet_decided without a diagnosis" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})
      put_assessment_response(valid_assessment())

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert updated.ai_review_status == "completed"
      assert updated.ai_review_generated_at

      payload = updated.ai_review_payload
      assert payload["schema_version"] == "2.0"
      assert payload["independent_impression"]["summary"] =~ "respiratory"

      assert [%{"generic_name" => "Amoxicillin"}] =
               payload["medication_review"]["options_to_consider"]

      assert payload["medication_review"]["existing_medication_concerns"] == [
               "No documented allergies on file."
             ]

      assert payload["closeness"] == %{
               "status" => "not_yet_decided",
               "score" => nil,
               "explanation" => nil
             }
    end

    test "treats a whitespace-only diagnosis/impression as not yet decided" do
      doctor_note = doctor_note_fixture(%{diagnosis: "   ", impression: "\n"})
      put_assessment_response(valid_assessment())

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)

      assert updated.ai_review_payload["closeness"] == %{
               "status" => "not_yet_decided",
               "score" => nil,
               "explanation" => nil
             }
    end

    test "computes closeness once a diagnosis exists" do
      doctor_note = doctor_note_fixture(%{diagnosis: "Pneumonia"})
      put_assessment_response(valid_assessment())
      put_closeness_response(valid_closeness(78))

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)

      closeness = updated.ai_review_payload["closeness"]
      assert closeness["status"] == "computed"
      assert closeness["score"] == 78
      assert closeness["explanation"] =~ "respiratory"
    end

    test "accepts a doctor note id and loads the note before reviewing" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})
      put_assessment_response(valid_assessment())

      assert {:ok, updated} =
               AIDocReviewer.refresh_doctor_note_review(doctor_note.id, FakeAIClient)

      assert updated.id == doctor_note.id
      assert updated.ai_review_status == "completed"
    end

    test "falls back to a default message when the AI omits the impression" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})

      put_assessment_response({:ok, %{}})

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)

      assert updated.ai_review_payload["independent_impression"]["summary"] =~
               "Not enough information"
    end

    test "falls back to a default message when the AI returns a blank impression summary" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})

      put_assessment_response({:ok, %{"independent_impression" => %{"summary" => ""}}})

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)

      assert updated.ai_review_payload["independent_impression"]["summary"] =~
               "Not enough information"
    end

    test "surfaces actionable missing_critical_information when data is insufficient" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})

      put_assessment_response(
        {:ok,
         %{
           "case_summary" => "Not enough information to assess.",
           "data_quality" => %{
             "sufficient_for_review" => false,
             "missing_critical_information" => [
               "Add the patient's investigation results before relying on this review."
             ]
           },
           "independent_impression" => %{"summary" => "Insufficient data."}
         }}
      )

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)

      data_quality = updated.ai_review_payload["data_quality"]
      assert data_quality["sufficient_for_review"] == false

      assert data_quality["missing_critical_information"] == [
               "Add the patient's investigation results before relying on this review."
             ]
    end
  end

  describe "refresh_doctor_note_review/2 — malformed field fallbacks" do
    test "data_quality falls back to a safe default when malformed" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})
      put_assessment_response({:ok, %{"data_quality" => "not a map"}})

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)

      assert updated.ai_review_payload["data_quality"] == %{
               "sufficient_for_review" => true,
               "missing_critical_information" => [],
               "conflicting_information" => []
             }
    end

    test "urgency falls back to routine with no red flags when malformed" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})
      put_assessment_response({:ok, %{"urgency" => "not a map"}})

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert updated.ai_review_payload["urgency"] == %{"level" => "routine", "red_flags" => []}
    end

    test "independent_impression falls back to a default when malformed" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})
      put_assessment_response({:ok, %{"independent_impression" => "not a map"}})

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      impression = updated.ai_review_payload["independent_impression"]
      assert impression["summary"] =~ "Not enough information"
      assert impression["evidence_strength"] == "weak"
      assert impression["source_refs"] == []
    end

    test "differential_diagnoses falls back to an empty list when malformed" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})
      put_assessment_response({:ok, %{"differential_diagnoses" => "not a list"}})

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert updated.ai_review_payload["differential_diagnoses"] == []
    end

    test "differential_diagnoses drops entries missing a condition" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})

      put_assessment_response(
        {:ok,
         %{
           "differential_diagnoses" => [
             %{"likelihood" => "possible", "rationale" => "no condition given"},
             %{"condition" => "Pneumonia", "likelihood" => "most_likely"}
           ]
         }}
      )

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert [%{"condition" => "Pneumonia"}] = updated.ai_review_payload["differential_diagnoses"]
    end

    test "recommended_next_steps falls back to an empty list when malformed" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})
      put_assessment_response({:ok, %{"recommended_next_steps" => "not a list"}})

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert updated.ai_review_payload["recommended_next_steps"] == []
    end

    test "medication_review falls back to empty lists when malformed" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})
      put_assessment_response({:ok, %{"medication_review" => "not a map"}})

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)

      assert updated.ai_review_payload["medication_review"] == %{
               "allergy_conflicts" => [],
               "interaction_warnings" => [],
               "existing_medication_concerns" => [],
               "options_to_consider" => []
             }
    end

    test "options_to_consider wraps a bare string instead of dropping it, for list fields" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})

      put_assessment_response(
        {:ok,
         %{
           "medication_review" => %{
             "options_to_consider" => [
               %{
                 "generic_name" => "Amoxicillin",
                 "preconditions" => "No penicillin allergy",
                 "contraindications_or_cautions" => "Penicillin allergy",
                 "monitoring" => "Reassess in 48-72 hours"
               }
             ]
           }
         }}
      )

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)

      assert [
               %{
                 "preconditions" => ["No penicillin allergy"],
                 "contraindications_or_cautions" => ["Penicillin allergy"],
                 "monitoring" => ["Reassess in 48-72 hours"]
               }
             ] = updated.ai_review_payload["medication_review"]["options_to_consider"]
    end

    test "safety_netting falls back to an empty list when malformed" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})
      put_assessment_response({:ok, %{"safety_netting" => "not a list"}})

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert updated.ai_review_payload["safety_netting"] == []
    end

    test "safety_netting strips a redundant leading if/when from the trigger" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})

      put_assessment_response(
        {:ok,
         %{
           "safety_netting" => [
             %{"trigger" => "If fever persists beyond 48 hours", "action" => "Seek care."},
             %{"trigger" => "When breathing worsens", "action" => "Return immediately."},
             %{"trigger" => "chest pain develops", "action" => "Go to the emergency room."}
           ]
         }}
      )

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)

      assert [
               %{"trigger" => "fever persists beyond 48 hours"},
               %{"trigger" => "breathing worsens"},
               %{"trigger" => "chest pain develops"}
             ] = updated.ai_review_payload["safety_netting"]
    end

    test "questions_for_clinician wraps a bare string instead of dropping it" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})

      put_assessment_response(
        {:ok, %{"questions_for_clinician" => "Has the patient traveled recently?"}}
      )

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)

      assert updated.ai_review_payload["questions_for_clinician"] == [
               "Has the patient traveled recently?"
             ]
    end

    test "questions_for_clinician falls back to an empty list for a non-list, non-string value" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})
      put_assessment_response({:ok, %{"questions_for_clinician" => 42}})

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert updated.ai_review_payload["questions_for_clinician"] == []
    end

    test "schema_version is always the stamped constant, regardless of what the AI returns" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})
      put_assessment_response({:ok, %{"schema_version" => "999.9"}})

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert updated.ai_review_payload["schema_version"] == "2.0"
    end
  end

  describe "refresh_doctor_note_review/2 — enum normalization" do
    test "urgency level outside the allowed set normalizes to routine" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})
      put_assessment_response({:ok, %{"urgency" => %{"level" => "critical"}}})

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert updated.ai_review_payload["urgency"]["level"] == "routine"
    end

    test "evidence_strength outside the allowed set normalizes to weak" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})

      put_assessment_response(
        {:ok,
         %{
           "independent_impression" => %{"summary" => "x", "evidence_strength" => "definitely"}
         }}
      )

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert updated.ai_review_payload["independent_impression"]["evidence_strength"] == "weak"
    end

    test "differential diagnosis likelihood outside the allowed set normalizes to possible" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})

      put_assessment_response(
        {:ok,
         %{"differential_diagnoses" => [%{"condition" => "Flu", "likelihood" => "definitely"}]}}
      )

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert [%{"likelihood" => "possible"}] = updated.ai_review_payload["differential_diagnoses"]
    end

    test "next step type outside the allowed set normalizes to other" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})

      put_assessment_response(
        {:ok, %{"recommended_next_steps" => [%{"action" => "Do something", "type" => "surgery"}]}}
      )

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert [%{"type" => "other"}] = updated.ai_review_payload["recommended_next_steps"]
    end

    test "next step priority outside the allowed set normalizes to routine" do
      doctor_note = doctor_note_fixture(%{diagnosis: nil, impression: nil})

      put_assessment_response(
        {:ok,
         %{"recommended_next_steps" => [%{"action" => "Do something", "priority" => "asap"}]}}
      )

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert [%{"priority" => "routine"}] = updated.ai_review_payload["recommended_next_steps"]
    end
  end

  describe "refresh_doctor_note_review/2 — closeness-score validation" do
    test "clamps an out-of-range score into 0..100" do
      doctor_note = doctor_note_fixture(%{diagnosis: "Pneumonia"})
      put_assessment_response(valid_assessment())
      put_closeness_response(valid_closeness(140))

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert updated.ai_review_payload["closeness"]["score"] == 100
    end

    test "a missing/invalid score normalizes to nil rather than crashing" do
      doctor_note = doctor_note_fixture(%{diagnosis: "Pneumonia"})
      put_assessment_response(valid_assessment())
      put_closeness_response({:ok, %{"explanation" => "no numeric score supplied"}})

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      closeness = updated.ai_review_payload["closeness"]
      assert closeness["status"] == "computed"
      assert closeness["score"] == nil
    end

    test "accepts a float score, rounding and clamping it" do
      doctor_note = doctor_note_fixture(%{diagnosis: "Pneumonia"})
      put_assessment_response(valid_assessment())
      put_closeness_response(valid_closeness(82.6))

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert updated.ai_review_payload["closeness"]["score"] == 83
    end

    test "accepts a numeric string score" do
      doctor_note = doctor_note_fixture(%{diagnosis: "Pneumonia"})
      put_assessment_response(valid_assessment())
      put_closeness_response(valid_closeness("65"))

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert updated.ai_review_payload["closeness"]["score"] == 65
    end

    test "a non-numeric string score normalizes to nil rather than crashing" do
      doctor_note = doctor_note_fixture(%{diagnosis: "Pneumonia"})
      put_assessment_response(valid_assessment())
      put_closeness_response(valid_closeness("not-a-number"))

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert updated.ai_review_payload["closeness"]["score"] == nil
    end

    test "clamps a below-range score up to 0" do
      doctor_note = doctor_note_fixture(%{diagnosis: "Pneumonia"})
      put_assessment_response(valid_assessment())
      put_closeness_response(valid_closeness(-15))

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert updated.ai_review_payload["closeness"]["score"] == 0
    end

    test "passes through a non-string, non-nil explanation unchanged" do
      doctor_note = doctor_note_fixture(%{diagnosis: "Pneumonia"})
      put_assessment_response(valid_assessment())
      put_closeness_response({:ok, %{"score" => 70, "explanation" => 42}})

      assert {:ok, updated} = AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)
      assert updated.ai_review_payload["closeness"]["explanation"] == 42
    end
  end

  describe "refresh_doctor_note_review/2 — external-service failure paths" do
    test "an unavailable/timed-out service returns a recoverable error and writes nothing" do
      doctor_note = doctor_note_fixture()
      put_assessment_response({:error, "AI request failed: timeout"})

      assert {:error, _reason} =
               AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)

      reloaded = DoctorNotes.get_doctor_note!(doctor_note.id)
      assert reloaded.ai_review_status == "pending"
      assert reloaded.ai_review_payload == %{}
      assert is_nil(reloaded.ai_review_generated_at)
    end

    test "an invalid JSON response from the AI returns a recoverable error and writes nothing" do
      doctor_note = doctor_note_fixture()
      put_assessment_response({:error, "AI returned invalid JSON: unexpected token"})

      assert {:error, _reason} =
               AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)

      reloaded = DoctorNotes.get_doctor_note!(doctor_note.id)
      assert reloaded.ai_review_status == "pending"
    end

    test "a refused request returns a recoverable error and writes nothing" do
      doctor_note = doctor_note_fixture()
      put_assessment_response({:error, "AI request was rejected: content policy violation"})

      assert {:error, _reason} =
               AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)

      reloaded = DoctorNotes.get_doctor_note!(doctor_note.id)
      assert reloaded.ai_review_status == "pending"
    end

    test "a failure on the second (closeness) call also writes nothing, even though the first call succeeded" do
      doctor_note = doctor_note_fixture(%{diagnosis: "Pneumonia"})
      put_assessment_response(valid_assessment())
      put_closeness_response({:error, "AI request failed: timeout"})

      assert {:error, _reason} =
               AIDocReviewer.refresh_doctor_note_review(doctor_note, FakeAIClient)

      reloaded = DoctorNotes.get_doctor_note!(doctor_note.id)
      assert reloaded.ai_review_status == "pending"
      assert reloaded.ai_review_payload == %{}
    end
  end
end
