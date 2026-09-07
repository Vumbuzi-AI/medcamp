defmodule Medcamp.Repo.Migrations.AddLabAllocationId do
  use Ecto.Migration

  def change do
    alter table(:lab_results) do
      add :lab_allocation_id, references(:lab_allocations, on_delete: :nothing)
    end
  end
end
