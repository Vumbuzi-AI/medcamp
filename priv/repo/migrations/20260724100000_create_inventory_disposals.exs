defmodule Medcamp.Repo.Migrations.CreateInventoryDisposals do
  use Ecto.Migration

  def change do
    create table(:inventory_disposals) do
      add :kind, :string, null: false
      add :date, :date, null: false
      add :reason, :text
      add :status, :string, null: false, default: "draft"
      add :supporting_document_path, :string
      add :supporting_document_name, :string
      add :requested_by_id, references(:users, on_delete: :nothing), null: false
      add :approved_by_id, references(:users, on_delete: :nothing)
      add :approved_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create constraint(:inventory_disposals, :inventory_disposals_kind_check,
             check: "kind IN ('donation', 'expiry')"
           )

    create constraint(:inventory_disposals, :inventory_disposals_status_check,
             check: "status IN ('draft', 'pending', 'approved', 'rejected')"
           )

    create index(:inventory_disposals, [:kind, :status])
    create index(:inventory_disposals, [:requested_by_id])
    create index(:inventory_disposals, [:approved_by_id])

    create table(:inventory_disposal_items) do
      add :entity_type, :string, null: false
      add :entity_id, :integer, null: false
      add :entity_name, :string, null: false
      add :category, :string
      add :available_quantity, :integer, null: false
      add :quantity, :integer, null: false
      add :uom, :string
      add :notes, :text
      add :has_been_applied, :boolean, null: false, default: false

      add :inventory_disposal_id,
          references(:inventory_disposals, on_delete: :delete_all),
          null: false

      timestamps(type: :utc_datetime)
    end

    create constraint(:inventory_disposal_items, :inventory_disposal_items_quantity_check,
             check: "quantity > 0"
           )

    create index(:inventory_disposal_items, [:inventory_disposal_id])

    create unique_index(
             :inventory_disposal_items,
             [:inventory_disposal_id, :entity_type, :entity_id],
             name: :inventory_disposal_items_unique_source
           )
  end
end
