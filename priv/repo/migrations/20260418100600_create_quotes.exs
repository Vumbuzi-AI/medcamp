defmodule Medcamp.Repo.Migrations.CreateQuotes do
  use Ecto.Migration

  def change do
    create table(:quotes) do
      add :reference, :string, null: false
      add :rfq_id, references(:rfqs, on_delete: :restrict), null: false
      add :supplier_id, references(:suppliers, on_delete: :restrict), null: false
      add :quote_date, :date
      add :valid_until, :date
      add :lead_time_days, :integer
      add :delivery_terms, :string
      add :general_remarks, :text
      add :subtotal, :decimal, precision: 15, scale: 2
      add :vat_amount, :decimal, precision: 15, scale: 2
      add :vat_rate, :decimal, precision: 5, scale: 4, default: 0.16
      add :total, :decimal, precision: 15, scale: 2
      add :status, :string, default: "submitted", null: false
      add :compliance_score, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:quotes, [:reference])
    create unique_index(:quotes, [:rfq_id, :supplier_id])
    create index(:quotes, [:supplier_id])
    create index(:quotes, [:status])
  end
end
