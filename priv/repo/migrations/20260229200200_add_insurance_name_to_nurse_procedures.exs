defmodule Medcamp.Repo.Migrations.AddInsuranceNameToNurseProcedures do
  use Ecto.Migration

  def change do
    alter table(:nurse_procedures) do
      add :insurance_name, :string
    end
  end
end
