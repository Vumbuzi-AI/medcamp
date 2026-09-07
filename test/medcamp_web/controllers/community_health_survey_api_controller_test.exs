defmodule MedcampWeb.CommunityHealthSurveyApiControllerTest do
  use MedcampWeb.ConnCase, async: true

  alias Medcamp.CommunityHealthSurveys

  describe "POST /api/community-health-insurance-survey" do
    test "creates an anonymous public survey response", %{conn: conn} do
      params = %{
        "survey_date" => "2026-06-18",
        "house_number" => "A-01",
        "adults_count" => "2",
        "children_count" => "3",
        "has_health_insurance" => "Yes",
        "insurance_covers" => ["SHA", "Private Insurance"],
        "insurance_providers" => ["AAR", "SHA"],
        "preferred_facility_type" => "Glocal Healthcare Centre of Excellence",
        "preferred_facility_name" => "Glocal Kisaju",
        "facility_choice_reasons" => ["Near Home", "Insurance Accepted", "Good Service"],
        "visited_glocal" => "Yes",
        "glocal_experience_rating" => "Excellent",
        "likely_services" => ["General Outpatient Clinic", "Laboratory Services"],
        "household_conditions" => ["Asthma"],
        "interested_in_screenings" => "Yes",
        "wants_updates" => "Yes",
        "preferred_contact_method" => "WhatsApp",
        "contact_number" => "+254700000001"
      }

      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> post(~p"/api/community-health-insurance-survey", params)

      assert %{"ok" => true, "response" => response} = json_response(conn, 201)
      assert response["surveyor_name"] == nil
      assert response["house_number"] == "A-01"
      assert response["total_household_members"] == 5

      assert CommunityHealthSurveys.list_responses() |> Enum.any?(&(&1.house_number == "A-01"))
    end
  end
end
