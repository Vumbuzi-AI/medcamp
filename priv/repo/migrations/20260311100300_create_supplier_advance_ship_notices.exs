defmodule Medcamp.Repo.Migrations.CreateSupplierAdvanceShipNotices do
  use Ecto.Migration

  def change do
    create table(:supplier_advance_ship_notices) do
      add :asn_number, :string, null: false
      add :ship_date, :date
      add :expected_delivery_date, :date
      add :status, :string, default: "submitted"
      add :notes, :text
      add :file_path, :string
      add :original_filename, :string
      add :supplier_id, references(:suppliers, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:supplier_advance_ship_notices, [:supplier_id])
    create index(:supplier_advance_ship_notices, [:status])
  end
end
