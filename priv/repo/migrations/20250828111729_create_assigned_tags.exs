defmodule Medcamp.Repo.Migrations.CreateAssignedTags do
  use Ecto.Migration

  def change do
    create table(:assigned_tags) do
      add :number, :integer
      add :date, :date
      add :remaining_number, :integer
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:assigned_tags, [:user_id])
  end
end
