defmodule Medcamp.Repo.Migrations.RenameInsurerHumanDevelopmentFundAddUniversitySuffix do
  use Ecto.Migration

  @old_name "Human Development Fund"
  @new_name "Human Development Fund (Islamic University Of Kenya)"

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
