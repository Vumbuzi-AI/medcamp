defmodule Medcamp.Repo.Migrations.CreateRoomAllocations do
  use Ecto.Migration

  def change do
    create table(:room_allocations) do
      add :start_date, :date
      add :end_date, :date
      add :payment_type, :string
      add :total_amount_paid, :integer
      add :has_paid, :boolean, default: false
      add :room_id, references(:rooms, on_delete: :nothing)
      add :patient_id, references(:patients, on_delete: :nothing)
      add :nurse_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:room_allocations, [:room_id])
    create index(:room_allocations, [:patient_id])
    create index(:room_allocations, [:nurse_id])
  end
end
