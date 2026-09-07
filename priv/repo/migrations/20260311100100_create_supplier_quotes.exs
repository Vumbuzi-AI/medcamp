defmodule Medcamp.Repo.Migrations.CreateSupplierQuotes do
  use Ecto.Migration

  def change do
    create table(:supplier_quotes) do
      add :quote_number, :string, null: false
      add :quote_date, :date
      add :expiry_date, :date
      add :amount, :decimal, precision: 15, scale: 2
      add :currency, :string, default: "KES"
      add :status, :string, default: "submitted"
      add :notes, :text
      add :file_path, :string
      add :original_filename, :string
      add :supplier_id, references(:suppliers, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:supplier_quotes, [:supplier_id])
    create index(:supplier_quotes, [:status])
  end
end
