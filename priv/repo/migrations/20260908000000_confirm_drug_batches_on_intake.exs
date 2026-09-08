defmodule Medcamp.Repo.Migrations.ConfirmDrugBatchesOnIntake do
  use Ecto.Migration

  def up do
    alter table(:drug_batches) do
      modify :is_confirmed, :boolean, default: true, null: false
    end

    execute "UPDATE drug_batches SET is_confirmed = TRUE WHERE is_confirmed IS DISTINCT FROM TRUE"
  end

  def down do
    alter table(:drug_batches) do
      modify :is_confirmed, :boolean, default: false, null: false
    end
  end
end
