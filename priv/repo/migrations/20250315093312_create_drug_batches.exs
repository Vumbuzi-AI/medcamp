defmodule Medcamp.Repo.Migrations.CreateDrugBatches do
  use Ecto.Migration

  def change do
    create table(:drug_batches) do
      add :remaining_quantity, :integer
      add :drug_id, references(:drugs, on_delete: :nothing)
      add :batch_id, references(:batches, on_delete: :nothing)
      add :inventory_manager_id, references(:users, on_delete: :nothing)
      add :inventory_received_id, references(:inventories_received, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:drug_batches, [:drug_id])
    create index(:drug_batches, [:batch_id])
    create index(:drug_batches, [:inventory_manager_id])
    create index(:drug_batches, [:inventory_received_id])
  end
end
