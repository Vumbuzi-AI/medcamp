defmodule Medcamp.Repo.Migrations.AddAssignedTo do
  use Ecto.Migration

  def change do
    alter table(:batches) do
      add :assigned_to, references(:users, on_delete: :nothing)
    end

    alter table(:inventories_received) do
      add :user_id, references(:users, on_delete: :nothing)
    end
  end
end
