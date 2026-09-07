defmodule Medcamp.Repo.Migrations.AddParentIdToDoctorNotes do
  use Ecto.Migration

  def change do
    alter table(:doctor_notes) do
      add :parent_id, references(:doctor_notes, on_delete: :nilify_all), null: true
    end

    create index(:doctor_notes, [:parent_id])
  end
end
