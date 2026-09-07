defmodule Medcamp.Repo.Migrations.CreateGeneralInventoryTransactions do
  use Ecto.Migration

  def change do
    create table(:general_inventory_transactions) do
      add :transaction_type, :string
      add :quantity, :decimal
      add :reason, :string
      add :notes, :text
      add :recorded_by, :string
      add :transaction_date, :date
      add :general_inventory_item_id, references(:general_inventory_items, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:general_inventory_transactions, [:general_inventory_item_id])
    create index(:general_inventory_transactions, [:user_id])
  end
end
