defmodule Medcamp.Repo.Migrations.CreateGrnItems do
  use Ecto.Migration

  def change do
    create table(:grn_items) do
      add :grn_id, references(:goods_received_notes, on_delete: :delete_all), null: false

      add :purchase_order_item_id, references(:purchase_order_items, on_delete: :restrict),
        null: false

      add :position, :integer
      add :description, :text
      add :po_quantity, :decimal, precision: 15, scale: 3
      add :quantity_received, :decimal, precision: 15, scale: 3
      add :variance, :decimal, precision: 15, scale: 3
      add :batch_number, :string
      add :expiry_date, :date
      add :condition, :string, default: "accepted", null: false

      timestamps(type: :utc_datetime)
    end

    create index(:grn_items, [:grn_id])
  end
end
