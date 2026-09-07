defmodule Medcamp.Repo.Migrations.AddClinicalNotes do
  use Ecto.Migration

  def change do
    alter table(:doctor_notes) do
      add :clinical_notes, :text
      add :impression, :text
    end
  end
end
