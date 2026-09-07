defmodule Medcamp.Repo.Migrations.AddInsuranceNameToLabResults do
  use Ecto.Migration

  def change do
    alter table(:lab_results) do
      add :insurance_name, :string
    end
  end
end
