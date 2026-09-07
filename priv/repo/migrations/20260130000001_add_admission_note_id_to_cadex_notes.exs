defmodule Medcamp.Repo.Migrations.AddAdmissionNoteIdToCadexNotes do
  use Ecto.Migration

  def change do
    alter table(:cadex_notes) do
      add :admission_note_id, references(:admission_notes, on_delete: :delete_all)
    end

    create index(:cadex_notes, [:admission_note_id])
  end
end
