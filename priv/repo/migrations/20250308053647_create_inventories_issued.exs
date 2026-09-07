defmodule Medcamp.Repo.Migrations.CreateInventoriesIssued do
  use Ecto.Migration

  def change do
    create table(:inventories_issued) do
      add :gtin, :string
      add :quantity, :integer
      add :description, :text
      add :location, :string
      add :batch_id, references(:batches, on_delete: :nothing)
      add :inventory_received_id, references(:inventories_received, on_delete: :nothing)
      add :inventory_manager_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:inventories_issued, [:batch_id])
    create index(:inventories_issued, [:inventory_manager_id])
    create index(:inventories_issued, [:inventory_received_id])
  end
end
