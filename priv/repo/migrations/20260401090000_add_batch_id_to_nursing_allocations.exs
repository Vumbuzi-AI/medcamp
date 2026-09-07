defmodule Medcamp.Repo.Migrations.AddBatchIdToNursingAllocations do
  use Ecto.Migration

  def change do
    alter table(:nursing_allocations) do
      add :batch_id, references(:batches, on_delete: :nothing), null: true
    end
  end
end
