defmodule Medcamp.Repo.Migrations.CreateInvoices do
  use Ecto.Migration

  def change do
    create table(:invoices) do
      add :reference, :string, null: false
      add :purchase_order_id, references(:purchase_orders, on_delete: :restrict), null: false
      add :supplier_id, references(:suppliers, on_delete: :restrict), null: false
      add :invoice_date, :date
      add :due_date, :date
      add :currency, :string, default: "KES"
      add :supplier_pin, :string
      add :bill_to, :text
      add :subtotal, :decimal, precision: 15, scale: 2
      add :vat_amount, :decimal, precision: 15, scale: 2
      add :total, :decimal, precision: 15, scale: 2
      add :invoice_document_path, :string
      add :status, :string, default: "draft", null: false
      add :approved_by_id, references(:users, on_delete: :nilify_all)
      add :approved_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:invoices, [:reference])
    create index(:invoices, [:purchase_order_id])
    create index(:invoices, [:supplier_id])
    create index(:invoices, [:status])
  end
end
