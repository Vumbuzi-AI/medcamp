defmodule Medcamp.Repo.Migrations.EditBatchAllocations do
  use Ecto.Migration

  def change do
    alter table(:batches) do
      remove :batch_allocations
    end

    alter table(:drugs_given) do
      add :batch_allocations, :jsonb, default: "[]"
    end
  end
end
