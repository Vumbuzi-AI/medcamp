defmodule Medcamp.Repo.Migrations.CreateCampAttendances do
  use Ecto.Migration

  # One row per (patient, camp): "this person attended this camp". A patient
  # record is reused across an organisation's camps; this table is what makes
  # "how many camps has this patient attended" and "new vs returning at this
  # camp" answerable, and it is the join the camp dashboard scopes patients by.
  def change do
    create table(:camp_attendances) do
      add :patient_id, references(:patients, on_delete: :delete_all), null: false
      add :camp_id, references(:camps, on_delete: :delete_all), null: false

      add :organisation_id, references(:organisations, on_delete: :delete_all),
        null: false

      add :first_seen_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:camp_attendances, [:patient_id, :camp_id])
    create index(:camp_attendances, [:camp_id])
    create index(:camp_attendances, [:organisation_id])
  end
end
