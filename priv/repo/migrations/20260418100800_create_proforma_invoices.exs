defmodule Medcamp.Repo.Migrations.CreateProformaInvoices do
  use Ecto.Migration

  def change do
    create table(:proforma_invoices) do
      add :reference, :string, null: false
      add :quote_id, references(:quotes, on_delete: :restrict), null: false
      add :supplier_id, references(:suppliers, on_delete: :restrict), null: false
      add :pi_date, :date
      add :valid_until, :date
      add :currency, :string, default: "KES"
      add :bill_to, :text
      add :ship_to, :text
      add :payment_instructions, :text
      add :subtotal, :decimal, precision: 15, scale: 2
      add :discount_amount, :decimal, precision: 15, scale: 2, default: 0
      add :vat_amount, :decimal, precision: 15, scale: 2
      add :total, :decimal, precision: 15, scale: 2
      add :status, :string, default: "draft", null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:proforma_invoices, [:reference])
    create index(:proforma_invoices, [:quote_id])
    create index(:proforma_invoices, [:supplier_id])
    create index(:proforma_invoices, [:status])
  end
end
