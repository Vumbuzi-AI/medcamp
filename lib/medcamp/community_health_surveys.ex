defmodule Medcamp.CommunityHealthSurveys do
  @moduledoc """
  Context for community health and insurance survey responses.
  """

  import Ecto.Query, warn: false
  alias Medcamp.CommunityHealthSurveys.Response
  alias Medcamp.Repo

  def list_responses(opts \\ []) do
    from(response in Response, order_by: [desc: response.inserted_at])
    |> apply_filters(opts)
    |> Repo.all()
  end

  def get_response!(id), do: Repo.get!(Response, id)

  def create_response(attrs \\ %{}) do
    %Response{}
    |> Response.changeset(attrs)
    |> Repo.insert()
  end

  def create_public_response(attrs \\ %{}) do
    %Response{}
    |> Response.public_changeset(attrs)
    |> Repo.insert()
  end

  def change_response(%Response{} = response, attrs \\ %{}) do
    Response.changeset(response, attrs)
  end

  def build_dashboard(opts \\ []) do
    responses = list_responses(opts)
    total_households = length(responses)
    total_population = Enum.sum(Enum.map(responses, &(&1.total_household_members || 0)))
    insured_households = Enum.count(responses, &(&1.has_health_insurance == "Yes"))
    sha_households = Enum.count(responses, &sha_household?/1)

    private_households =
      Enum.count(responses, &("Private Insurance" in (&1.insurance_covers || [])))

    non_visitors = Enum.filter(responses, &(&1.visited_glocal == "No"))

    aware_non_visitors =
      Enum.count(non_visitors, &(&1.glocal_non_visit_reason != "Not Aware of Facility"))

    screening_interest = Enum.count(responses, &(&1.interested_in_screenings == "Yes"))
    contact_leads = Enum.filter(responses, &contact_lead?/1)
    conversion_opportunities = non_visitors

    %{
      total_households: total_households,
      total_population: total_population,
      average_household_size: safe_average(total_population, total_households),
      insurance_coverage_rate: percentage(insured_households, total_households),
      sha_coverage_rate: percentage(sha_households, total_households),
      private_insurance_penetration: percentage(private_households, total_households),
      awareness_of_glocal_rate: percentage(aware_non_visitors, length(non_visitors)),
      screening_interest_count: screening_interest,
      screening_interest_rate: percentage(screening_interest, total_households),
      contact_leads_count: length(contact_leads),
      contact_leads_rate: percentage(length(contact_leads), total_households),
      conversion_opportunities_count: length(conversion_opportunities),
      provider_rankings: rank_multi_select(responses, & &1.insurance_providers, total_households),
      facility_rankings:
        rank_single_select(responses, & &1.preferred_facility_type, total_households),
      service_rankings: rank_multi_select(responses, & &1.likely_services, total_households),
      household_condition_rankings:
        rank_multi_select(
          Enum.reject(responses, &("None" in (&1.household_conditions || []))),
          & &1.household_conditions,
          total_households
        ),
      experience_breakdown:
        rank_single_select(
          Enum.filter(responses, &(&1.visited_glocal == "Yes")),
          & &1.glocal_experience_rating,
          Enum.count(responses, &(&1.visited_glocal == "Yes"))
        ),
      non_visit_reason_rankings:
        rank_single_select(non_visitors, & &1.glocal_non_visit_reason, length(non_visitors)),
      communication_method_rankings:
        rank_single_select(contact_leads, & &1.preferred_contact_method, length(contact_leads)),
      contact_leads: contact_leads,
      conversion_opportunities: conversion_opportunities,
      recent_responses: Enum.take(responses, 25),
      responses: responses
    }
  end

  defp apply_filters(query, opts) do
    Enum.reduce(opts, query, fn
      {:date_from, value}, acc -> maybe_filter_date_from(acc, value)
      {:date_to, value}, acc -> maybe_filter_date_to(acc, value)
      {:search, value}, acc -> maybe_filter_search(acc, value)
      {_, _}, acc -> acc
    end)
  end

  defp maybe_filter_date_from(query, nil), do: query
  defp maybe_filter_date_from(query, ""), do: query

  defp maybe_filter_date_from(query, value) do
    case parse_date(value) do
      nil -> query
      date -> where(query, [response], response.survey_date >= ^date)
    end
  end

  defp maybe_filter_date_to(query, nil), do: query
  defp maybe_filter_date_to(query, ""), do: query

  defp maybe_filter_date_to(query, value) do
    case parse_date(value) do
      nil -> query
      date -> where(query, [response], response.survey_date <= ^date)
    end
  end

  defp maybe_filter_search(query, nil), do: query
  defp maybe_filter_search(query, ""), do: query

  defp maybe_filter_search(query, value) do
    term =
      value
      |> String.trim()
      |> String.replace("%", "\\%")
      |> String.replace("_", "\\_")
      |> then(&"%#{&1}%")

    where(
      query,
      [response],
      ilike(response.surveyor_name, ^term) or
        ilike(response.house_number, ^term) or
        ilike(response.contact_number, ^term) or
        ilike(response.preferred_facility_name, ^term) or
        ilike(response.preferred_facility_other, ^term)
    )
  end

  defp parse_date(%Date{} = value), do: value

  defp parse_date(value) when is_binary(value) do
    case Date.from_iso8601(String.trim(value)) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_date(_), do: nil

  defp sha_household?(response) do
    "SHA" in (response.insurance_covers || []) or "SHA" in (response.insurance_providers || [])
  end

  defp contact_lead?(response) do
    response.wants_updates == "Yes" and Response.valid_contact_number?(response.contact_number)
  end

  defp safe_average(_numerator, 0), do: 0.0
  defp safe_average(numerator, denominator), do: Float.round(numerator / denominator, 1)

  defp percentage(_numerator, 0), do: 0.0
  defp percentage(numerator, denominator), do: Float.round(numerator * 100 / denominator, 1)

  defp rank_multi_select(responses, accessor, denominator) do
    responses
    |> Enum.flat_map(fn response -> accessor.(response) || [] end)
    |> Enum.frequencies()
    |> rank_counts(denominator)
  end

  defp rank_single_select(responses, accessor, denominator) do
    responses
    |> Enum.map(accessor)
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.frequencies()
    |> rank_counts(denominator)
  end

  defp rank_counts(counts, denominator) do
    counts
    |> Enum.sort_by(fn {label, count} -> {-count, label} end)
    |> Enum.map(fn {label, count} ->
      %{
        label: label,
        count: count,
        percentage: percentage(count, denominator)
      }
    end)
  end
end
