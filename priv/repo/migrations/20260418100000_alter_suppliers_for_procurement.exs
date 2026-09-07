defmodule Medcamp.Repo.Migrations.AlterSuppliersForProcurement do
  use Ecto.Migration

  def change do
    alter table(:suppliers) do
      add :reference, :string
      add :legal_name, :string
      add :nature_of_business, :string
      add :years_in_operation, :integer
      add :country, :string
      add :product_categories, {:array, :string}, default: []
      add :street_address, :string
      add :city, :string
      add :county, :string
      add :po_box, :string
      add :contact_first_name, :string
      add :contact_last_name, :string
      add :contact_email, :string
      add :contact_telephone, :string
      add :account_name, :string
      add :account_number, :string
      add :bank_name, :string
      add :bank_branch, :string
      add :swift_code, :string
      add :currency, :string, default: "KES"
      add :payment_terms, :string, default: ""
      add :kra_pin, :string
      add :status, :string, default: "pending", null: false
      add :compliance_score, :integer
      add :approved_by_id, references(:users, on_delete: :nilify_all)
      add :approved_at, :utc_datetime
      add :rejection_reason, :text
    end

    create unique_index(:suppliers, [:reference])
    create index(:suppliers, [:status])
    create index(:suppliers, [:approved_by_id])
  end
end
