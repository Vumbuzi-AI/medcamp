defmodule Medcamp.MinistryReporting.MOH706 do
  @moduledoc """
  Deterministic MOH 706 aggregation from completed structured laboratory entries.

  Only explicitly mapped templates and result fields are counted. Unknown test
  names are returned in the summary so an administrator can correct the mapping
  instead of silently placing clinical data in the wrong official-report cell.
  """

  import Ecto.Query, warn: false

  alias Medcamp.LabTestTemplates.LabTestEntry
  alias Medcamp.MinistryReporting
  alias Medcamp.Repo

  @form_id "moh_706"

  @single_test_mappings %{
    "full haemogram test fbc" => {"4. HAEMATOLOGY", "Full blood count", :total},
    "full haemogram" => {"4. HAEMATOLOGY", "Full blood count", :total},
    "full blood count" => {"4. HAEMATOLOGY", "Full blood count", :total},
    "fbc" => {"4. HAEMATOLOGY", "Full blood count", :total},
    "hiv test" => {"7. SEROLOGY", "HIV", :positive},
    "hiv" => {"7. SEROLOGY", "HIV", :positive},
    "vdrl test" => {"7. SEROLOGY", "VDRL", :positive},
    "vdrl" => {"7. SEROLOGY", "VDRL", :positive},
    "hepatitis b test" => {"7. SEROLOGY", "Hepatitis B test", :positive},
    "hepatitis surface antigen" => {"7. SEROLOGY", "Hepatitis B test", :positive},
    "h pylori antigen test" => {"7. SEROLOGY", "Helicobacter pylori", :positive},
    "h pylori antibody test" => {"7. SEROLOGY", "Helicobacter pylori", :positive},
    "rheumatoid factor" => {"7. SEROLOGY", "Rheumatoid factor", :positive},
    "rheumatoid factor rf" => {"7. SEROLOGY", "Rheumatoid factor", :positive},
    "anti streptolysin o test" => {"7. SEROLOGY", "ASOT", :positive},
    "asot" => {"7. SEROLOGY", "ASOT", :positive},
    "abo grouping and rhesus factor" => {"4. HAEMATOLOGY", "Total blood group tests", :total},
    "blood group" => {"4. HAEMATOLOGY", "Total blood group tests", :total},
    "sickling test" => {"4. HAEMATOLOGY", "Sickling test", :positive},
    "erythrocyte sedimentation rate" =>
      {"4. HAEMATOLOGY", "Erythrocyte Sedimentation rate", :total},
    "esr" => {"4. HAEMATOLOGY", "Erythrocyte Sedimentation rate", :total}
  }

  @compound_mappings %{
    "renal function test" => %{
      "creatinine" => {"2. BLOOD CHEMISTRY", "Creatinine", :low_high},
      "urea" => {"2. BLOOD CHEMISTRY", "Urea", :low_high},
      "sodium" => {"2. BLOOD CHEMISTRY", "Sodium", :low_high},
      "potassium" => {"2. BLOOD CHEMISTRY", "Potassium", :low_high},
      "chloride" => {"2. BLOOD CHEMISTRY", "Chlorides", :low_high}
    },
    "rft" => %{
      "creatinine" => {"2. BLOOD CHEMISTRY", "Creatinine", :low_high},
      "urea" => {"2. BLOOD CHEMISTRY", "Urea", :low_high},
      "sodium" => {"2. BLOOD CHEMISTRY", "Sodium", :low_high},
      "potassium" => {"2. BLOOD CHEMISTRY", "Potassium", :low_high},
      "chloride" => {"2. BLOOD CHEMISTRY", "Chlorides", :low_high}
    },
    "liver function test" => %{
      "ast" => {"2. BLOOD CHEMISTRY", "ASAT (SGOT)", :low_high},
      "alt" => {"2. BLOOD CHEMISTRY", "ALAT (SGPT)", :low_high},
      "alp" => {"2. BLOOD CHEMISTRY", "Alkaline Phosphatase", :low_high},
      "albumin" => {"2. BLOOD CHEMISTRY", "Albumin", :low_high},
      "t bilirubin" => {"2. BLOOD CHEMISTRY", "Total bilirubin", :low_high},
      "d bilirubin" => {"2. BLOOD CHEMISTRY", "Direct bilirubin", :low_high}
    },
    "lft" => %{
      "ast" => {"2. BLOOD CHEMISTRY", "ASAT (SGOT)", :low_high},
      "alt" => {"2. BLOOD CHEMISTRY", "ALAT (SGPT)", :low_high},
      "alp" => {"2. BLOOD CHEMISTRY", "Alkaline Phosphatase", :low_high},
      "albumin" => {"2. BLOOD CHEMISTRY", "Albumin", :low_high},
      "t bilirubin" => {"2. BLOOD CHEMISTRY", "Total bilirubin", :low_high},
      "d bilirubin" => {"2. BLOOD CHEMISTRY", "Direct bilirubin", :low_high}
    },
    "lipid profile" => %{
      "total cholesterol" => {"2. BLOOD CHEMISTRY", "Total cholesterol", :low_high},
      "ldl" => {"2. BLOOD CHEMISTRY", "LDL", :low_high},
      "triglycerides" => {"2. BLOOD CHEMISTRY", "Triglycerides", :low_high}
    },
    "routine urinalysis" => %{
      "glucose" => {"1. URINE ANALYSIS", "Glucose", :positive},
      "ketones" => {"1. URINE ANALYSIS", "Ketones", :positive},
      "protein" => {"1. URINE ANALYSIS", "Proteins", :positive},
      "wbc pus cells" => {"1. URINE ANALYSIS", "Pus cells (>5/hpf)", :positive},
      "yeast cells" => {"1. URINE ANALYSIS", "Yeast cells", :positive},
      "trichomonas vaginalis" => {"1. URINE ANALYSIS", "T. vaginalis", :positive},
      "bacteria" => {"1. URINE ANALYSIS", "Bacteria", :positive}
    },
    "urinalysis" => %{
      "glucose" => {"1. URINE ANALYSIS", "Glucose", :positive},
      "ketones" => {"1. URINE ANALYSIS", "Ketones", :positive},
      "protein" => {"1. URINE ANALYSIS", "Proteins", :positive},
      "wbc pus cells" => {"1. URINE ANALYSIS", "Pus cells (>5/hpf)", :positive},
      "yeast cells" => {"1. URINE ANALYSIS", "Yeast cells", :positive},
      "trichomonas vaginalis" => {"1. URINE ANALYSIS", "T. vaginalis", :positive},
      "bacteria" => {"1. URINE ANALYSIS", "Bacteria", :positive}
    }
  }

  @malaria_rdt_names ["malaria rdt", "malaria rapid", "malaria rapid diagnostic test"]
  @malaria_microscopy_names [
    "malaria microscopy test",
    "malaria microscopy",
    "malaria microscopic",
    "malaria bs"
  ]

  def generate(date_from, date_to) do
    entries =
      LabTestEntry
      |> join(:inner, [entry], lab_result in assoc(entry, :lab_result))
      |> join(:inner, [entry, lab_result], template in assoc(entry, :template))
      |> join(:left, [entry, lab_result, template], patient in assoc(lab_result, :patient))
      |> where([entry], entry.status in ["completed", "verified"])
      |> where(
        [entry, lab_result],
        fragment(
          "COALESCE(?, ?, DATE(?)) BETWEEN ? AND ?",
          entry.test_performed_on,
          lab_result.date_of_test,
          entry.inserted_at,
          ^date_from,
          ^date_to
        )
      )
      |> preload([entry, lab_result, template, patient],
        template: template,
        lab_result: {lab_result, patient: patient}
      )
      |> Repo.all()

    aggregate(entries, date_from, date_to)
  end

  def aggregate(entries, date_from, date_to) do
    form = MinistryReporting.get_form(@form_id)

    initial = %{
      counts: %{},
      matched_entries: 0,
      unmatched_tests: MapSet.new()
    }

    result = Enum.reduce(entries, initial, &count_entry/2)

    values =
      result.counts
      |> Enum.reduce(period_values(date_from, date_to), fn
        {{section, row, metric}, count}, values ->
          case cell_id(form, section, row, metric) do
            nil -> values
            id -> Map.put(values, id, Integer.to_string(count))
          end
      end)

    %{
      values: values,
      summary: %{
        source_entries: length(entries),
        matched_entries: result.matched_entries,
        source_label: "completed lab entries",
        unmatched_tests: result.unmatched_tests |> MapSet.to_list() |> Enum.sort(),
        limitations: []
      }
    }
  end

  defp count_entry(entry, acc) do
    names =
      [entry.template.name, entry.template.short_name]
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&normalize/1)

    cond do
      malaria_name?(names, @malaria_rdt_names) ->
        result = first_result(entry)
        add_target(acc, {"3. PARASITOLOGY", "Malaria Rapid Diagnostic Tests", :positive}, result)

      malaria_name?(names, @malaria_microscopy_names) ->
        row = malaria_microscopy_row(entry)
        add_target(acc, {"3. PARASITOLOGY", row, :positive}, first_result(entry))

      mapping = find_mapping(names, @single_test_mappings) ->
        add_target(acc, mapping, first_result(entry))

      mappings = find_mapping(names, @compound_mappings) ->
        count_compound_entry(entry, mappings, acc)

      true ->
        test_name = entry.template.name || entry.template.short_name || "Unknown test"
        %{acc | unmatched_tests: MapSet.put(acc.unmatched_tests, test_name)}
    end
  end

  defp count_compound_entry(entry, mappings, acc) do
    {acc, matched_fields} =
      Enum.reduce(entry.results || %{}, {acc, 0}, fn {field_name, result}, {acc, matched} ->
        case {Map.get(mappings, normalize(field_name)), result_recorded?(result)} do
          {nil, _recorded?} -> {acc, matched}
          {_target, false} -> {acc, matched}
          {target, true} -> {add_count(acc, target, result), matched + 1}
        end
      end)

    if matched_fields > 0 do
      %{acc | matched_entries: acc.matched_entries + 1}
    else
      test_name = entry.template.name || entry.template.short_name || "Unknown test"
      %{acc | unmatched_tests: MapSet.put(acc.unmatched_tests, test_name)}
    end
  end

  defp add_target(acc, target, result) do
    acc
    |> add_count(target, result)
    |> Map.update!(:matched_entries, &(&1 + 1))
  end

  defp add_count(acc, {section, row, mode}, result) do
    counts =
      acc.counts
      |> increment({section, row, :total})
      |> maybe_increment_outcome(section, row, mode, result)

    %{acc | counts: counts}
  end

  defp maybe_increment_outcome(counts, _section, _row, :total, _result), do: counts

  defp maybe_increment_outcome(counts, section, row, :positive, result) do
    if positive?(result), do: increment(counts, {section, row, :positive}), else: counts
  end

  defp maybe_increment_outcome(counts, section, row, :low_high, result) do
    case result_flag(result) do
      flag when flag in ["low", "critical low"] -> increment(counts, {section, row, :low})
      flag when flag in ["high", "critical high"] -> increment(counts, {section, row, :high})
      _ -> counts
    end
  end

  defp increment(counts, key), do: Map.update(counts, key, 1, &(&1 + 1))

  defp cell_id(form, section, row, :total),
    do: MinistryReporting.find_table_cell_id(form, section, row, "Total Exam")

  defp cell_id(form, section, row, :positive) do
    ["Number Positive", "Cultures Positive", "Malignant"]
    |> Enum.find_value(&MinistryReporting.find_table_cell_id(form, section, row, &1))
  end

  defp cell_id(form, section, row, :low),
    do: MinistryReporting.find_table_cell_id(form, section, row, "Low")

  defp cell_id(form, section, row, :high),
    do: MinistryReporting.find_table_cell_id(form, section, row, "High")

  defp period_values(date_from, date_to) do
    month =
      if date_from.year == date_to.year && date_from.month == date_to.month do
        Calendar.strftime(date_from, "%B")
      else
        "#{Date.to_iso8601(date_from)} – #{Date.to_iso8601(date_to)}"
      end

    year =
      if date_from.year == date_to.year,
        do: Integer.to_string(date_from.year),
        else: "#{date_from.year}–#{date_to.year}"

    %{"report_month" => month, "year" => year}
  end

  defp first_result(entry) do
    entry.results
    |> Kernel.||(%{})
    |> Map.values()
    |> List.first()
    |> Kernel.||(%{})
  end

  defp positive?(result) do
    value = result_value(result) |> normalize()

    cond do
      value == "" ->
        false

      Regex.match?(~r/\b(negative|non reactive|not detected|no malaria parasites seen)\b/, value) ->
        false

      Regex.match?(
        ~r/\b(positive|reactive|detected|present|malariae|falciparum|vivax|ovale|mixed species)\b/,
        value
      ) ->
        true

      String.contains?(value, "+") ->
        true

      true ->
        false
    end
  end

  defp result_value(result) when is_map(result),
    do: Map.get(result, "value") || Map.get(result, :value) || ""

  defp result_value(result), do: result

  defp result_recorded?(result) do
    case result_value(result) do
      nil -> false
      value when is_binary(value) -> String.trim(value) != ""
      _value -> true
    end
  end

  defp result_flag(result) when is_map(result) do
    (Map.get(result, "flag") || Map.get(result, :flag) || "")
    |> normalize()
  end

  defp result_flag(_result), do: ""

  defp malaria_microscopy_row(entry) do
    test_date = entry_date(entry)

    birth_date =
      get_in(entry, [Access.key(:lab_result), Access.key(:patient), Access.key(:date_of_birth)])

    if birth_date && age_on(birth_date, test_date) < 5,
      do: "Malaria BS (Under five years)",
      else: "Malaria BS (5 years and above)"
  end

  defp age_on(birth_date, on_date) do
    years = on_date.year - birth_date.year

    if {on_date.month, on_date.day} < {birth_date.month, birth_date.day},
      do: years - 1,
      else: years
  end

  defp entry_date(entry) do
    entry.test_performed_on ||
      entry.lab_result.date_of_test ||
      DateTime.to_date(entry.inserted_at)
  end

  defp malaria_name?(names, aliases), do: Enum.any?(names, &(&1 in aliases))

  defp find_mapping(names, mappings) do
    Enum.find_value(names, &Map.get(mappings, &1))
  end

  defp normalize(nil), do: ""

  defp normalize(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(".", " ")
    |> String.replace("_", " ")
    |> String.replace(~r/[^a-z0-9+]+/u, " ")
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end
end
