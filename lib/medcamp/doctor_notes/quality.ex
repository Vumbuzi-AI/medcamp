defmodule Medcamp.DoctorNotes.Quality do
  @moduledoc """
  Evaluates the completeness of core clinical documentation in doctor notes.

  Optional or situation-specific fields are deliberately excluded. An explicit
  value such as "None" is considered documented; nil and whitespace are not.
  """

  @fields [
    {:reason_for_consulatation, "Complaints"},
    {:clinical_notes, "Clinical notes"},
    {:past_medical_history, "Past medical history"},
    {:impression, "Impression"},
    {:management, "Management"},
    {:investigations, "Investigations"}
  ]

  def fields, do: @fields

  def evaluate(note) do
    missing =
      Enum.reject(@fields, fn {field, _label} -> present?(Map.get(note, field)) end)

    filled_count = length(@fields) - length(missing)

    %{
      note: note,
      complete?: missing == [],
      completion_percentage: percentage(filled_count, length(@fields)),
      missing_fields: Enum.map(missing, &elem(&1, 0)),
      missing_labels: Enum.map(missing, &elem(&1, 1))
    }
  end

  def summarize(notes) do
    evaluations = Enum.map(notes, &evaluate/1)
    total = length(evaluations)
    complete = Enum.count(evaluations, & &1.complete?)

    %{
      total_notes: total,
      complete_notes: complete,
      complete_percentage: percentage(complete, total),
      average_completion: average_completion(evaluations),
      missing_impression: missing_count(evaluations, :impression),
      missing_impression_percentage: missing_percentage(evaluations, :impression),
      missing_investigations: missing_count(evaluations, :investigations),
      missing_investigations_percentage: missing_percentage(evaluations, :investigations),
      gaps: gap_summary(evaluations),
      by_doctor: doctor_summary(evaluations)
    }
  end

  defp doctor_summary(evaluations) do
    evaluations
    |> Enum.group_by(fn evaluation -> evaluation.note.doctor_id end)
    |> Enum.map(fn {doctor_id, doctor_evaluations} ->
      total = length(doctor_evaluations)
      complete = Enum.count(doctor_evaluations, & &1.complete?)

      %{
        doctor_id: doctor_id,
        doctor_name: doctor_name(doctor_evaluations),
        total_notes: total,
        complete_notes: complete,
        complete_percentage: percentage(complete, total),
        average_completion: average_completion(doctor_evaluations),
        missing_impression: missing_count(doctor_evaluations, :impression),
        missing_impression_percentage: missing_percentage(doctor_evaluations, :impression),
        missing_investigations: missing_count(doctor_evaluations, :investigations),
        missing_investigations_percentage:
          missing_percentage(doctor_evaluations, :investigations),
        missing_management: missing_count(doctor_evaluations, :management),
        missing_management_percentage: missing_percentage(doctor_evaluations, :management)
      }
    end)
    |> Enum.sort_by(&{&1.complete_percentage, -&1.total_notes, &1.doctor_name})
  end

  defp gap_summary(evaluations) do
    Enum.map(@fields, fn {field, label} ->
      count = missing_count(evaluations, field)

      %{
        field: field,
        label: label,
        missing_count: count,
        missing_percentage: percentage(count, length(evaluations))
      }
    end)
  end

  defp missing_count(evaluations, field),
    do: Enum.count(evaluations, &(field in &1.missing_fields))

  defp missing_percentage(evaluations, field),
    do: percentage(missing_count(evaluations, field), length(evaluations))

  defp average_completion([]), do: 0.0

  defp average_completion(evaluations) do
    evaluations
    |> Enum.map(& &1.completion_percentage)
    |> Enum.sum()
    |> Kernel./(length(evaluations))
    |> Float.round(1)
  end

  defp doctor_name([%{note: %{doctor: %{name: name}}} | _]) when is_binary(name) and name != "",
    do: name

  defp doctor_name(_evaluations), do: "Unknown doctor"

  defp present?(value) when is_binary(value), do: String.trim(value) != ""
  defp present?(nil), do: false
  defp present?(_value), do: true

  defp percentage(_part, 0), do: 0.0
  defp percentage(part, total), do: Float.round(part * 100 / total, 1)
end
