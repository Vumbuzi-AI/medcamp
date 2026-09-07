defmodule Medcamp.DoctorNotes.QualityTest do
  use ExUnit.Case, async: true

  alias Medcamp.Accounts.User
  alias Medcamp.DoctorNotes.DoctorNote
  alias Medcamp.DoctorNotes.Quality

  test "evaluates blank and populated core fields" do
    evaluation =
      Quality.evaluate(%DoctorNote{
        reason_for_consulatation: "Fever",
        impression: "  ",
        investigations: nil
      })

    refute evaluation.complete?
    assert evaluation.completion_percentage == 16.7
    assert :impression in evaluation.missing_fields
    assert :investigations in evaluation.missing_fields
    refute :reason_for_consulatation in evaluation.missing_fields
  end

  test "summarizes overall and per-doctor quality percentages" do
    doctor = %User{id: 9, name: "Amina Noor"}

    complete =
      %DoctorNote{doctor_id: doctor.id, doctor: doctor}
      |> fill_fields("Documented")

    incomplete = %DoctorNote{
      doctor_id: doctor.id,
      doctor: doctor,
      reason_for_consulatation: "Cough",
      impression: "Pneumonia"
    }

    quality = Quality.summarize([complete, incomplete])

    assert quality.total_notes == 2
    assert quality.complete_notes == 1
    assert quality.complete_percentage == 50.0
    assert quality.missing_impression == 0
    assert quality.missing_investigations == 1

    assert [doctor_quality] = quality.by_doctor
    assert doctor_quality.doctor_name == "Amina Noor"
    assert doctor_quality.complete_percentage == 50.0
    assert doctor_quality.missing_investigations_percentage == 50.0
  end

  test "returns zero percentages when there are no notes" do
    quality = Quality.summarize([])

    assert quality.total_notes == 0
    assert quality.complete_percentage == 0.0
    assert quality.average_completion == 0.0
    assert quality.by_doctor == []
  end

  defp fill_fields(note, value) do
    Enum.reduce(Quality.fields(), note, fn {field, _label}, note ->
      Map.put(note, field, value)
    end)
  end
end
