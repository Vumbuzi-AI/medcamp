defmodule Medcamp.LabResults.InterpretationBuilder do
  @moduledoc """
  Builds a doctor-friendly interpretation snapshot for a lab request.

  The service prefers structured lab test entry data and falls back to the
  embedded `lab_results.tests` payload when needed. It uses the OpenAI wrapper
  when available and always falls back to a deterministic local summary so lab
  workflows are never blocked.
  """

  alias Medcamp.ArtificialIntelligence.OpenAI
  alias Medcamp.DoctorNotes
  alias Medcamp.LabResults.LabResult
  alias Medcamp.LabTestTemplates
  alias Medcamp.Patients.Patient
  alias Medcamp.Repo
  alias Medcamp.Triages

  @source_openai "openai_v1"
  @source_fallback "rules_fallback_v1"
  @default_disclaimer "For clinician review only. Correlate with history, examination, and previous results."

  def build_context_for_lab_result(%LabResult{} = lab_result) do
    lab_result =
      lab_result
      |> Repo.preload([:doctor_note, :patient, :doctor, :lab_technician])

    latest_doctor_note =
      case lab_result.doctor_note do
        nil -> DoctorNotes.doctor_notes_for_patient(lab_result.patient_id) |> List.first()
        doctor_note -> doctor_note
      end

    latest_triage = Triages.most_recent_triage(lab_result.patient_id)
    test_entries = LabTestTemplates.list_entries_for_lab_result(lab_result.id)

    normalized_results =
      case normalize_structured_entries(test_entries) do
        [] -> normalize_embedded_tests(lab_result.tests || [])
        entries -> entries
      end

    abnormal_findings = Enum.filter(normalized_results, &abnormal_flag?(&1[:flag]))
    critical_count = Enum.count(normalized_results, &critical_flag?(&1[:flag]))

    %{
      lab_result: %{
        id: lab_result.id,
        description: lab_result.description,
        urgency: lab_result.urgency,
        report_complete: lab_result.report_complete,
        requested_at: lab_result.inserted_at,
        requested_tests: Enum.map(lab_result.tests || [], & &1.name)
      },
      patient_context: normalize_patient_context(lab_result.patient),
      doctor_note_context: normalize_doctor_note(latest_doctor_note),
      triage_context: normalize_triage(latest_triage),
      normalized_results: normalized_results,
      lab_summary: %{
        abnormal_count: length(abnormal_findings),
        critical_count: critical_count,
        tests_reviewed:
          normalized_results
          |> Enum.map(& &1[:test])
          |> Enum.reject(&is_nil/1)
          |> Enum.uniq()
      }
    }
  end

  def generate_payload(%LabResult{} = lab_result) do
    context = build_context_for_lab_result(lab_result)

    case maybe_generate_with_openai(context) do
      {:ok, payload} ->
        finalize_payload(payload, context, @source_openai)

      {:error, reason} ->
        fallback_payload(context, reason)
    end
  end

  defp maybe_generate_with_openai(context) do
    OpenAI.request_json_to_gpt(system_prompt(), user_prompt(context))
  end

  defp system_prompt do
    """
    You are generating a senior clinician-support lab interpretation for a hospital system.
    Your output is for a doctor who wants a concise but clinically useful review of the available results.

    Core task:
    - Review only the supplied laboratory data and context.
    - Identify the most clinically important abnormal or critical findings.
    - Summarize overall pattern, likely significance, and immediate review priorities.
    - Sound like a careful senior clinician supporting another clinician.
    - Write in clear, plain English so the summary is readable even to a non-specialist.

    Safety rules:
    - Do not diagnose.
    - Do not recommend treatment, medication, procedures, or disposition.
    - Do not invent values, symptoms, findings, ranges, trends, differentials, or context not present in the input.
    - If context is missing, say so briefly and continue with the available data.
    - Raw lab values and flags remain the source of truth.
    - Use cautious wording such as "may be consistent with", "could fit", "can be seen with", or "should be correlated clinically".
    - Do not overstate isolated mild abnormalities.
    - Do not describe a relationship between labs and symptoms unless both are present in the input.
    - Return JSON only.
    - Do not wrap the JSON in markdown or code fences.

    Reasoning rules:
    - Prioritize critical abnormalities over non-critical abnormalities.
    - When several abnormalities appear related, comment on the pattern rather than listing disconnected one-liners.
    - When abnormalities are isolated or minor, say that clearly.
    - Use `patient_context` when clinically relevant, especially age, sex/gender, and life stage.
    - Let age, sex/gender, and date of birth influence interpretation only when they materially affect the meaning or significance of the findings.
    - Do not force demographic commentary into every case; mention it only when it helps interpretation.
    - Mention missing trend data, differential counts, or complementary context only as a limitation, not as an order or treatment plan.
    - Prefer the specific analyte/field label when naming an abnormal finding; use the broader test name only when needed for context.
    - If degree matters and is directly supported by the value versus the stated reference range or flag, describe it as mild, moderate, marked, or critical. Do not guess severity when it is unclear.
    - Use short sentences and common words where possible.
    - Avoid dense jargon and abbreviations unless they are already present in the input.
    - If you must use a medical term, make the meaning obvious from the sentence.

    Output rules:
    - `status` must be one of: "pending", "completed".
    - `doctor_note_context` and `triage_context` must echo only supplied context and must not be enriched or paraphrased.
    - `lab_summary` should align with the supplied results and reviewed tests.
    - `abnormal_findings` must include only abnormal or critical findings.
    - Each `abnormal_findings[].doctor_note` must be a substantive clinician-facing sentence that states:
      the direction of abnormality, approximate significance if supported, and the most relevant clinical correlation point or limitation.
    - Each `abnormal_findings[].doctor_note` should be easy to read on first pass and should avoid unnecessary technical phrasing.
    - `clinical_interpretation` must be 2 to 4 short doctor-facing lines when results are completed.
    - `clinical_interpretation` should usually cover:
      overall pattern or acuity,
      the most important abnormal findings and whether they appear isolated or part of a broader pattern,
      any direct correlation with supplied note or triage context,
      and an important limitation when relevant.
    - `clinical_interpretation` should be clear, calm, and readable to both clinicians and non-clinicians.
    - `recommended_attention` must be 2 to 4 short operational clinician-review lines.
    - `recommended_attention` may include actions such as review, correlate, compare with prior results, verify trends, or prioritize critical values.
    - `recommended_attention` must not include treatment instructions.
    - `recommended_attention` should use simple action wording, not specialist shorthand.
    - `disclaimer` must state that this is for clinician review only.
    - Avoid empty generic phrasing. Prefer specific, data-linked wording over boilerplate.

    If there are no completed lab values:
    - set `status` to "pending"
    - keep `abnormal_findings` empty
    - make `clinical_interpretation` explain that results are awaited
    - make `recommended_attention` say review should follow once values are available

    Required JSON shape:
    {
      "generated_at": "ISO-8601 string",
      "source": "openai_v1",
      "status": "pending|completed",
      "doctor_note_context": {
        "doctor_note_id": "number|null",
        "diagnosis": "string|null",
        "symptoms": "string|null",
        "clinical_notes": "string|null"
      },
      "triage_context": {
        "triage_id": "number|null",
        "temperature": "number|string|null",
        "blood_pressure": "string|null",
        "pulse_rate": "number|string|null",
        "oxygen_saturation": "number|string|null",
        "allergies": "string|null",
        "emergency_scale": "string|null"
      },
      "lab_summary": {
        "abnormal_count": "number",
        "critical_count": "number",
        "tests_reviewed": ["string"]
      },
      "abnormal_findings": [
        {
          "test": "string",
          "value": "string|null",
          "unit": "string|null",
          "flag": "string|null",
          "reference_range": "string|null",
          "doctor_note": "string"
        }
      ],
      "clinical_interpretation": ["string"],
      "recommended_attention": ["string"],
      "disclaimer": "string"
    }
    """
  end

  defp user_prompt(context) do
    """
    Build the lab interpretation payload from this context.

    Grounding instructions:
    - Treat `normalized_results` as the authoritative list of completed lab values to interpret.
    - Treat `lab_summary` as a summary aid, but ensure the narrative remains consistent with `normalized_results`.
    - Use `patient_context` as part of the interpretation context. Age, date of birth, and gender are valid clinical parameters when relevant.
    - Use `doctor_note_context` and `triage_context` only for explicit correlation, not for inference beyond the supplied text.
    - If `normalized_results` is empty, return a pending interpretation.

    #{Jason.encode!(context, pretty: true)}
    """
  end

  defp finalize_payload(payload, context, source) do
    payload
    |> Map.put_new(
      "generated_at",
      DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
    )
    |> Map.put("source", source)
    |> Map.put("status", inferred_status(context))
    |> Map.put(
      "doctor_note_context",
      payload_context(payload, "doctor_note_context", context[:doctor_note_context])
    )
    |> Map.put(
      "triage_context",
      payload_context(payload, "triage_context", context[:triage_context])
    )
    |> Map.put(
      "lab_summary",
      payload_context(payload, "lab_summary", stringify_keys(context[:lab_summary]))
    )
    |> Map.update(
      "abnormal_findings",
      fallback_abnormal_findings(context),
      &normalize_abnormal_findings/1
    )
    |> Map.update("clinical_interpretation", fallback_interpretation(context), &normalize_lines/1)
    |> Map.update("recommended_attention", fallback_attention(context), &normalize_lines/1)
    |> Map.put_new("disclaimer", @default_disclaimer)
  end

  defp payload_context(payload, key, fallback) do
    payload
    |> Map.get(key)
    |> case do
      value when is_map(value) -> stringify_keys(value)
      _ -> stringify_keys(fallback || %{})
    end
  end

  defp fallback_payload(context, reason) do
    %{
      "generated_at" => DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
      "source" => @source_fallback,
      "status" => inferred_status(context),
      "doctor_note_context" => stringify_keys(context[:doctor_note_context] || %{}),
      "triage_context" => stringify_keys(context[:triage_context] || %{}),
      "lab_summary" => stringify_keys(context[:lab_summary] || %{}),
      "abnormal_findings" => fallback_abnormal_findings(context),
      "clinical_interpretation" => fallback_interpretation(context),
      "recommended_attention" => fallback_attention(context),
      "disclaimer" => @default_disclaimer,
      "generation_note" => "AI summary fallback used: #{reason}"
    }
  end

  defp fallback_abnormal_findings(context) do
    context[:normalized_results]
    |> Enum.filter(&abnormal_flag?(&1[:flag]))
    |> Enum.map(fn finding ->
      %{
        "test" => finding[:label] || finding[:test],
        "value" => finding[:value],
        "unit" => finding[:unit],
        "flag" => finding[:flag],
        "reference_range" => finding[:reference_range],
        "doctor_note" => abnormal_note_for_finding(finding)
      }
    end)
  end

  defp fallback_interpretation(context) do
    results = context[:normalized_results] || []
    doctor_note = context[:doctor_note_context] || %{}
    triage = context[:triage_context] || %{}

    text_context =
      [
        doctor_note[:symptoms],
        doctor_note[:diagnosis],
        doctor_note[:clinical_notes],
        triage[:triage_notes]
      ]
      |> Enum.reject(&is_nil_or_blank/1)
      |> Enum.join(" ")
      |> String.downcase()

    cond do
      results == [] ->
        ["Lab request submitted. Interpretation will update once lab results are entered."]

      true ->
        [
          malaria_context_line(results, text_context),
          low_haemoglobin_line(results, text_context),
          high_wbc_line(results, text_context),
          urinary_line(results, text_context),
          generic_abnormal_line(context)
        ]
        |> Enum.reject(&is_nil_or_blank/1)
        |> case do
          [] ->
            [
              "Please review the abnormal values alongside the patient's symptoms, examination, and overall condition."
            ]

          lines ->
            lines
        end
    end
  end

  defp fallback_attention(context) do
    results = context[:normalized_results] || []

    attention =
      [
        if(Enum.any?(results, &critical_flag?(&1[:flag])),
          do: "Review critical values first and escalate promptly."
        ),
        if(Enum.any?(results, &abnormal_flag?(&1[:flag])),
          do:
            "Compare abnormal values with the latest symptoms, triage findings, and any earlier labs."
        ),
        if(results == [], do: "Wait for completed lab values before relying on this summary.")
      ]
      |> Enum.reject(&is_nil_or_blank/1)

    case attention do
      [] -> ["Read the lab values in the context of the patient's overall clinical picture."]
      lines -> lines
    end
  end

  defp normalize_structured_entries(entries) do
    entries
    |> Enum.filter(&(&1.status in ["completed", "verified"]))
    |> Enum.flat_map(fn entry ->
      template = entry.template

      Enum.map(entry.results || %{}, fn {field_name, result_data} ->
        field_def = find_field_def(template, field_name)

        %{
          test: template && template.name,
          label: field_def["label"] || field_name,
          value: stringify_value(result_data["value"]),
          unit: field_def["unit"],
          flag: result_data["flag"],
          reference_range: field_def["ref_range_text"],
          field_name: field_name
        }
      end)
    end)
  end

  defp normalize_embedded_tests(tests) do
    tests
    |> Enum.filter(fn test -> not is_nil_or_blank(test.result) end)
    |> Enum.map(fn test ->
      %{
        test: test.name,
        label: test.name,
        value: stringify_value(test.result),
        unit: nil,
        flag: nil,
        reference_range: nil,
        field_name: test.name
      }
    end)
  end

  defp normalize_patient_context(nil), do: %{}

  defp normalize_patient_context(patient) do
    %{
      patient_id: patient.id,
      age: patient.age || Patient.calculate_age(patient.date_of_birth),
      date_of_birth: patient.date_of_birth,
      gender: patient.gender
    }
  end

  defp normalize_doctor_note(nil), do: %{}

  defp normalize_doctor_note(doctor_note) do
    %{
      doctor_note_id: doctor_note.id,
      diagnosis: doctor_note.diagnosis,
      symptoms: doctor_note.symptoms,
      clinical_notes: doctor_note.clinical_notes,
      impression: doctor_note.impression
    }
  end

  defp normalize_triage(nil), do: %{}

  defp normalize_triage(triage) do
    %{
      triage_id: triage.id,
      temperature: triage.temperature,
      blood_pressure: triage.blood_pressure,
      pulse_rate: triage.pulse_rate,
      oxygen_saturation: triage.oxygen_saturation,
      allergies: triage.allergies,
      emergency_scale: triage.emergency_scale,
      triage_notes: triage.triage_notes
    }
  end

  defp normalize_abnormal_findings(value) when is_list(value) do
    Enum.map(value, fn
      finding when is_map(finding) -> stringify_keys(finding)
      finding -> %{"test" => to_string(finding)}
    end)
  end

  defp normalize_abnormal_findings(_), do: []

  defp normalize_lines(value) when is_list(value) do
    value
    |> Enum.map(&to_string/1)
    |> Enum.reject(&is_nil_or_blank/1)
  end

  defp normalize_lines(value) when is_binary(value), do: [value]
  defp normalize_lines(_), do: []

  defp inferred_status(context) do
    if Enum.empty?(context[:normalized_results] || []) do
      "pending"
    else
      "completed"
    end
  end

  defp abnormal_note_for_finding(%{flag: "critical_low"}),
    do: "This value is critically low and needs prompt clinician review."

  defp abnormal_note_for_finding(%{flag: "critical_high"}),
    do: "This value is critically high and needs prompt clinician review."

  defp abnormal_note_for_finding(%{flag: "low"}),
    do:
      "This value is below the stated reference range and should be read in the full clinical context."

  defp abnormal_note_for_finding(%{flag: "high"}),
    do:
      "This value is above the stated reference range and should be read in the full clinical context."

  defp abnormal_note_for_finding(_),
    do: "Read this alongside the symptoms, examination findings, and any earlier results."

  defp malaria_context_line(results, text_context) do
    malaria_related? =
      Enum.any?(results, fn result ->
        test_name =
          [result[:test], result[:label], result[:field_name]]
          |> Enum.join(" ")
          |> String.downcase()

        abnormal_flag?(result[:flag]) and String.contains?(test_name, "malaria")
      end)

    if malaria_related? and contains_any?(text_context, ["fever", "chills", "rigor", "malaria"]) do
      "The malaria-related abnormal result may fit the current fever-like presentation, but it should still be checked against the examination findings."
    end
  end

  defp low_haemoglobin_line(results, text_context) do
    low_hb? =
      Enum.any?(results, fn result ->
        name =
          [result[:test], result[:label], result[:field_name]]
          |> Enum.join(" ")
          |> String.downcase()

        abnormal_flag?(result[:flag]) and String.contains?(name, "haemoglobin")
      end)

    if low_hb? and
         contains_any?(text_context, ["weak", "fatigue", "tired", "dizziness", "pallor"]) do
      "The low haemoglobin may help explain the documented tiredness or weakness."
    end
  end

  defp high_wbc_line(results, text_context) do
    high_wbc? =
      Enum.any?(results, fn result ->
        name =
          [result[:test], result[:label], result[:field_name]]
          |> Enum.join(" ")
          |> String.downcase()

        result[:flag] in ["high", "critical_high"] and
          (String.contains?(name, "wbc") or String.contains?(name, "white"))
      end)

    if high_wbc? and
         contains_any?(text_context, ["fever", "infection", "cough", "pain", "discharge"]) do
      "The raised white cell count may fit with an infection or inflammatory picture."
    end
  end

  defp urinary_line(results, text_context) do
    urinary_related? =
      Enum.any?(results, fn result ->
        name =
          [result[:test], result[:label], result[:field_name]]
          |> Enum.join(" ")
          |> String.downcase()

        abnormal_flag?(result[:flag]) and
          (String.contains?(name, "urine") or String.contains?(name, "leucocyte") or
             String.contains?(name, "nitrite"))
      end)

    if urinary_related? and
         contains_any?(text_context, ["dysuria", "frequency", "urinary", "flank"]) do
      "The abnormal urine findings may fit the documented urinary symptoms and should be checked against the clinical picture."
    end
  end

  defp generic_abnormal_line(context) do
    summary = context[:lab_summary] || %{}

    if (summary[:abnormal_count] || 0) > 0 do
      "Review the abnormal values first and read them alongside the latest note, triage findings, and any earlier results."
    end
  end

  defp critical_flag?(flag), do: flag in ["critical_low", "critical_high"]
  defp abnormal_flag?(flag), do: flag in ["low", "high", "critical_low", "critical_high"]

  defp contains_any?(text, values) do
    Enum.any?(values, &String.contains?(text, &1))
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end

  defp stringify_keys(other), do: other

  defp stringify_value(nil), do: nil
  defp stringify_value(value) when is_binary(value), do: value
  defp stringify_value(value), do: to_string(value)

  defp is_nil_or_blank(nil), do: true
  defp is_nil_or_blank(""), do: true
  defp is_nil_or_blank(value) when is_binary(value), do: String.trim(value) == ""
  defp is_nil_or_blank(_), do: false

  defp find_field_def(nil, _field_name), do: %{}

  defp find_field_def(template, field_name) do
    Enum.find(template.field_definitions, %{}, fn field ->
      field["name"] == field_name || field[:name] == field_name
    end)
  end
end
