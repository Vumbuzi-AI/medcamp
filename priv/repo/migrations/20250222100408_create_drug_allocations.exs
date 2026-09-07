defmodule Medcamp.Repo.Migrations.CreateDrugAllocations do
  use Ecto.Migration

  def change do
    create table(:drug_allocations) do
      add :quantity, :integer
      add :prescription, :text
      add :drugs_assigned, :jsonb, default: "[]"
      add :has_been_assigned, :boolean, default: false
      add :payment_type, :string
      add :total_amount_paid, :integer
      add :has_paid, :boolean, default: false
      add :patient_id, references(:drugs, on_delete: :nothing)
      add :pharmacist_id, references(:users, on_delete: :nothing)
      add :doctor_note_id, references(:doctor_notes, on_delete: :nothing)
      add :doctor_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:drug_allocations, [:patient_id])

    create index(:drug_allocations, [:pharmacist_id])

    create index(:drug_allocations, [:doctor_note_id])

    create index(:drug_allocations, [:doctor_id])
  end
end
