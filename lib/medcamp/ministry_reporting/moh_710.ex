defmodule Medcamp.MinistryReporting.MOH710 do
  @moduledoc """
  Partial, deterministic MOH 710 aggregation from MCH service records.

  The engine fills Section A grand totals. Static/outreach splits and vaccine
  stock logistics remain blank because those attributes are not captured by
  the current MCH records.
  """

  import Ecto.Query, warn: false

  alias Medcamp.Mch.{EyeAssessment, Immunization, TdVaccination, VitaminASupplement}
  alias Medcamp.MinistryReporting
  alias Medcamp.Repo

  @form_id "moh_710"
  @section "SECTION A"
  @grand_total "Grand Total (Total Static + Total Outreach)"

  def generate(date_from, date_to) do
    immunizations =
      Immunization
      |> join(:inner, [immunization], child in assoc(immunization, :child))
      |> where(
        [immunization],
        immunization.date_given >= ^date_from and immunization.date_given <= ^date_to
      )
      |> preload([_immunization, child], child: child)
      |> Repo.all()

    vitamin_a =
      VitaminASupplement
      |> where(
        [supplement],
        supplement.date_given >= ^date_from and supplement.date_given <= ^date_to
      )
      |> Repo.all()

    td_vaccinations =
      TdVaccination
      |> where(
        [vaccination],
        vaccination.date_given >= ^date_from and vaccination.date_given <= ^date_to
      )
      |> Repo.all()

    eye_assessments =
      EyeAssessment
      |> join(:inner, [assessment], child in assoc(assessment, :child))
      |> where(
        [assessment],
        assessment.assessment_date >= ^date_from and assessment.assessment_date <= ^date_to
      )
      |> where(
        [assessment],
        assessment.has_squint == true or
          fragment("LOWER(COALESCE(?, '')) LIKE '%white%'", assessment.pupil_color)
      )
      |> preload([_assessment, child], child: child)
      |> Repo.all()

    aggregate(
      %{
        immunizations: immunizations,
        vitamin_a: vitamin_a,
        td_vaccinations: td_vaccinations,
        eye_assessments: eye_assessments
      },
      date_from,
      date_to
    )
  end

  def aggregate(sources, date_from, date_to) do
    form = MinistryReporting.get_form(@form_id)

    initial = %{counts: %{}, matched: 0, unmatched: MapSet.new()}

    result =
      sources
      |> Map.get(:immunizations, [])
      |> Enum.reduce(initial, &count_immunization/2)
      |> count_vitamin_a(Map.get(sources, :vitamin_a, []))
      |> count_td_vaccinations(Map.get(sources, :td_vaccinations, []))
      |> count_eye_assessments(Map.get(sources, :eye_assessments, []))

    values =
      Enum.reduce(result.counts, period_values(date_from, date_to), fn
        {{code, label}, count}, values ->
          case MinistryReporting.find_table_cell_id_by_code(
                 form,
                 @section,
                 code,
                 label,
                 @grand_total
               ) do
            nil -> values
            id -> Map.put(values, id, Integer.to_string(count))
          end
      end)

    source_count =
      sources
      |> Map.take([:immunizations, :vitamin_a, :td_vaccinations, :eye_assessments])
      |> Map.values()
      |> Enum.map(&length/1)
      |> Enum.sum()

    %{
      values: values,
      summary: %{
        source_entries: source_count,
        matched_entries: result.matched,
        source_label: "recorded immunization and child-health events",
        unmatched_tests: result.unmatched |> MapSet.to_list() |> Enum.sort(),
        limitations: [
          "Grand totals are filled; static versus outreach delivery is not recorded.",
          "Cold-chain and vaccine-stock sections remain manual."
        ]
      }
    }
  end

  defp count_immunization(immunization, acc) do
    case immunization_target(immunization) do
      {:ok, target} ->
        acc =
          acc
          |> increment(target)
          |> Map.update!(:matched, &(&1 + 1))

        if immunization.adverse_event,
          do: increment(acc, {"Adverse Events Following Immunization", ""}),
          else: acc

      :unmatched ->
        description =
          [immunization.vaccine_name, immunization.dose_number]
          |> Enum.reject(&is_nil/1)
          |> Enum.join(" dose ")
          |> case do
            "" -> "Immunization with no vaccine name"
            value -> value
          end

        %{acc | unmatched: MapSet.put(acc.unmatched, description)}
    end
  end

  defp immunization_target(immunization) do
    name = normalize(immunization.vaccine_name)
    dose = immunization.dose_number
    age_months = age_in_months(immunization.child.date_of_birth, immunization.date_given)

    cond do
      name in ["bcg", "bacillus calmette guerin"] ->
        {:ok, {"BCG", under_or_above_one(age_months)}}

      name in ["opv", "oral polio vaccine"] && birth_dose?(immunization, age_months) ->
        {:ok, {"OPV (Birth dose)", "Within 2 weeks"}}

      name in ["opv", "oral polio vaccine"] && dose in 1..3 ->
        {:ok, {"OPV#{dose}", under_or_above_one(age_months)}}

      name in ["ipv", "inactivated polio vaccine"] && dose in 1..2 ->
        {:ok, {"IPV#{dose}", under_or_above_one(age_months)}}

      name in ["pentavalent", "dpt hib hepb", "dpt hib hep b"] && dose in 1..3 ->
        {:ok, {"DPT+HIB+HEPB #{dose}", under_or_above_one(age_months)}}

      name in ["pcv", "pcv10", "pneumococcal", "pneumococcal vaccine"] && dose in 1..3 ->
        {:ok, {"Pneumococcal #{dose}", under_or_above_one(age_months)}}

      name in ["rota", "rotavirus", "rotavirus vaccine"] && dose in 1..3 && age_months < 12 ->
        {:ok, {"Rota #{dose}", "Under 1 Year"}}

      name in ["malaria", "malaria vaccine"] && dose in 1..3 ->
        {:ok, {"Malaria Vaccine #{dose}", under_or_above_one(age_months)}}

      name in ["malaria", "malaria vaccine"] && dose == 4 && age_months in 24..47 ->
        {:ok, {"Malaria Vaccine 4", "At 2-3 years"}}

      name in ["malaria", "malaria vaccine"] && dose == 4 && age_months >= 48 ->
        {:ok, {"Malaria Vaccine 4", "Above 3 years"}}

      name in ["yellow fever", "yellow fever vaccine"] ->
        {:ok, {"Yellow fever", under_or_above_one(age_months)}}

      name in ["mr", "measles rubella", "measles rubella vaccine"] && dose == 1 ->
        {:ok, {"MR 1", under_or_above_one(age_months)}}

      name in ["mr", "measles rubella", "measles rubella vaccine"] && dose == 2 &&
          age_months in 18..24 ->
        {:ok, {"MR 2", "At 1 1/2 - 2 Years"}}

      name in ["mr", "measles rubella", "measles rubella vaccine"] && dose == 2 &&
          age_months > 24 ->
        {:ok, {"MR 2", "Above 2 Years"}}

      name in ["typhoid conjugate", "typhoid conjugate vaccine", "tcv"] ->
        {:ok, {"Typhoid Conjugate Vaccine", under_or_above_one(age_months)}}

      name in ["hpv", "hpv vaccine", "human papillomavirus vaccine"] && dose == 1 ->
        {:ok, {"HPV Vaccine", "1st Dose - 10 years"}}

      name in ["hpv", "hpv vaccine", "human papillomavirus vaccine"] && dose == 2 ->
        {:ok, {"HPV Vaccine", "2nd Dose - At least 6 months after HPV dose 1"}}

      true ->
        :unmatched
    end
  end

  defp count_vitamin_a(acc, supplements) do
    Enum.reduce(supplements, acc, fn supplement, acc ->
      target =
        cond do
          supplement.dose_iu == 100_000 ->
            {"Vitamin A", "At 6 -11 Months (100,000IU)"}

          supplement.dose_iu == 200_000 ->
            {"Vitamin A", "At 12-59 Months (200,000IU)"}

          supplement.age_months in 6..11 ->
            {"Vitamin A", "At 6 -11 Months (100,000IU)"}

          supplement.age_months in 12..59 ->
            {"Vitamin A", "At 12-59 Months (200,000IU)"}

          true ->
            nil
        end

      if target do
        acc |> increment(target) |> Map.update!(:matched, &(&1 + 1))
      else
        %{
          acc
          | unmatched: MapSet.put(acc.unmatched, "Vitamin A supplement with unknown dose/age")
        }
      end
    end)
  end

  defp count_td_vaccinations(acc, vaccinations) do
    Enum.reduce(vaccinations, acc, fn vaccination, acc ->
      if vaccination.dose_number in 1..5 do
        target =
          {"Tetanus Diphtheria Containing Vaccine for pregnant women",
           ordinal(vaccination.dose_number)}

        acc |> increment(target) |> Map.update!(:matched, &(&1 + 1))
      else
        %{acc | unmatched: MapSet.put(acc.unmatched, "TD vaccination with unknown dose")}
      end
    end)
  end

  defp count_eye_assessments(acc, assessments) do
    Enum.reduce(assessments, acc, fn assessment, acc ->
      age_months = age_in_months(assessment.child.date_of_birth, assessment.assessment_date)
      white_reflection? = normalize(assessment.pupil_color) in ["white", "white reflection"]

      if age_months < 12 && (assessment.has_squint || white_reflection?) do
        acc
        |> increment({"Squint/White Eye reflection (Under 1 Year)", ""})
        |> Map.update!(:matched, &(&1 + 1))
      else
        acc
      end
    end)
  end

  defp increment(acc, target) do
    %{acc | counts: Map.update(acc.counts, target, 1, &(&1 + 1))}
  end

  defp birth_dose?(immunization, age_months) do
    age_months == 0 &&
      (immunization.dose_number in [0, nil] ||
         normalize(immunization.scheduled_age) in ["birth", "at birth", "within 2 weeks"])
  end

  defp under_or_above_one(age_months) when age_months < 12, do: "Under 1 Year"
  defp under_or_above_one(_age_months), do: "Above 1 Year"

  defp age_in_months(nil, _date), do: 999
  defp age_in_months(_birth_date, nil), do: 999

  defp age_in_months(birth_date, date) do
    months = (date.year - birth_date.year) * 12 + date.month - birth_date.month
    if date.day < birth_date.day, do: months - 1, else: months
  end

  defp ordinal(1), do: "1st Dose"
  defp ordinal(2), do: "2nd Dose"
  defp ordinal(3), do: "3rd Dose"
  defp ordinal(4), do: "4th Dose"
  defp ordinal(5), do: "5th Dose"

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

    %{"month" => month, "year" => year}
  end

  defp normalize(nil), do: ""

  defp normalize(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, " ")
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
  end
end
