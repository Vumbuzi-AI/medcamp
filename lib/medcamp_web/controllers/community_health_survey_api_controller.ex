defmodule MedcampWeb.CommunityHealthSurveyApiController do
  use MedcampWeb, :controller

  alias Medcamp.CommunityHealthSurveys

  def create(conn, params) do
    attrs = Map.get(params, "response", params)

    case CommunityHealthSurveys.create_public_response(attrs) do
      {:ok, response} ->
        conn
        |> put_status(:created)
        |> put_resp_content_type("application/json")
        |> send_resp(
          201,
          Jason.encode!(%{
            ok: true,
            message: "Survey response saved",
            response: response_payload(response)
          })
        )

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> put_resp_content_type("application/json")
        |> send_resp(
          422,
          Jason.encode!(%{
            ok: false,
            message: "Validation failed",
            errors: format_errors(changeset)
          })
        )
    end
  end

  defp response_payload(response) do
    %{
      id: response.id,
      surveyor_name: response.surveyor_name,
      survey_date: response.survey_date,
      house_number: response.house_number,
      adults_count: response.adults_count,
      children_count: response.children_count,
      total_household_members: response.total_household_members,
      has_health_insurance: response.has_health_insurance,
      insurance_covers: response.insurance_covers,
      insurance_providers: response.insurance_providers,
      preferred_facility_type: response.preferred_facility_type,
      preferred_facility_other: response.preferred_facility_other,
      preferred_facility_name: response.preferred_facility_name,
      facility_choice_reasons: response.facility_choice_reasons,
      visited_glocal: response.visited_glocal,
      glocal_experience_rating: response.glocal_experience_rating,
      glocal_non_visit_reason: response.glocal_non_visit_reason,
      likely_services: response.likely_services,
      household_conditions: response.household_conditions,
      interested_in_screenings: response.interested_in_screenings,
      wants_updates: response.wants_updates,
      preferred_contact_method: response.preferred_contact_method,
      contact_number: response.contact_number,
      inserted_at: response.inserted_at,
      updated_at: response.updated_at
    }
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
