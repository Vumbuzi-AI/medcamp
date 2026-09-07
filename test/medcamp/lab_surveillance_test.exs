defmodule Medcamp.LabSurveillanceTest do
  use Medcamp.DataCase, async: true

  alias Medcamp.LabResults.LabResult
  alias Medcamp.LabSurveillance
  alias Medcamp.LabTestTemplates.{LabTestEntry, LabTestTemplate}
  alias Medcamp.Patients.Patient

  test "returns an empty report when no completed tests match" do
    assert %{rows: [], test_names: [], totals: %{total_tested: 0}} =
             LabSurveillance.report(%{
               date_from: ~D[2026-08-01],
               date_to: ~D[2026-08-31],
               test_name: "",
               age_group: ""
             })
  end

  test "groups completed tests into report-ready age and positive-result columns" do
    entries = [
      entry("Malaria MRDT", "Positive", ~D[2022-08-04]),
      entry("Malaria MRDT", "Negative", ~D[2021-08-03]),
      entry("Malaria MRDT", "P. falciparum (+)", ~D[1990-01-01]),
      entry("Typhoid", "Negative", ~D[1988-01-01])
    ]

    report = LabSurveillance.aggregate(entries)

    assert [malaria, typhoid] = report.rows
    assert malaria.test_name == "Malaria MRDT"
    assert malaria.under_five_tested == 1
    assert malaria.under_five_positive == 1
    assert malaria.five_plus_tested == 2
    assert malaria.five_plus_positive == 1
    assert malaria.total_tested == 3
    assert malaria.total_positive == 2

    assert typhoid.test_name == "Typhoid"
    assert report.totals.total_tested == 4
    assert report.totals.total_positive == 2
  end

  test "filters by test and age group" do
    entries = [
      entry("Malaria Microscopy", "Positive", ~D[2022-08-04]),
      entry("Malaria Microscopy", "Negative", ~D[1990-01-01]),
      entry("Dysentery", "Positive", ~D[2022-01-01])
    ]

    report =
      LabSurveillance.aggregate(entries, %{
        test_name: "Malaria Microscopy",
        age_group: "under_five"
      })

    assert [%{test_name: "Malaria Microscopy", total_tested: 1, total_positive: 1}] =
             report.rows
  end

  test "treats explicit negative phrases as negative before matching detected or present" do
    entries = [
      entry("Malaria Microscopy", "No Malaria Parasites Seen", ~D[1990-01-01]),
      entry("HIV", "Not detected", ~D[1990-01-01]),
      entry("HIV", "Non reactive", ~D[1990-01-01])
    ]

    assert LabSurveillance.aggregate(entries).totals.total_positive == 0
  end

  defp entry(name, result, birth_date) do
    %LabTestEntry{
      status: "completed",
      results: %{"result" => %{"value" => result}},
      test_performed_on: ~D[2026-08-03],
      inserted_at: ~U[2026-08-03 08:00:00Z],
      template: %LabTestTemplate{name: name},
      lab_result: %LabResult{
        date_of_test: ~D[2026-08-03],
        patient: %Patient{date_of_birth: birth_date}
      }
    }
  end
end
