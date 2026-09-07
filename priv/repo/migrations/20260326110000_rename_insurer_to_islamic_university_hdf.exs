defmodule Medcamp.Repo.Migrations.RenameInsurerToIslamicUniversityHdf do
  use Ecto.Migration

  @old_name "Human Development Fund (Islamic University Of Kenya)"
  @new_name "Islamic University of Kenya ( HDF)"

  @old_camp_name "Islamic University Of Kenya"
  @new_camp_name "Islamic University of Kenya ( HDF)"

  def up do
    execute(
      "UPDATE patient_visits    SET insurance_name = '#{@new_name}' WHERE insurance_name = '#{@old_name}'"
    )

    execute(
      "UPDATE drug_allocations  SET insurance_name = '#{@new_name}' WHERE insurance_name = '#{@old_name}'"
    )

    execute(
      "UPDATE doctor_procedures SET insurance_name = '#{@new_name}' WHERE insurance_name = '#{@old_name}'"
    )

    execute(
      "UPDATE nurse_procedures  SET insurance_name = '#{@new_name}' WHERE insurance_name = '#{@old_name}'"
    )

    execute(
      "UPDATE lab_results       SET insurance_name = '#{@new_name}' WHERE insurance_name = '#{@old_name}'"
    )

    execute(
      "UPDATE patients          SET medical_camp_name = '#{@new_camp_name}' WHERE medical_camp_name = '#{@old_camp_name}'"
    )
  end

  def down do
    execute(
      "UPDATE patient_visits    SET insurance_name = '#{@old_name}' WHERE insurance_name = '#{@new_name}'"
    )

    execute(
      "UPDATE drug_allocations  SET insurance_name = '#{@old_name}' WHERE insurance_name = '#{@new_name}'"
    )

    execute(
      "UPDATE doctor_procedures SET insurance_name = '#{@old_name}' WHERE insurance_name = '#{@new_name}'"
    )

    execute(
      "UPDATE nurse_procedures  SET insurance_name = '#{@old_name}' WHERE insurance_name = '#{@new_name}'"
    )

    execute(
      "UPDATE lab_results       SET insurance_name = '#{@old_name}' WHERE insurance_name = '#{@new_name}'"
    )

    execute(
      "UPDATE patients          SET medical_camp_name = '#{@old_camp_name}' WHERE medical_camp_name = '#{@new_camp_name}'"
    )
  end
end
