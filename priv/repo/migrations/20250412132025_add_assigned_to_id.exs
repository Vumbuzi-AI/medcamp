defmodule Medcamp.Repo.Migrations.AddAssignedToId do
  use Ecto.Migration

  def change do
    alter table(:inventories_issued) do
      add :assigned_to_id, references(:users, on_delete: :nothing)
    end
  end
end
