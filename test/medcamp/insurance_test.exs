defmodule Medcamp.InsuranceTest do
  use Medcamp.DataCase, async: true

  alias Medcamp.Insurance
  alias Medcamp.LabResults.LabResult
  alias Medcamp.PatientVisits.PatientVisit
  alias Medcamp.Patients.Patient

  describe "list_insurance_patients/2" do
    test "keeps hospital patients with valid records outside the camp dates" do
      keep_patient = insert_patient(%{first_name: "Keep"})
      insert_insurance_visit(keep_patient, "AAR")

      registered_during_camp_patient =
        insert_patient(%{
          first_name: "Registered",
          inserted_at: ~U[2026-03-28 08:15:00Z],
          updated_at: ~U[2026-03-28 08:15:00Z]
        })

      insert_insurance_visit(registered_during_camp_patient, "AAR")

      lab_activity_during_camp_patient = insert_patient(%{first_name: "Lab"})
      insert_insurance_visit(lab_activity_during_camp_patient, "AAR")
      insert_lab_result(lab_activity_during_camp_patient, ~D[2026-03-29])

      excluded_visit_patient = insert_patient(%{first_name: "ExcludedVisit"})
      insert_insurance_visit(excluded_visit_patient, "AAR", ~D[2026-03-28])

      flagged_medical_camp_patient =
        insert_patient(%{first_name: "Flagged", is_for_medical_camp: true})

      insert_insurance_visit(flagged_medical_camp_patient, "AAR")

      hospital_patient_ids =
        Insurance.list_insurance_patients("", %{source: "hospital"})
        |> Enum.map(& &1.id)

      assert Enum.sort(hospital_patient_ids) ==
               Enum.sort([
                 keep_patient.id,
                 registered_during_camp_patient.id,
                 lab_activity_during_camp_patient.id,
                 flagged_medical_camp_patient.id
               ])

      all_patient_ids =
        Insurance.list_insurance_patients()
        |> Enum.map(& &1.id)
        |> Enum.sort()

      assert all_patient_ids ==
               Enum.sort([
                 keep_patient.id,
                 registered_during_camp_patient.id,
                 lab_activity_during_camp_patient.id,
                 excluded_visit_patient.id,
                 flagged_medical_camp_patient.id
               ])
    end
  end

  describe "list_patients_for_insurer/2" do
    test "excludes only insurer records that fall on the camp dates" do
      keep_patient = insert_patient(%{first_name: "InsurerKeep"})
      insert_insurance_visit(keep_patient, "Britam")

      excluded_patient = insert_patient(%{first_name: "InsurerExcluded"})
      insert_insurance_visit(excluded_patient, "Britam", ~D[2026-03-28])
      insert_lab_result(excluded_patient, ~D[2026-03-28])

      included_after_camp_patient = insert_patient(%{first_name: "IncludedAfterCamp"})
      insert_insurance_visit(included_after_camp_patient, "Britam", ~D[2026-04-11])
      insert_lab_result(included_after_camp_patient, ~D[2026-03-28])

      other_insurer_patient = insert_patient(%{first_name: "OtherInsurer"})
      insert_insurance_visit(other_insurer_patient, "AAR")

      patient_ids =
        Insurance.list_patients_for_insurer("Britam", %{source: "hospital"})
        |> Enum.map(& &1.id)

      assert Enum.sort(patient_ids) ==
               Enum.sort([keep_patient.id, included_after_camp_patient.id])
    end
  end

  defp insert_patient(attrs \\ %{}) do
    unique = System.unique_integer([:positive])

    defaults = %{
      first_name: "Patient#{unique}",
      middle_name: nil,
      last_name: "Example",
      phone_number: "0700#{Integer.to_string(unique) |> String.pad_leading(6, "0")}",
      date_of_birth: ~D[1990-01-01],
      gender: "Female",
      home_address: "Test Address",
      gsrn: "6163000000000#{Integer.to_string(unique) |> String.pad_leading(5, "0")}",
      is_for_medical_camp: false,
      inserted_at: ~U[2026-03-20 09:00:00Z],
      updated_at: ~U[2026-03-20 09:00:00Z]
    }

    defaults
    |> Map.merge(attrs)
    |> then(&struct(Patient, &1))
    |> Repo.insert!()
  end

  defp insert_insurance_visit(patient, insurer_name, date \\ ~D[2026-04-10]) do
    %PatientVisit{
      patient_id: patient.id,
      date: date,
      time: ~T[09:30:00],
      reason: "Follow up",
      payment_type: "Insurance",
      insurance_name: insurer_name,
      total_amount_paid: 1500,
      has_paid: true,
      inserted_at: visit_inserted_at(date),
      updated_at: visit_inserted_at(date)
    }
    |> Repo.insert!()
  end

  defp insert_lab_result(patient, date_of_test) do
    %LabResult{
      patient_id: patient.id,
      name: "Camp Lab",
      date_of_test: date_of_test,
      urgency: "Routine",
      payment_type: "Cash",
      has_paid: true,
      report_complete: true,
      tests: [],
      inserted_at: ~U[2026-03-29 08:00:00Z],
      updated_at: ~U[2026-03-29 08:00:00Z]
    }
    |> Repo.insert!()
  end

  defp visit_inserted_at(date) do
    DateTime.new!(date, ~T[09:30:00], "Africa/Nairobi")
    |> DateTime.shift_zone!("Etc/UTC")
  end
end
