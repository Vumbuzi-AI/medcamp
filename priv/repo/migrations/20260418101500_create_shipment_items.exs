defmodule Medcamp.Repo.Migrations.CreateShipmentItems do
  use Ecto.Migration

  def change do
    create table(:shipment_items) do
      add :shipment_advice_id, references(:shipment_advices, on_delete: :delete_all), null: false
      add :purchase_order_item_id, references(:purchase_order_items, on_delete: :nilify_all)
      add :position, :integer
      add :description, :text
      add :unit, :string
      add :quantity_shipped, :decimal, precision: 15, scale: 3
      add :batch_number, :string
      add :expiry_date, :date
      add :temperature_requirement, :string, default: "ambient"

      timestamps(type: :utc_datetime)
    end

    create index(:shipment_items, [:shipment_advice_id])
  end
end
