defmodule Medcamp.Repo.Migrations.CreateProformaInvoiceItems do
  use Ecto.Migration

  def change do
    create table(:proforma_invoice_items) do
      add :proforma_invoice_id, references(:proforma_invoices, on_delete: :delete_all),
        null: false

      add :rfq_item_id, references(:rfq_items, on_delete: :nilify_all)
      add :position, :integer
      add :description, :text
      add :unit, :string
      add :quantity, :decimal, precision: 15, scale: 3
      add :unit_price, :decimal, precision: 15, scale: 2
      add :discount_percent, :decimal, precision: 5, scale: 2, default: 0
      add :discount_amount, :decimal, precision: 15, scale: 2, default: 0
      add :total, :decimal, precision: 15, scale: 2

      timestamps(type: :utc_datetime)
    end

    create index(:proforma_invoice_items, [:proforma_invoice_id])
  end
end
