defmodule Medcamp.Repo.Migrations.CreatePurchaseOrders do
  use Ecto.Migration

  def change do
    create table(:purchase_orders) do
      add :reference, :string, null: false
      add :rfq_id, references(:rfqs, on_delete: :nilify_all)
      add :proforma_invoice_id, references(:proforma_invoices, on_delete: :nilify_all)
      add :supplier_id, references(:suppliers, on_delete: :restrict), null: false
      add :po_date, :date
      add :expected_delivery_date, :date
      add :currency, :string, default: "KES"
      add :payment_terms, :string
      add :delivery_address, :text
      add :subtotal, :decimal, precision: 15, scale: 2
      add :vat_amount, :decimal, precision: 15, scale: 2
      add :total, :decimal, precision: 15, scale: 2
      add :status, :string, default: "draft", null: false
      add :approved_by_id, references(:users, on_delete: :nilify_all)
      add :approved_at, :utc_datetime
      add :acknowledged_at, :utc_datetime
      add :created_by_id, references(:users, on_delete: :nilify_all)
      add :checklist_prices_confirmed, :boolean, default: false, null: false
      add :checklist_vendor_approved, :boolean, default: false, null: false
      add :checklist_delivery_verified, :boolean, default: false, null: false
      add :checklist_budget_approved, :boolean, default: false, null: false
      add :checklist_hod_signoff, :boolean, default: false, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:purchase_orders, [:reference])
    create index(:purchase_orders, [:rfq_id])
    create index(:purchase_orders, [:supplier_id])
    create index(:purchase_orders, [:status])
    create index(:purchase_orders, [:approved_by_id])
  end
end
