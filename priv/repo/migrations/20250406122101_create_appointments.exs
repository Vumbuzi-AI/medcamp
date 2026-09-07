defmodule Medcamp.Repo.Migrations.CreateAppointments do
  use Ecto.Migration

  def change do
    create table(:appointments) do
      add :date, :date
      add :time, :time
      add :reason, :string
      add :patient_id, references(:patients, on_delete: :nothing)
      add :doctor_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:appointments, [:patient_id])
    create index(:appointments, [:doctor_id])
  end
end
