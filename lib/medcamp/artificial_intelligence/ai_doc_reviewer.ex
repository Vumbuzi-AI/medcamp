defmodule Medcamp.AIDocReviewer do
  @moduledoc """
  On-demand clinical decision support for a `Medcamp.DoctorNotes.DoctorNote`.
  Forms an independent impression before revealing the doctor's diagnosis
  (blind-then-reveal — see `docs/ai_doc_reviewer.md`), then scores their
  alignment and shows it to the doctor as a quick indicator. Any AI failure
  leaves the note untouched.
  """

  alias Medcamp.ArtificialIntelligence.OpenAI
  alias Medcamp.DoctorNotes
  alias Medcamp.DoctorNotes.DoctorNote
  alias Medcamp.DrugAllocations
  alias Medcamp.LabResults
  alias Medcamp.Patients.Patient
  alias Medcamp.Repo
  alias Medcamp.Triages

  @source_openai "openai_v1"
  @disclaimer "AI-generated second opinion for clinician review only. Does not replace clinical judgement, examination, or established treatment protocols."
  @schema_version "2.0"

  @urgency_levels ["routine", "urgent", "emergency"]
  @likelihoods ["most_likely", "possible", "less_likely"]
  @evidence_strengths ["weak", "moderate", "strong"]
  @next_step_types ["investigation", "referral", "monitoring", "treatment", "other"]

  @doc """
  Builds the AI context: `:blind_context` (no patient identifiers at all,
  only age/gender — safe to reveal before a diagnosis exists) plus
  `:doctor_assessment` (used afterwards to score alignment). Record-keyed
  sections (`triage_history`, `prior_notes`, lab history, prescriptions)
  are maps keyed by real database id, so the AI can cite a checkable
  source for each finding.
  """
  def build_context_for_doctor_note(%DoctorNote{} = doctor_note) do
    doctor_note = Repo.preload(doctor_note, [:patient, :patient_visit])
    patient_id = doctor_note.patient_id

    prior_notes =
      DoctorNotes.doctor_notes_for_patient(patient_id)
      |> Enum.reject(&(&1.id == doctor_note.id))

    triages = Triages.list_triages_by_patient(patient_id)
    patient_lab_history = LabResults.list_lab_results_for_patient(patient_id)
    current_note_lab_results = LabResults.list_lab_results_for_doctor_note(doctor_note.id)
    drug_allocations = DrugAllocations.list_drug_allocations_for_a_doctor_note(doctor_note.id)

    %{
      blind_context: %{
        patient_context: normalize_patient(doctor_note.patient),
        triage_history: index_by_id(triages, &normalize_triage/1),
        current_presentation: normalize_current_presentation(doctor_note),
        prior_notes: index_by_id(prior_notes, &normalize_prior_note/1),
        patient_lab_history: index_by_id(patient_lab_history, &normalize_lab_result/1),
        current_note_lab_results: index_by_id(current_note_lab_results, &normalize_lab_result/1),
        existing_prescriptions: index_by_id(drug_allocations, &normalize_drug_allocation/1)
      },
      doctor_assessment: normalize_doctor_assessment(doctor_note)
    }
  end

  defp index_by_id(records, normalize_fun) do
    Map.new(records, fn record -> {to_string(record.id), normalize_fun.(record)} end)
  end

  @doc """
  Runs the full review and persists it. Returns `{:ok, doctor_note}`, or
  `{:error, reason}` on any AI failure — writing nothing in that case.
  `ai_client` defaults to the real OpenAI wrapper; tests pass a fake.
  """
  def refresh_doctor_note_review(doctor_note, ai_client \\ OpenAI)

  def refresh_doctor_note_review(%DoctorNote{} = doctor_note, ai_client) do
    context = build_context_for_doctor_note(doctor_note)

    with {:ok, assessment} <- generate_assessment(context.blind_context, ai_client),
         {:ok, closeness} <-
           generate_closeness(assessment, context.doctor_assessment, ai_client) do
      payload = finalize_payload(assessment, closeness)

      doctor_note
      |> DoctorNote.ai_review_changeset(%{
        ai_review_payload: payload,
        ai_review_status: "completed",
        ai_review_generated_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.update()
    end
  end

  def refresh_doctor_note_review(doctor_note_id, ai_client) when is_integer(doctor_note_id) do
    DoctorNotes.get_doctor_note!(doctor_note_id)
    |> refresh_doctor_note_review(ai_client)
  end

  defp generate_assessment(blind_context, ai_client) do
    case ai_client.request_json_to_gpt(
           assessment_system_prompt(),
           assessment_user_prompt(blind_context)
         ) do
      {:ok, payload} -> {:ok, normalize_assessment_response(payload)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp assessment_system_prompt do
    """
    You are a senior clinician giving a second opinion inside a hospital
    system. A colleague is going to search for tailored guidance on a case
    they are already handling — think of yourself as a well-informed,
    case-specific reference lookup, not an authority overriding their
    judgement.

    Input shape:
    - The case data is organized into keyed sections: "patient_context",
      "triage_history", "current_presentation", "prior_notes",
      "patient_lab_history", "current_note_lab_results",
      "existing_prescriptions". Where a section is an object of objects,
      each entry's key is the real database id of that record (a triage
      id, a prior note id, a lab result id, a prescription id) — use these
      exact ids when citing sources.

    Core task:
    - Decide whether the supplied context is sufficient to form a
      reliable, safe review. If it is not, say so plainly and name exactly
      what's missing rather than guessing (see "data_quality" below).
    - Form your own independent clinical impression, a short case summary,
      and an urgency assessment with any red flags.
    - Propose a ranked differential (not just one diagnosis) and
      recommended next steps (investigations, referrals, monitoring,
      treatment).
    - Propose medication options worth considering, drawing on general
      medical knowledge (not limited to any specific hospital formulary),
      and separately flag allergy conflicts, interactions, or concerns
      with already-prescribed medication.
    - List direct questions you would ask the treating clinician if you
      could, and concrete "if X happens, do Y" safety-netting advice.

    Safety rules:
    - You have not examined the patient and have less context than the
      treating doctor. Write as a second opinion to consider, not an
      instruction to follow.
    - Do not invent findings, values, or history not present in the input.
    - Return JSON only, no markdown or code fences.

    Source-ref rule:
    - Every "source_refs" list must cite real ids from the input,
      formatted as "triage.<id>", "prior_notes.<id>", "labs.<id>",
      "prescriptions.<id>", or "current.<field_name>" (e.g.
      "current.symptoms"). Never invent an id or cite a record that isn't
      in the input.

    Insufficient-data rule:
    - When the note is missing information needed for a reliable review
      (e.g. investigations, past medical history, vitals), set
      "data_quality.sufficient_for_review" to false and phrase each
      "missing_critical_information" entry as a direct, actionable ask the
      doctor can act on immediately — e.g. "Add the patient's
      investigation results before relying on this review" rather than a
      passive "no investigations were provided."

    Questions rule:
    - Each "questions_for_clinician" entry must be a literal question
      (ends with "?"), not a restated observation.

    Safety-netting rule:
    - Each "safety_netting[].trigger" must be a bare condition phrase, not
      a full sentence and not starting with "if"/"when" — the app displays
      it as "If <trigger>:". Write "the fever persists beyond 48 hours",
      not "If the fever persists beyond 48 hours".

    Reasoning rules:
    - When several pieces of context point toward the same picture,
      describe the pattern rather than listing disconnected observations.
      When something is isolated or minor, say so plainly rather than
      dwelling on it.
    - Use the full triage and prior-note history when it's relevant (e.g.
      a recurring or chronic pattern) — don't rely on only the most recent
      entry if older ones change the picture.
    - Use cautious, calibrated wording — "may be consistent with", "could
      represent", "would be worth considering" — rather than asserting
      certainty you don't have.
    - Avoid empty, generic phrasing. Prefer specific wording tied to what
      was actually supplied over boilerplate that could apply to any case.
    - Use short sentences and common words. Avoid jargon unless it already
      appears in the input; if a technical term is necessary, make its
      meaning clear from the surrounding sentence.

    Required JSON shape:
    {
      "case_summary": "string - 1-3 sentences summarizing the case",
      "data_quality": {
        "sufficient_for_review": true or false,
        "missing_critical_information": ["string", ...],
        "conflicting_information": ["string", ...]
      },
      "urgency": {
        "level": "routine" | "urgent" | "emergency",
        "red_flags": [
          {"finding": "string", "why_it_matters": "string", "suggested_action": "string", "source_refs": ["string", ...]}
        ]
      },
      "independent_impression": {
        "summary": "string - 2-4 sentences",
        "evidence_strength": "weak" | "moderate" | "strong",
        "source_refs": ["string", ...]
      },
      "differential_diagnoses": [
        {"condition": "string", "likelihood": "most_likely" | "possible" | "less_likely", "rationale": "string", "evidence_for": ["string"], "evidence_against": ["string"], "source_refs": ["string"]}
      ],
      "recommended_next_steps": [
        {"type": "investigation" | "referral" | "monitoring" | "treatment" | "other", "priority": "routine" | "urgent" | "emergency", "action": "string", "reason": "string", "source_refs": ["string"]}
      ],
      "medication_review": {
        "allergy_conflicts": ["string", ...],
        "interaction_warnings": ["string", ...],
        "existing_medication_concerns": ["string", ...],
        "options_to_consider": [
          {"generic_name": "string", "indication": "string", "rationale": "string", "preconditions": ["string", ...], "contraindications_or_cautions": ["string", ...], "monitoring": ["string", ...], "dose": "string", "source_refs": ["string"]}
        ]
      },
      "questions_for_clinician": ["string ending in ?", ...],
      "safety_netting": [
        {"trigger": "string", "action": "string"}
      ],
      "limitations": ["string", ...]
    }

    If there is not enough information to form a meaningful impression, say
    so plainly in "independent_impression.summary" and "case_summary", set
    "data_quality.sufficient_for_review" to false, return an empty
    "differential_diagnoses" and "options_to_consider", and use
    "limitations"/"missing_critical_information" to explain what's missing.
    """
  end

  defp assessment_user_prompt(blind_context) do
    """
    Form an independent impression and possible drug options from this case.
    You have not been shown any diagnosis — reason only from what's below.

    #{Jason.encode!(blind_context, pretty: true)}
    """
  end

  defp normalize_assessment_response(payload) do
    %{
      "schema_version" => @schema_version,
      "case_summary" =>
        Map.get(payload, "case_summary")
        |> presence_or("Not enough information was available to summarize this case."),
      "data_quality" => normalize_data_quality(Map.get(payload, "data_quality")),
      "urgency" => normalize_urgency(Map.get(payload, "urgency")),
      "independent_impression" =>
        normalize_independent_impression(Map.get(payload, "independent_impression")),
      "differential_diagnoses" =>
        normalize_differential_diagnoses(Map.get(payload, "differential_diagnoses")),
      "recommended_next_steps" =>
        normalize_next_steps(Map.get(payload, "recommended_next_steps")),
      "medication_review" => normalize_medication_review(Map.get(payload, "medication_review")),
      "questions_for_clinician" =>
        normalize_string_list(Map.get(payload, "questions_for_clinician")),
      "safety_netting" => normalize_safety_netting(Map.get(payload, "safety_netting")),
      "limitations" => normalize_string_list(Map.get(payload, "limitations"))
    }
  end

  defp normalize_data_quality(data) when is_map(data) do
    %{
      "sufficient_for_review" => normalize_boolean(Map.get(data, "sufficient_for_review"), true),
      "missing_critical_information" =>
        normalize_string_list(Map.get(data, "missing_critical_information")),
      "conflicting_information" => normalize_string_list(Map.get(data, "conflicting_information"))
    }
  end

  defp normalize_data_quality(_) do
    %{
      "sufficient_for_review" => true,
      "missing_critical_information" => [],
      "conflicting_information" => []
    }
  end

  defp normalize_urgency(data) when is_map(data) do
    %{
      "level" => normalize_enum(Map.get(data, "level"), @urgency_levels, "routine"),
      "red_flags" => normalize_red_flags(Map.get(data, "red_flags"))
    }
  end

  defp normalize_urgency(_), do: %{"level" => "routine", "red_flags" => []}

  defp normalize_red_flags(flags) when is_list(flags) do
    flags
    |> Enum.filter(&is_map/1)
    |> Enum.map(fn flag ->
      %{
        "finding" => Map.get(flag, "finding") |> presence_or(nil),
        "why_it_matters" => Map.get(flag, "why_it_matters") |> presence_or(nil),
        "suggested_action" => Map.get(flag, "suggested_action") |> presence_or(nil),
        "source_refs" => normalize_string_list(Map.get(flag, "source_refs"))
      }
    end)
    |> Enum.reject(&is_nil(&1["finding"]))
  end

  defp normalize_red_flags(_), do: []

  defp normalize_independent_impression(data) when is_map(data) do
    %{
      "summary" =>
        Map.get(data, "summary")
        |> presence_or("Not enough information was available to form an independent impression."),
      "evidence_strength" =>
        normalize_enum(Map.get(data, "evidence_strength"), @evidence_strengths, "weak"),
      "source_refs" => normalize_string_list(Map.get(data, "source_refs"))
    }
  end

  defp normalize_independent_impression(_) do
    %{
      "summary" => "Not enough information was available to form an independent impression.",
      "evidence_strength" => "weak",
      "source_refs" => []
    }
  end

  defp normalize_differential_diagnoses(diagnoses) when is_list(diagnoses) do
    diagnoses
    |> Enum.filter(&is_map/1)
    |> Enum.map(fn dx ->
      %{
        "condition" => Map.get(dx, "condition") |> presence_or(nil),
        "likelihood" => normalize_enum(Map.get(dx, "likelihood"), @likelihoods, "possible"),
        "rationale" => Map.get(dx, "rationale") |> presence_or(nil),
        "evidence_for" => normalize_string_list(Map.get(dx, "evidence_for")),
        "evidence_against" => normalize_string_list(Map.get(dx, "evidence_against")),
        "source_refs" => normalize_string_list(Map.get(dx, "source_refs"))
      }
    end)
    |> Enum.reject(&is_nil(&1["condition"]))
  end

  defp normalize_differential_diagnoses(_), do: []

  defp normalize_next_steps(steps) when is_list(steps) do
    steps
    |> Enum.filter(&is_map/1)
    |> Enum.map(fn step ->
      %{
        "type" => normalize_enum(Map.get(step, "type"), @next_step_types, "other"),
        "priority" => normalize_enum(Map.get(step, "priority"), @urgency_levels, "routine"),
        "action" => Map.get(step, "action") |> presence_or(nil),
        "reason" => Map.get(step, "reason") |> presence_or(nil),
        "source_refs" => normalize_string_list(Map.get(step, "source_refs"))
      }
    end)
    |> Enum.reject(&is_nil(&1["action"]))
  end

  defp normalize_next_steps(_), do: []

  defp normalize_medication_review(data) when is_map(data) do
    %{
      "allergy_conflicts" => normalize_string_list(Map.get(data, "allergy_conflicts")),
      "interaction_warnings" => normalize_string_list(Map.get(data, "interaction_warnings")),
      "existing_medication_concerns" =>
        normalize_string_list(Map.get(data, "existing_medication_concerns")),
      "options_to_consider" => normalize_medication_options(Map.get(data, "options_to_consider"))
    }
  end

  defp normalize_medication_review(_) do
    %{
      "allergy_conflicts" => [],
      "interaction_warnings" => [],
      "existing_medication_concerns" => [],
      "options_to_consider" => []
    }
  end

  defp normalize_medication_options(options) when is_list(options) do
    options
    |> Enum.filter(&is_map/1)
    |> Enum.map(fn option ->
      %{
        "generic_name" => Map.get(option, "generic_name") |> presence_or(nil),
        "indication" => Map.get(option, "indication") |> presence_or(nil),
        "rationale" => Map.get(option, "rationale") |> presence_or(nil),
        "preconditions" => normalize_string_list(Map.get(option, "preconditions")),
        "contraindications_or_cautions" =>
          normalize_string_list(Map.get(option, "contraindications_or_cautions")),
        "monitoring" => normalize_string_list(Map.get(option, "monitoring")),
        "dose" => Map.get(option, "dose") |> presence_or(nil),
        "source_refs" => normalize_string_list(Map.get(option, "source_refs"))
      }
    end)
    |> Enum.reject(&is_nil(&1["generic_name"]))
  end

  defp normalize_medication_options(_), do: []

  defp normalize_safety_netting(items) when is_list(items) do
    items
    |> Enum.filter(&is_map/1)
    |> Enum.map(fn item ->
      %{
        "trigger" => Map.get(item, "trigger") |> presence_or(nil) |> strip_leading_conditional(),
        "action" => Map.get(item, "action") |> presence_or(nil)
      }
    end)
    |> Enum.reject(&is_nil(&1["trigger"]))
  end

  defp normalize_safety_netting(_), do: []

  defp normalize_boolean(value, _default) when is_boolean(value), do: value
  defp normalize_boolean(_value, default), do: default

  defp normalize_enum(value, allowed, default) when is_binary(value) do
    if value in allowed, do: value, else: default
  end

  defp normalize_enum(_value, _allowed, default), do: default

  defp generate_closeness(assessment, doctor_assessment, ai_client) do
    if blank?(doctor_assessment.diagnosis) and blank?(doctor_assessment.impression) do
      {:ok, %{"status" => "not_yet_decided", "score" => nil, "explanation" => nil}}
    else
      do_generate_closeness(assessment, doctor_assessment, ai_client)
    end
  end

  defp blank?(nil), do: true
  defp blank?(value) when is_binary(value), do: String.trim(value) == ""

  defp do_generate_closeness(assessment, doctor_assessment, ai_client) do
    case ai_client.request_json_to_gpt(
           closeness_system_prompt(),
           closeness_user_prompt(assessment, doctor_assessment)
         ) do
      {:ok, payload} -> {:ok, normalize_closeness_response(payload)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp closeness_system_prompt do
    """
    You previously formed an independent clinical impression without seeing
    the treating doctor's diagnosis. You will now be shown that diagnosis.
    Rate how closely your independent impression aligns with it.

    Rules:
    - This is an alignment/overlap signal for internal quality tracking, not
      a verdict on whether the doctor is right. The doctor has context you
      do not (examination findings, things not written down).
    - "score" must be an integer from 0 to 100, where 100 means your
      impression and the doctor's diagnosis describe essentially the same
      clinical picture, and 0 means they point in entirely different
      directions.
    - "explanation" must briefly state what specifically aligns and what
      specifically diverges, grounded only in the impression and diagnosis
      given — avoid generic phrasing like "there is some overlap" without
      saying what the overlap is.
    - Use short sentences and plain, common words rather than clinical
      jargon, so the explanation is quick to scan.
    - Return JSON only, no markdown or code fences.

    Required JSON shape:
    {
      "score": "integer 0-100",
      "explanation": "string, 1-3 sentences"
    }
    """
  end

  defp closeness_user_prompt(assessment, doctor_assessment) do
    """
    Your independent impression was:
    #{assessment["independent_impression"]["summary"]}

    The treating doctor's documented diagnosis/impression is:
    #{Jason.encode!(doctor_assessment, pretty: true)}

    Rate the alignment.
    """
  end

  defp normalize_closeness_response(payload) do
    score =
      case Map.get(payload, "score") do
        score when is_integer(score) -> clamp(score, 0, 100)
        score when is_float(score) -> score |> round() |> clamp(0, 100)
        score when is_binary(score) -> score |> parse_integer() |> clamp(0, 100)
        _ -> nil
      end

    %{
      "status" => "computed",
      "score" => score,
      "explanation" => Map.get(payload, "explanation") |> presence_or(nil)
    }
  end

  defp clamp(nil, _min, _max), do: nil
  defp clamp(value, min, _max) when value < min, do: min
  defp clamp(value, _min, max) when value > max, do: max
  defp clamp(value, _min, _max), do: value

  defp parse_integer(binary) do
    case Integer.parse(binary) do
      {int, _rest} -> int
      :error -> nil
    end
  end

  defp finalize_payload(assessment, closeness) do
    Map.merge(assessment, %{
      "closeness" => closeness,
      "disclaimer" => @disclaimer,
      "source" => @source_openai,
      "generated_at" => DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    })
  end

  defp normalize_patient(nil), do: %{}

  defp normalize_patient(patient) do
    %{
      "age" => patient.age || Patient.calculate_age(patient.date_of_birth),
      "gender" => patient.gender
    }
  end

  defp normalize_triage(nil), do: %{}

  defp normalize_triage(triage) do
    %{
      "temperature" => triage.temperature,
      "blood_pressure" => triage.blood_pressure,
      "pulse_rate" => triage.pulse_rate,
      "oxygen_saturation" => triage.oxygen_saturation,
      "allergies" => triage.allergies,
      "emergency_scale" => triage.emergency_scale,
      "triage_notes" => triage.triage_notes
    }
  end

  defp normalize_current_presentation(doctor_note) do
    %{
      "reason_for_consultation" => doctor_note.reason_for_consulatation,
      "clinical_notes" => doctor_note.clinical_notes,
      "past_medical_history" => doctor_note.past_medical_history,
      "impression" => doctor_note.impression,
      "management" => doctor_note.management,
      "investigations" => doctor_note.investigations
    }
  end

  # Prior notes are established history, not "the current guess" — safe to
  # include in full, diagnosis and all. Excludes ai_review_* fields: those
  # are the prior note's own AI-review metadata, not clinical content, and
  # including them would leak an old closeness score into this review.
  defp normalize_prior_note(note) do
    %{
      "date" => note.date,
      "reason_for_consultation" => note.reason_for_consulatation,
      "symptoms" => note.symptoms,
      "investigations" => note.investigations,
      "past_medical_history" => note.past_medical_history,
      "impression" => note.impression,
      "diagnosis" => note.diagnosis,
      "diagnosis_icd_code" => note.diagnosis_icd_code,
      "management" => note.management,
      "clinical_notes" => note.clinical_notes,
      "lifestyle_recommendations" => note.lifestyle_recommendations,
      "lab_imaging_request" => note.lab_imaging_request,
      "prescribed_medication" => note.prescribed_medication,
      "last_period_date" => note.last_period_date
    }
  end

  defp normalize_lab_result(lab_result) do
    %{
      "description" => lab_result.description,
      "urgency" => lab_result.urgency,
      "report_complete" => lab_result.report_complete,
      "date_of_test" => lab_result.date_of_test,
      "sample_collection_date" => lab_result.sample_collection_date,
      "test_findings" => lab_result.test_findings,
      "tests" => Enum.map(lab_result.tests || [], &%{"name" => &1.name, "result" => &1.result}),
      "prior_ai_interpretation" =>
        Map.get(lab_result.interpretation_payload || %{}, "clinical_interpretation")
    }
  end

  defp normalize_drug_allocation(drug_allocation) do
    %{
      "prescription" => drug_allocation.prescription,
      "has_been_assigned" => drug_allocation.has_been_assigned
    }
  end

  defp normalize_doctor_assessment(doctor_note) do
    %{
      diagnosis: doctor_note.diagnosis,
      diagnosis_icd_code: doctor_note.diagnosis_icd_code,
      impression: doctor_note.impression,
      management: doctor_note.management,
      prescribed_medication: doctor_note.prescribed_medication
    }
  end

  defp normalize_string_list(value) when is_list(value) do
    value
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(String.trim(&1) == ""))
  end

  # If the AI writes a single sentence instead of an array, wrap it rather
  # than silently dropping the content.
  defp normalize_string_list(value) when is_binary(value), do: normalize_string_list([value])

  defp normalize_string_list(_), do: []

  defp presence_or(nil, default), do: default
  defp presence_or("", default), do: default
  defp presence_or(value, _default) when is_binary(value), do: String.trim(value)
  defp presence_or(value, _default), do: value

  # The template renders safety-netting triggers as "If <trigger>:" — strip
  # a redundant leading "if"/"when" so we never double up regardless of how
  # the AI phrases it, even though the prompt also asks for a bare phrase.
  defp strip_leading_conditional(nil), do: nil

  defp strip_leading_conditional(text) when is_binary(text) do
    Regex.replace(~r/^(if|when)\s+/i, text, "")
  end

  defp strip_leading_conditional(value), do: value
end
