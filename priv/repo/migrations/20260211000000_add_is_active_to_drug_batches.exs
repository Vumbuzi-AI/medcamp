defmodule Medcamp.Repo.Migrations.AddIsActiveToDrugBatches do
  use Ecto.Migration

  def change do
    alter table(:drug_batches) do
      add :is_active, :boolean, default: true
    end
  end
end
