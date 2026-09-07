defmodule Medcamp.Repo.Migrations.AddHasBeenAssignedRoom do
  use Ecto.Migration

  def change do
    alter table(:admission_requests) do
      add :has_been_assigned_room, :boolean, default: false
    end
  end
end
