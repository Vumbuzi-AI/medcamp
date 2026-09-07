defmodule Medcamp.CommunityHealthSurveysTest do
  use Medcamp.DataCase

  alias Medcamp.CommunityHealthSurveys

  describe "create_response/1" do
    test "creates a valid survey response and computes household totals" do
      assert {:ok, response} = CommunityHealthSurveys.create_response(valid_attrs())

      assert response.total_household_members == 5
      assert response.insurance_providers == ["AAR", "SHA"]
      assert response.preferred_contact_method == "WhatsApp"
    end

    test "keeps only q1 to q4 mandatory" do
      attrs =
        valid_attrs()
        |> Map.put("visited_glocal", "No")
        |> Map.put("glocal_experience_rating", nil)
        |> Map.put("glocal_non_visit_reason", "")
        |> Map.put("facility_choice_reasons", ["Near Home", "Affordable", "Good Service", "Other"])
        |> Map.put("preferred_facility_type", nil)
        |> Map.put("interested_in_screenings", nil)
        |> Map.put("wants_updates", nil)
        |> Map.put("preferred_contact_method", nil)

      assert {:error, %Ecto.Changeset{} = changeset} =
               CommunityHealthSurveys.create_response(attrs)

      assert "Select up to 3 reasons" in errors_on(changeset).facility_choice_reasons
      refute Map.has_key?(errors_on(changeset), :glocal_non_visit_reason)
      refute Map.has_key?(errors_on(changeset), :preferred_facility_type)
      refute Map.has_key?(errors_on(changeset), :interested_in_screenings)
      refute Map.has_key?(errors_on(changeset), :wants_updates)
    end

    test "\"None\" cannot be combined with other conditions" do
      attrs =
        valid_attrs()
        |> Map.put("household_conditions", ["None", "Asthma"])

      assert {:error, %Ecto.Changeset{} = changeset} =
               CommunityHealthSurveys.create_response(attrs)

      assert "\"None\" cannot be combined with other conditions" in errors_on(changeset).household_conditions
    end
  end

  describe "create_public_response/1" do
    test "allows anonymous submissions" do
      attrs =
        valid_attrs()
        |> Map.delete("surveyor_name")
        |> Map.put("survey_date", "2026-06-18")

      assert {:ok, response} = CommunityHealthSurveys.create_public_response(attrs)

      assert response.surveyor_name == nil
      assert response.survey_date == ~D[2026-06-18]
      assert response.total_household_members == 5
    end
  end

  describe "build_dashboard/1" do
    test "aggregates the core survey metrics" do
      {:ok, _first} = CommunityHealthSurveys.create_response(valid_attrs())

      {:ok, _second} =
        CommunityHealthSurveys.create_response(
          valid_attrs(%{
            "surveyor_name" => "Mercy Njeri",
            "house_number" => "B-12",
            "adults_count" => "1",
            "children_count" => "1",
            "has_health_insurance" => "No",
            "insurance_covers" => [],
            "insurance_providers" => [],
            "visited_glocal" => "No",
            "glocal_experience_rating" => nil,
            "glocal_non_visit_reason" => "Not Aware of Facility",
            "interested_in_screenings" => "No",
            "wants_updates" => "No",
            "preferred_contact_method" => nil,
            "contact_number" => nil,
            "facility_choice_reasons" => ["Near Home"],
            "likely_services" => ["Laboratory Services"],
            "household_conditions" => ["None"]
          })
        )

      metrics = CommunityHealthSurveys.build_dashboard()

      assert metrics.total_households == 2
      assert metrics.total_population == 7
      assert metrics.average_household_size == 3.5
      assert metrics.insurance_coverage_rate == 50.0
      assert metrics.contact_leads_count == 1
      assert metrics.conversion_opportunities_count == 1
      assert Enum.any?(metrics.provider_rankings, &(&1.label == "AAR" and &1.count == 1))
    end
  end

  defp valid_attrs(overrides \\ %{}) do
    Map.merge(
      %{
        "surveyor_name" => "James Otieno",
        "survey_date" => "2026-06-14",
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
      },
      overrides
    )
  end
end
