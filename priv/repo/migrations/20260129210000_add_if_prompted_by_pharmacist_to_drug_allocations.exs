defmodule Medcamp.Repo.Migrations.AddIfPromptedByPharmacistToDrugAllocations do
  use Ecto.Migration

  def change do
    alter table(:drug_allocations) do
      add :if_prompted_by_pharmacist, :boolean, default: false
    end
  end
end
