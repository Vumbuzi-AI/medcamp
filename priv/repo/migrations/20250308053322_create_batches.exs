defmodule Medcamp.Repo.Migrations.CreateBatches do
  use Ecto.Migration

  def change do
    create table(:batches) do
      add :gtin, :string
      add :batch, :string
      add :expiry, :string
      add :manufacturer, :string
      add :serial, :string
      add :quantity, :string
      add :price_per_unit, :integer
      add :has_been_issued, :boolean, default: false
      add :inventory_received_id, references(:inventories_received, on_delete: :nothing)
      add :inventory_manager_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:batches, [:inventory_received_id])
    create index(:batches, [:inventory_manager_id])
  end
end
