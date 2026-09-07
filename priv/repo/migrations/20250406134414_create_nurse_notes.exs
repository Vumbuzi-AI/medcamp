defmodule Medcamp.Repo.Migrations.CreateNurseNotes do
  use Ecto.Migration

  def change do
    create table(:nurse_notes) do
      add :content, :text
      add :patient_id, references(:patients, on_delete: :nothing)
      add :nurse_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:nurse_notes, [:patient_id])
    create index(:nurse_notes, [:nurse_id])
  end
end
