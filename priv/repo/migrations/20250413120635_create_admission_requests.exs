defmodule Medcamp.Repo.Migrations.CreateAdmissionRequests do
  use Ecto.Migration

  def change do
    create table(:admission_requests) do
      add :start_date, :date
      add :end_date, :date
      add :payment_type, :string
      add :total_amount_paid, :integer
      add :has_paid, :boolean, default: false, null: false
      add :doctor_note_id, references(:doctor_notes, on_delete: :nothing)
      add :patient_id, references(:patients, on_delete: :nothing)
      add :doctor_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:admission_requests, [:doctor_note_id])
    create index(:admission_requests, [:patient_id])
    create index(:admission_requests, [:doctor_id])
  end
end
