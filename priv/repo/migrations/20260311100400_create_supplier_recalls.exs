defmodule Medcamp.Repo.Migrations.CreateSupplierRecalls do
  use Ecto.Migration

  def change do
    create table(:supplier_recalls) do
      add :recall_number, :string, null: false
      add :recall_date, :date
      add :reason, :string
      add :description, :text
      add :affected_products, :text
      add :severity, :string, default: "medium"
      add :status, :string, default: "initiated"
      add :notes, :text
      add :supplier_id, references(:suppliers, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:supplier_recalls, [:supplier_id])
    create index(:supplier_recalls, [:status])
    create index(:supplier_recalls, [:severity])
  end
end
