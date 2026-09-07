defmodule Medcamp.DoctorNoteSearch do
  @moduledoc """
  Admin reporting search across the narrative fields in doctor notes.

  Search results distinguish the number of notes containing a term from the
  number of times that term occurs. Patient age is calculated on the note date.
  """

  import Ecto.Query, warn: false

  alias Medcamp.DoctorNotes.DoctorNote
  alias Medcamp.Repo

  @search_fields [
    {:reason_for_consulatation, "Reason for consultation"},
    {:symptoms, "Symptoms / complaints"},
    {:clinical_notes, "Clinical notes"},
    {:past_medical_history, "Past medical history"},
    {:diagnosis, "Diagnosis"},
    {:diagnosis_icd_code, "Diagnosis ICD code"},
    {:impression, "Impression"},
    {:investigations, "Investigations"},
    {:lab_imaging_request, "Lab / imaging request"},
    {:management, "Management plan"},
    {:prescribed_medication, "Prescribed medication"},
    {:lifestyle_recommendations, "Lifestyle recommendations"}
  ]

  def search(filters) do
    query = filters[:query] |> to_string() |> String.trim()

    if query == "" do
      empty_report(query)
    else
      matches =
        DoctorNote
        |> join(:inner, [note], patient in assoc(note, :patient))
        |> join(:left, [note, patient], doctor in assoc(note, :doctor))
        |> apply_date_filter(filters[:date_from], filters[:date_to])
        |> apply_sex_filter(filters[:sex])
        |> apply_text_filter(query)
        |> order_by([note], desc: note.date, desc: note.time, desc: note.id)
        |> preload([note, patient, doctor], patient: patient, doctor: doctor)
        |> Repo.all()
        |> Enum.map(&build_match(&1, query))
        |> Enum.reject(&(&1.occurrence_count == 0))
        |> Enum.filter(&age_matches?(&1.age, filters[:age_from], filters[:age_to]))

      build_report(matches, query)
    end
  end

  defp apply_date_filter(query, nil, nil), do: query
  defp apply_date_filter(query, date_from, nil), do: where(query, [note], note.date >= ^date_from)
  defp apply_date_filter(query, nil, date_to), do: where(query, [note], note.date <= ^date_to)

  defp apply_date_filter(query, date_from, date_to) do
    where(query, [note], note.date >= ^date_from and note.date <= ^date_to)
  end

  defp apply_sex_filter(query, sex) when sex in [nil, ""], do: query

  defp apply_sex_filter(query, sex) do
    where(query, [_note, patient], fragment("LOWER(?)", patient.gender) == ^String.downcase(sex))
  end

  defp apply_text_filter(query, term) do
    condition =
      Enum.reduce(@search_fields, dynamic(false), fn {field_name, _label}, condition ->
        dynamic(
          [note],
          ^condition or
            fragment(
              "POSITION(LOWER(?) IN LOWER(COALESCE(?, ''))) > 0",
              ^term,
              field(note, ^field_name)
            )
        )
      end)

    where(query, ^condition)
  end

  defp build_match(note, query) do
    regex = Regex.compile!(Regex.escape(query), "iu")

    field_matches =
      @search_fields
      |> Enum.map(fn {field_name, label} ->
        value = Map.get(note, field_name) || ""
        count = regex |> Regex.scan(value) |> length()

        %{
          field: field_name,
          label: label,
          count: count,
          snippet: if(count > 0, do: snippet(value, query), else: nil)
        }
      end)
      |> Enum.filter(&(&1.count > 0))

    %{
      note: note,
      age: age_on(note.patient.date_of_birth, note.date),
      occurrence_count: Enum.sum(Enum.map(field_matches, & &1.count)),
      field_matches: field_matches
    }
  end

  defp snippet(value, query) do
    escaped = Regex.escape(query)

    case Regex.run(Regex.compile!(".{0,80}#{escaped}.{0,120}", "isu"), value) do
      [match | _] -> clean_snippet(match, value)
      _ -> clean_snippet(String.slice(value, 0, 200), value)
    end
  end

  defp clean_snippet(snippet, full_value) do
    snippet = snippet |> String.replace(~r/\s+/u, " ") |> String.trim()
    prefix = if String.starts_with?(full_value, snippet), do: "", else: "…"
    suffix = if String.ends_with?(full_value, snippet), do: "", else: "…"
    prefix <> snippet <> suffix
  end

  defp age_on(nil, _note_date), do: nil
  defp age_on(_birth_date, nil), do: nil

  defp age_on(birth_date, note_date) do
    years = note_date.year - birth_date.year

    if {note_date.month, note_date.day} < {birth_date.month, birth_date.day},
      do: years - 1,
      else: years
  end

  defp age_matches?(nil, nil, nil), do: true
  defp age_matches?(nil, _age_from, _age_to), do: false

  defp age_matches?(age, age_from, age_to) do
    (is_nil(age_from) || age >= age_from) && (is_nil(age_to) || age <= age_to)
  end

  defp build_report(matches, query) do
    field_counts =
      matches
      |> Enum.flat_map(& &1.field_matches)
      |> Enum.group_by(& &1.label)
      |> Enum.map(fn {label, entries} ->
        %{label: label, count: Enum.sum(Enum.map(entries, & &1.count))}
      end)
      |> Enum.sort_by(&{-&1.count, &1.label})

    %{
      query: query,
      matching_notes: length(matches),
      total_occurrences: Enum.sum(Enum.map(matches, & &1.occurrence_count)),
      unique_patients: matches |> Enum.map(& &1.note.patient_id) |> MapSet.new() |> MapSet.size(),
      field_counts: field_counts,
      matches: matches
    }
  end

  defp empty_report(query) do
    %{
      query: query,
      matching_notes: 0,
      total_occurrences: 0,
      unique_patients: 0,
      field_counts: [],
      matches: []
    }
  end
end
