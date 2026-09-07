defmodule Medcamp.Repo.Migrations.CreateLabAllocations do
  use Ecto.Migration

  def change do
    create table(:lab_allocations) do
      add :allocated_quantity, :integer
      add :remaining_quantity, :integer
      add :uom, :string
      add :expiry_date, :date
      add :inventory_issued_id, references(:inventories_issued, on_delete: :nothing)
      add :allocated_by, references(:users, on_delete: :nothing)
      add :allocated_to, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:lab_allocations, [:inventory_issued_id])
    create index(:lab_allocations, [:allocated_by])
    create index(:lab_allocations, [:allocated_to])
  end
end
