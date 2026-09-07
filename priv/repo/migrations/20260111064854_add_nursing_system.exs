defmodule Medcamp.Repo.Migrations.AddNursingSystem do
  use Ecto.Migration

  def change do
    create table(:nursing_allocations) do
      add :allocated_quantity, :integer
      add :remaining_quantity, :integer
      add :uom, :string
      add :expiry_date, :date
      add :inventory_issued_id, references(:inventories_issued, on_delete: :nothing)
      add :allocated_by, references(:users, on_delete: :nothing)
      add :allocated_to, references(:users, on_delete: :nothing)
      timestamps(type: :utc_datetime)
    end

    create table(:nursing_consumables) do
      add :date, :date
      add :consumed_quantity, :integer
      add :purpose, :string
      add :patient_id, references(:patients, on_delete: :nothing)
      add :nursing_allocation_id, references(:nursing_allocations, on_delete: :delete_all)
      timestamps(type: :utc_datetime)
    end
  end
end
