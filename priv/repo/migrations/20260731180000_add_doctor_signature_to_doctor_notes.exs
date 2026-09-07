defmodule Medcamp.Repo.Migrations.AddDoctorSignatureToDoctorNotes do
  use Ecto.Migration

  def change do
    alter table(:doctor_notes) do
      add :doctor_signature, :text
      add :signed_at, :utc_datetime
    end
  end
end
