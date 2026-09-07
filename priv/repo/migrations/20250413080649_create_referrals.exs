defmodule Medcamp.Repo.Migrations.CreateReferrals do
  use Ecto.Migration

  def change do
    create table(:referrals) do
      add :date, :date
      add :time, :time
      add :referral_note, :text
      add :hospital, :string
      add :doctor_id, references(:users, on_delete: :nothing)
      add :patient_id, references(:patients, on_delete: :nothing)
      add :doctor_note_id, references(:doctor_notes, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:referrals, [:doctor_id])
    create index(:referrals, [:patient_id])
    create index(:referrals, [:doctor_note_id])
  end
end
