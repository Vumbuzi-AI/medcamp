defmodule Medcamp.Repo.Migrations.CreateCadexNotes do
  use Ecto.Migration

  def change do
    create table(:cadex_notes) do
      add :note_date, :date, null: false
      add :note_time, :time, null: false
      add :note, :text, null: false

      add :patient_id, references(:patients, on_delete: :delete_all), null: false
      add :nurse_id, references(:users, on_delete: :nilify_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:cadex_notes, [:patient_id])
    create index(:cadex_notes, [:nurse_id])
    create index(:cadex_notes, [:note_date])
  end
end
