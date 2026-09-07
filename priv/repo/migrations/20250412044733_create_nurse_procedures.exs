defmodule Medcamp.Repo.Migrations.CreateNurseProcedures do
  use Ecto.Migration

  def change do
    create table(:nurse_procedures) do
      add :payment_type, :string
      add :has_paid, :boolean, default: false, null: false
      add :total_amount_paid, :integer
      add :procedure_id, references(:procedure, on_delete: :nothing)
      add :nurse_id, references(:users, on_delete: :nothing)
      add :patient_id, references(:patients, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:nurse_procedures, [:procedure_id])
    create index(:nurse_procedures, [:nurse_id])
    create index(:nurse_procedures, [:patient_id])
  end
end
