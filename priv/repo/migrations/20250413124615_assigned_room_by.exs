defmodule Medcamp.Repo.Migrations.AssignedRoomBy do
  use Ecto.Migration

  def change do
    alter table(:admission_requests) do
      add :nurse_id, references(:users, on_delete: :nothing)
    end

    create index(:admission_requests, [:nurse_id])
  end
end
