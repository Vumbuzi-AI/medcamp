defmodule Medcamp.Repo.Migrations.CreateSupplierInvoices do
  use Ecto.Migration

  def change do
    create table(:supplier_invoices) do
      add :invoice_number, :string, null: false
      add :invoice_date, :date
      add :due_date, :date
      add :amount, :decimal, precision: 15, scale: 2
      add :currency, :string, default: "KES"
      add :status, :string, default: "submitted"
      add :notes, :text
      add :file_path, :string
      add :original_filename, :string
      add :supplier_id, references(:suppliers, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:supplier_invoices, [:supplier_id])
    create index(:supplier_invoices, [:status])
  end
end
