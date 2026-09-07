defmodule Medcamp.Repo.Migrations.AddInsuranceNameToDoctorProcedures do
  use Ecto.Migration

  def change do
    alter table(:doctor_procedures) do
      add :insurance_name, :string
    end
  end
end
