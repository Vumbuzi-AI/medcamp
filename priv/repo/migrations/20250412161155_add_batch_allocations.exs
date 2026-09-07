defmodule Medcamp.Repo.Migrations.AddBatchAllocations do
  use Ecto.Migration

  def change do
    alter table(:batches) do
      add :batch_allocations, :jsonb, default: "[]"
    end
  end
end
