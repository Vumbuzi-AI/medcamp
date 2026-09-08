defmodule Medcamp.Repo.Migrations.AddBillingFieldsToDrugAllocations do
  use Ecto.Migration

  def change do
    alter table(:drug_allocations) do
      add :payment_type, :string
      add :insurance_name, :string
      add :total_amount_paid, :integer
      add :has_paid, :boolean, null: false, default: false
      add :excluded_from_insurance_invoice, :boolean, null: false, default: false
    end
  end
end
