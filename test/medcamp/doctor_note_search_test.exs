defmodule Medcamp.DoctorNoteSearchTest do
  use Medcamp.DataCase

  import Medcamp.DoctorNotesFixtures
  import Medcamp.PatientsFixtures

  alias Medcamp.DoctorNoteSearch

  test "counts matching notes, occurrences and fields case-insensitively" do
    patient = patient_fixture(%{"date_of_birth" => ~D[2016-07-20], "gender" => "Female"})

    doctor_note_fixture(%{
      patient: patient,
      date: ~D[2026-07-15],
      symptoms: "Possible typhoid with a previous TYPHOID episode",
      diagnosis: "Typhoid fever"
    })

    doctor_note_fixture(%{
      patient: patient,
      date: ~D[2026-07-16],
      symptoms: "Headache only",
      diagnosis: "Migraine"
    })

    report =
      DoctorNoteSearch.search(%{
        query: "typhoid",
        date_from: ~D[2026-07-01],
        date_to: ~D[2026-07-31]
      })

    assert report.matching_notes == 1
    assert report.total_occurrences == 3
    assert report.unique_patients == 1
    assert [%{occurrence_count: 3, age: 9}] = report.matches
    assert Enum.find(report.field_counts, &(&1.label == "Symptoms / complaints")).count == 2
    assert Enum.find(report.field_counts, &(&1.label == "Diagnosis")).count == 1
  end

  test "filters matching patients by age on the note date and sex" do
    child = patient_fixture(%{"date_of_birth" => ~D[2022-08-04], "gender" => "Female"})
    adult = patient_fixture(%{"date_of_birth" => ~D[1990-01-01], "gender" => "Male"})

    doctor_note_fixture(%{patient: child, date: ~D[2026-08-03], diagnosis: "Typhoid"})
    doctor_note_fixture(%{patient: adult, date: ~D[2026-08-03], diagnosis: "Typhoid"})

    report =
      DoctorNoteSearch.search(%{
        query: "typhoid",
        date_from: ~D[2026-08-01],
        date_to: ~D[2026-08-31],
        age_from: 0,
        age_to: 4,
        sex: "female"
      })

    assert report.matching_notes == 1
    assert [%{age: 3, note: %{patient_id: patient_id}}] = report.matches
    assert patient_id == child.id
  end

  test "returns an empty report without executing a broad search for a blank query" do
    assert %{query: "", matching_notes: 0, total_occurrences: 0, matches: []} =
             DoctorNoteSearch.search(%{query: "  "})
  end
end
