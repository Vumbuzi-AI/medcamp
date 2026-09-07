defmodule Medcamp.LabSurveillance do
  @moduledoc """
  Reporting queries for completed laboratory tests, grouped by test and patient age.

  Ages are calculated on the day the test was performed so historical reports do
  not change as patients get older.
  """

  import Ecto.Query, warn: false

  alias Medcamp.LabTestTemplates.LabTestEntry
  alias Medcamp.Repo

  @completed_statuses ["completed", "verified"]

  def report(filters) do
    entries =
      LabTestEntry
      |> join(:inner, [entry], lab_result in assoc(entry, :lab_result))
      |> join(:inner, [entry, lab_result], template in assoc(entry, :template))
      |> join(:inner, [entry, lab_result, template], patient in assoc(lab_result, :patient))
      |> where([entry], entry.status in @completed_statuses)
      |> apply_date_filter(filters[:date_from], filters[:date_to])
      |> preload([entry, lab_result, template, patient],
        template: template,
        lab_result: {lab_result, patient: patient}
      )
      |> Repo.all()

    aggregate(entries, filters)
  end

  def aggregate(entries, filters \\ %{}) do
    test_name = normalize_filter(filters[:test_name])
    age_group = normalize_filter(filters[:age_group])

    test_names = entries |> Enum.map(&test_name/1) |> Enum.uniq() |> Enum.sort()

    entries =
      Enum.filter(entries, fn entry ->
        entry_test_name = test_name(entry)
        group = age_group(entry)

        (is_nil(test_name) || entry_test_name == test_name) &&
          (is_nil(age_group) || Atom.to_string(group) == age_group)
      end)

    rows =
      entries
      |> Enum.group_by(&test_name/1)
      |> Enum.map(fn {name, test_entries} ->
        under_five = Enum.filter(test_entries, &(age_group(&1) == :under_five))
        five_plus = Enum.filter(test_entries, &(age_group(&1) == :five_plus))
        unknown = Enum.filter(test_entries, &(age_group(&1) == :unknown))

        %{
          test_name: name,
          under_five_tested: length(under_five),
          under_five_positive: Enum.count(under_five, &positive?/1),
          five_plus_tested: length(five_plus),
          five_plus_positive: Enum.count(five_plus, &positive?/1),
          unknown_age_tested: length(unknown),
          unknown_age_positive: Enum.count(unknown, &positive?/1),
          total_tested: length(test_entries),
          total_positive: Enum.count(test_entries, &positive?/1)
        }
      end)
      |> Enum.sort_by(&String.downcase(&1.test_name))

    %{
      rows: rows,
      test_names: test_names,
      totals: sum_rows(rows)
    }
  end

  defp apply_date_filter(query, nil, nil), do: query

  defp apply_date_filter(query, date_from, nil) do
    where(
      query,
      [entry, lab_result],
      fragment(
        "COALESCE(?, ?, DATE(?)) >= ?",
        entry.test_performed_on,
        lab_result.date_of_test,
        entry.inserted_at,
        ^date_from
      )
    )
  end

  defp apply_date_filter(query, nil, date_to) do
    where(
      query,
      [entry, lab_result],
      fragment(
        "COALESCE(?, ?, DATE(?)) <= ?",
        entry.test_performed_on,
        lab_result.date_of_test,
        entry.inserted_at,
        ^date_to
      )
    )
  end

  defp apply_date_filter(query, date_from, date_to) do
    where(
      query,
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
  end

  defp sum_rows(rows) do
    Enum.reduce(
      rows,
      %{
        under_five_tested: 0,
        under_five_positive: 0,
        five_plus_tested: 0,
        five_plus_positive: 0,
        unknown_age_tested: 0,
        unknown_age_positive: 0,
        total_tested: 0,
        total_positive: 0
      },
      fn row, totals ->
        Map.new(totals, fn {key, value} -> {key, value + Map.fetch!(row, key)} end)
      end
    )
  end

  defp test_name(entry) do
    entry.template.name || entry.template.short_name || "Unnamed test"
  end

  defp age_group(entry) do
    birth_date = entry.lab_result.patient.date_of_birth

    case birth_date do
      %Date{} -> if age_on(birth_date, entry_date(entry)) < 5, do: :under_five, else: :five_plus
      _ -> :unknown
    end
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

  defp positive?(entry) do
    entry.results
    |> Kernel.||(%{})
    |> Map.values()
    |> Enum.any?(fn result ->
      value = result_value(result) |> normalize_result()

      cond do
        value == "" ->
          false

        Regex.match?(
          ~r/\b(negative|non reactive|not detected|absent|no malaria parasites seen)\b/,
          value
        ) ->
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
    end)
  end

  defp result_value(result) when is_map(result),
    do: Map.get(result, "value") || Map.get(result, :value) || ""

  defp result_value(result), do: result

  defp normalize_result(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace("_", " ")
    |> String.trim()
  end

  defp normalize_filter(value) when value in [nil, ""], do: nil
  defp normalize_filter(value), do: value
end
