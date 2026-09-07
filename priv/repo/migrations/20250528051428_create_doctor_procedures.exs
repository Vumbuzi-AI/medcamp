defmodule Medcamp.Repo.Migrations.CreateDoctorProcedures do
  use Ecto.Migration

  def change do
    create table(:doctor_procedures) do
      add :payment_type, :string
      add :has_paid, :boolean, default: false, null: false
      add :total_amount_paid, :integer
      add :procedure_id, references(:procedure, on_delete: :nothing)
      add :doctor_id, references(:users, on_delete: :nothing)
      add :patient_id, references(:patients, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:doctor_procedures, [:procedure_id])
    create index(:doctor_procedures, [:doctor_id])
    create index(:doctor_procedures, [:patient_id])
  end
end
