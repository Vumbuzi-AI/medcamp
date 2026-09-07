defmodule Medcamp.Repo.Migrations.CreateSupplierDeliveryNotes do
  use Ecto.Migration

  def change do
    create table(:supplier_delivery_notes) do
      add :delivery_note_number, :string, null: false
      add :delivery_date, :date
      add :status, :string, default: "submitted"
      add :notes, :text
      add :file_path, :string
      add :original_filename, :string
      add :supplier_id, references(:suppliers, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:supplier_delivery_notes, [:supplier_id])
    create index(:supplier_delivery_notes, [:status])
  end
end
