defmodule Medcamp.Repo.Migrations.AddExcludedFromInsuranceInvoiceToBillableRecords do
  use Ecto.Migration

  def change do
    alter table(:patient_visits) do
      add :excluded_from_insurance_invoice, :boolean, default: false, null: false
    end

    alter table(:drug_allocations) do
      add :excluded_from_insurance_invoice, :boolean, default: false, null: false
    end

    alter table(:nurse_procedures) do
      add :excluded_from_insurance_invoice, :boolean, default: false, null: false
    end

    alter table(:doctor_procedures) do
      add :excluded_from_insurance_invoice, :boolean, default: false, null: false
    end

    alter table(:lab_results) do
      add :excluded_from_insurance_invoice, :boolean, default: false, null: false
    end
  end
end
