defmodule Medcamp.Repo.Migrations.CreateRequisitions do
  use Ecto.Migration

  def change do
    create table(:requisitions) do
      add :title, :string
      add :description, :text
      add :status, :string, default: "pending"
      add :notes, :text
      add :requested_at, :utc_datetime
      add :responded_at, :utc_datetime
      add :requested_by_id, references(:users, on_delete: :nothing)
      add :requested_from_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:requisitions, [:requested_by_id])
    create index(:requisitions, [:requested_from_id])
    create index(:requisitions, [:status])
  end
end
