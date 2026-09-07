defmodule Medcamp.Repo.Migrations.CreateInvoiceItems do
  use Ecto.Migration

  def change do
    create table(:invoice_items) do
      add :invoice_id, references(:invoices, on_delete: :delete_all), null: false
      add :purchase_order_item_id, references(:purchase_order_items, on_delete: :nilify_all)
      add :position, :integer
      add :description, :text
      add :unit, :string
      add :quantity_delivered, :decimal, precision: 15, scale: 3
      add :unit_price, :decimal, precision: 15, scale: 2
      add :vat_rate, :decimal, precision: 5, scale: 4, default: 0.16
      add :vat_amount, :decimal, precision: 15, scale: 2
      add :total, :decimal, precision: 15, scale: 2

      timestamps(type: :utc_datetime)
    end

    create index(:invoice_items, [:invoice_id])
  end
end
