defmodule Medcamp.Repo.Migrations.CreatePatientVisits do
  use Ecto.Migration

  def change do
    create table(:patient_visits) do
      add :date, :date
      add :time, :time
      add :reason, :string
      add :visit_type, :string
      add :total_amount_paid, :integer
      add :patient_id, references(:patients, on_delete: :nothing)
      add :creator_id, references(:users, on_delete: :nothing)
      add :doctor_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:patient_visits, [:patient_id])
    create index(:patient_visits, [:creator_id])
    create index(:patient_visits, [:doctor_id])
  end
end
