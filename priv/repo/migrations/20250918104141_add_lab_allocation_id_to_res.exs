defmodule Medcamp.Repo.Migrations.AddLabAllocationIdToRes do
  use Ecto.Migration

  def change do
    alter table(:lab_consumables) do
      add :lab_allocation_id, references(:lab_allocations, on_delete: :nothing)
    end
  end
end
