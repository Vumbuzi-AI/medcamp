defmodule Medcamp.Repo.Migrations.RenameInsurerIslamicUniversityToHumanDevelopmentFund do
  use Ecto.Migration

  @old_name "Islamic University of Kenya"
  @new_name "Human Development Fund"

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
  end
end
