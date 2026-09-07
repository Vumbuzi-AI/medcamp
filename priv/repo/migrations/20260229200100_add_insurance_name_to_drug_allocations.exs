defmodule Medcamp.Repo.Migrations.AddInsuranceNameToDrugAllocations do
  use Ecto.Migration

  def change do
    alter table(:drug_allocations) do
      add :insurance_name, :string
    end
  end
end
