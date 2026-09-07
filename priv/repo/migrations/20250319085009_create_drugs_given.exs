defmodule Medcamp.Repo.Migrations.CreateDrugsGiven do
  use Ecto.Migration

  def change do
    create table(:drugs_given) do
      add :quantity, :integer
      add :price, :integer
      add :drug_id, references(:drugs, on_delete: :nothing)
      add :drug_batch_id, references(:drug_batches, on_delete: :nothing)
      add :drug_allocation_id, references(:drug_allocations, on_delete: :nothing)
      add :pharmacist_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:drugs_given, [:drug_id])
    create index(:drugs_given, [:drug_batch_id])
    create index(:drugs_given, [:drug_allocation_id])
    create index(:drugs_given, [:pharmacist_id])
  end
end
