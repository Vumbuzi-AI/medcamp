defmodule Medcamp.MinistryReportingTest do
  use ExUnit.Case, async: true

  alias Medcamp.LabResults.LabResult
  alias Medcamp.LabTestTemplates.{LabTestEntry, LabTestTemplate}
  alias Medcamp.Mch.{Child, EyeAssessment, Immunization, TdVaccination, VitaminASupplement}
  alias Medcamp.MinistryReporting
  alias Medcamp.MinistryReporting.{AIMappingAdvisor, MCP, MOH706, MOH710}
  alias Medcamp.Patients.Patient

  defmodule FakeMappingAI do
    def request_json_to_gpt(_system_prompt, _user_prompt, opts) do
      send(self(), {:ai_opts, opts})

      {:ok,
       %{
         "suggestions" => [
           %{
             "source_item" => "Acute watery diarrhoea",
             "candidate_id" => "0:0",
             "confidence" => 0.91,
             "reason" => "The source label is a diarrhoeal condition."
           },
           %{
             "source_item" => "Acute watery diarrhoea",
             "candidate_id" => "99:99",
             "confidence" => 1,
             "reason" => "This candidate does not exist."
           }
         ]
       }}
    end
  end

  describe "auto_fill/3" do
    test "validates dates and supported forms before querying data" do
      assert {:error, :invalid_date} =
               MinistryReporting.auto_fill("moh_706", "not-a-date", "2026-07-31")

      assert {:error, :invalid_range} =
               MinistryReporting.auto_fill("moh_706", "2026-08-01", "2026-07-31")

      assert {:error, :unsupported_form} =
               MinistryReporting.auto_fill("moh_705a", "2026-07-01", "2026-07-31")

      assert MinistryReporting.auto_fill_supported?("moh_706")
      assert MinistryReporting.auto_fill_supported?("moh_710")
    end
  end

  describe "MOH710.aggregate/3" do
    test "fills antigen grand totals from mapped MCH events" do
      infant = %Child{date_of_birth: ~D[2026-01-01]}
      older_child = %Child{date_of_birth: ~D[2024-01-01]}

      sources = %{
        immunizations: [
          immunization("BCG", nil, infant, adverse_event: true),
          immunization("OPV", 1, older_child),
          immunization("Pentavalent", 2, infant),
          immunization("Unmapped Vaccine", 1, infant)
        ],
        vitamin_a: [
          %VitaminASupplement{age_months: 8, dose_iu: 100_000, date_given: ~D[2026-07-10]}
        ],
        td_vaccinations: [
          %TdVaccination{dose_number: 2, date_given: ~D[2026-07-11]}
        ],
        eye_assessments: [
          %EyeAssessment{
            child: infant,
            assessment_date: ~D[2026-07-12],
            has_squint: true
          }
        ]
      }

      report = MOH710.aggregate(sources, ~D[2026-07-01], ~D[2026-07-31])
      form = MinistryReporting.get_form("moh_710")

      assert report.values[moh710_cell(form, "BCG", "Under 1 Year")] == "1"
      assert report.values[moh710_cell(form, "OPV1", "Above 1 Year")] == "1"
      assert report.values[moh710_cell(form, "DPT+HIB+HEPB 2", "Under 1 Year")] == "1"

      assert report.values[
               moh710_cell(form, "Vitamin A", "At 6 -11 Months (100,000IU)")
             ] == "1"

      assert report.values[
               moh710_cell(
                 form,
                 "Tetanus Diphtheria Containing Vaccine for pregnant women",
                 "2nd Dose"
               )
             ] == "1"

      assert report.values[
               moh710_cell(form, "Adverse Events Following Immunization", "")
             ] == "1"

      assert report.values[
               moh710_cell(form, "Squint/White Eye reflection (Under 1 Year)", "")
             ] == "1"

      assert report.values["month"] == "July"
      assert report.values["year"] == "2026"
      assert report.summary.source_entries == 7
      assert report.summary.matched_entries == 6
      assert report.summary.unmatched_tests == ["Unmapped Vaccine dose 1"]
      assert length(report.summary.limitations) == 2
    end
  end

  describe "MOH706.aggregate/3" do
    test "counts approved templates, outcomes and abnormal chemistry flags" do
      entries = [
        entry("HIV Test", %{"hiv_test" => %{"value" => "Positive"}}),
        entry("HIV Test", %{"hiv_test" => %{"value" => "Negative"}}),
        entry("Renal Function Test", %{
          "creatinine" => %{"value" => "20", "flag" => "low"},
          "urea" => %{"value" => "12", "flag" => "high"},
          "sodium" => %{"value" => ""}
        }),
        entry("Unmapped Specialist Assay", %{"result" => %{"value" => "Positive"}})
      ]

      report = MOH706.aggregate(entries, ~D[2026-07-01], ~D[2026-07-31])
      form = MinistryReporting.get_form("moh_706")

      hiv_total =
        MinistryReporting.find_table_cell_id(form, "7. SEROLOGY", "HIV", "Total Exam")

      hiv_positive =
        MinistryReporting.find_table_cell_id(form, "7. SEROLOGY", "HIV", "Number Positive")

      creatinine_low =
        MinistryReporting.find_table_cell_id(
          form,
          "2. BLOOD CHEMISTRY",
          "Creatinine",
          "Low"
        )

      urea_high =
        MinistryReporting.find_table_cell_id(form, "2. BLOOD CHEMISTRY", "Urea", "High")

      sodium_total =
        MinistryReporting.find_table_cell_id(form, "2. BLOOD CHEMISTRY", "Sodium", "Total Exam")

      assert report.values[hiv_total] == "2"
      assert report.values[hiv_positive] == "1"
      assert report.values[creatinine_low] == "1"
      assert report.values[urea_high] == "1"
      refute Map.has_key?(report.values, sodium_total)
      assert report.values["report_month"] == "July"
      assert report.values["year"] == "2026"

      assert report.summary == %{
               source_entries: 4,
               matched_entries: 3,
               source_label: "completed lab entries",
               unmatched_tests: ["Unmapped Specialist Assay"],
               limitations: []
             }
    end

    test "splits malaria microscopy totals by patient age on the test date" do
      entries = [
        entry(
          "Malaria Microscopy Test",
          %{
            "malaria_microscopy" => %{"value" => "P. falciparum (+)"}
          },
          ~D[2022-01-01]
        ),
        entry(
          "Malaria Microscopy Test",
          %{
            "malaria_microscopy" => %{"value" => "No Malaria Parasites Seen"}
          },
          ~D[1990-01-01]
        )
      ]

      report = MOH706.aggregate(entries, ~D[2026-07-01], ~D[2026-07-31])
      form = MinistryReporting.get_form("moh_706")

      under_five_total =
        MinistryReporting.find_table_cell_id(
          form,
          "3. PARASITOLOGY",
          "Malaria BS (Under five years)",
          "Total Exam"
        )

      under_five_positive =
        MinistryReporting.find_table_cell_id(
          form,
          "3. PARASITOLOGY",
          "Malaria BS (Under five years)",
          "Number Positive"
        )

      over_five_total =
        MinistryReporting.find_table_cell_id(
          form,
          "3. PARASITOLOGY",
          "Malaria BS (5 years and above)",
          "Total Exam"
        )

      assert report.values[under_five_total] == "1"
      assert report.values[under_five_positive] == "1"
      assert report.values[over_five_total] == "1"
    end
  end

  describe "MCP.handle/1" do
    test "advertises read-only reporting tools" do
      response =
        MCP.handle(%{
          "jsonrpc" => "2.0",
          "id" => 1,
          "method" => "tools/list"
        })

      assert get_in(response, ["result", "tools"])
             |> Enum.map(& &1["name"]) == [
               "list_moh_reports",
               "get_moh_report_schema",
               "generate_moh_report",
               "suggest_moh_mappings"
             ]
    end

    test "serves schema and readiness for reports without deterministic auto-fill" do
      response =
        MCP.handle(%{
          "jsonrpc" => "2.0",
          "id" => 3,
          "method" => "tools/call",
          "params" => %{
            "name" => "get_moh_report_schema",
            "arguments" => %{"form_id" => "moh_711"}
          }
        })

      content = get_in(response, ["result", "structuredContent"])
      assert content["capability"].status == "schema_only"
      assert content["capability"].ai_advisory
      assert content["mapping_candidates"] != []
    end

    test "serves a schema contract for every configured report" do
      for form <- MinistryReporting.forms() do
        response =
          MCP.handle(%{
            "jsonrpc" => "2.0",
            "id" => form["id"],
            "method" => "tools/call",
            "params" => %{
              "name" => "get_moh_report_schema",
              "arguments" => %{"form_id" => form["id"]}
            }
          })

        content = get_in(response, ["result", "structuredContent"])
        assert content["form_id"] == form["id"]
        assert is_map(content["capability"])
        assert is_list(content["mapping_candidates"])
      end
    end

    test "returns tool errors for invalid ranges" do
      response =
        MCP.handle(%{
          "jsonrpc" => "2.0",
          "id" => 2,
          "method" => "tools/call",
          "params" => %{
            "name" => "generate_moh_report",
            "arguments" => %{
              "form_id" => "moh_706",
              "date_from" => "2026-08-01",
              "date_to" => "2026-07-01"
            }
          }
        })

      assert get_in(response, ["result", "isError"])
      assert get_in(response, ["result", "content", Access.at(0), "text"]) =~ "date_from"
    end
  end

  describe "AIMappingAdvisor.suggest/3" do
    test "returns only validated candidates and never applies suggestions" do
      assert {:ok, result} =
               AIMappingAdvisor.suggest(
                 "moh_705a",
                 ["Acute watery diarrhoea"],
                 FakeMappingAI
               )

      assert_receive {:ai_opts, opts}
      assert is_map(opts[:response_schema])

      assert [
               %{
                 "source_item" => "Acute watery diarrhoea",
                 "candidate_id" => "0:0",
                 "confidence" => 0.91,
                 "requires_human_review" => true
               }
             ] = result["suggestions"]

      refute result["applied"]
      assert result["advisory_only"]
    end

    test "rejects unknown forms and empty source labels" do
      assert {:error, :unknown_form} =
               AIMappingAdvisor.suggest("not-a-form", ["Malaria"], FakeMappingAI)

      assert {:error, :invalid_source_items} =
               AIMappingAdvisor.suggest("moh_705a", ["  "], FakeMappingAI)
    end
  end

  defp entry(template_name, results, birth_date \\ ~D[1990-01-01]) do
    %LabTestEntry{
      status: "completed",
      results: results,
      test_performed_on: ~D[2026-07-15],
      inserted_at: ~U[2026-07-15 08:00:00Z],
      template: %LabTestTemplate{name: template_name},
      lab_result: %LabResult{
        date_of_test: ~D[2026-07-15],
        patient: %Patient{date_of_birth: birth_date}
      }
    }
  end

  defp immunization(name, dose, child, options \\ []) do
    %Immunization{
      vaccine_name: name,
      dose_number: dose,
      date_given: ~D[2026-07-15],
      adverse_event: Keyword.get(options, :adverse_event, false),
      child: child
    }
  end

  defp moh710_cell(form, code, label) do
    MinistryReporting.find_table_cell_id_by_code(
      form,
      "SECTION A",
      code,
      label,
      "Grand Total (Total Static + Total Outreach)"
    )
  end
end
