defmodule Medcamp.Repo.Migrations.CreatePatientCharges do
  use Ecto.Migration

  def change do
    alter table(:nursing_consumables) do
      add :doctor_note_id, references(:doctor_notes, on_delete: :nilify_all)
    end

    create index(:nursing_consumables, [:doctor_note_id])

    create table(:patient_charge_batches) do
      add :doctor_note_id, references(:doctor_notes, on_delete: :delete_all), null: false
      add :patient_id, references(:patients, on_delete: :delete_all), null: false
      add :created_by_id, references(:users, on_delete: :nilify_all)
      add :total_amount, :integer, null: false, default: 0
      add :status, :string, null: false, default: "pending"
      add :paid_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:patient_charge_batches, [:doctor_note_id])
    create index(:patient_charge_batches, [:patient_id])
    create index(:patient_charge_batches, [:status])

    create table(:patient_charges) do
      add :description, :string, null: false
      add :quantity, :integer, null: false
      add :unit_price, :integer, null: false, default: 0
      add :total_price, :integer, null: false, default: 0
      add :status, :string, null: false, default: "pending_review"
      add :approved_at, :utc_datetime
      add :paid_at, :utc_datetime
      add :waived_at, :utc_datetime
      add :patient_id, references(:patients, on_delete: :delete_all), null: false
      add :doctor_note_id, references(:doctor_notes, on_delete: :delete_all), null: false

      add :nursing_consumable_id, references(:nursing_consumables, on_delete: :delete_all),
        null: false

      add :patient_charge_batch_id, references(:patient_charge_batches, on_delete: :nilify_all)
      add :created_by_id, references(:users, on_delete: :nilify_all)
      add :approved_by_id, references(:users, on_delete: :nilify_all)
      add :waived_by_id, references(:users, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:patient_charges, [:doctor_note_id])
    create index(:patient_charges, [:patient_id])
    create index(:patient_charges, [:status])
    create index(:patient_charges, [:patient_charge_batch_id])
    create unique_index(:patient_charges, [:nursing_consumable_id])
  end
end
