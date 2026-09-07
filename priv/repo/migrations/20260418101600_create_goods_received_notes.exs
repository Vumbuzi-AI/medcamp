defmodule Medcamp.Repo.Migrations.CreateGoodsReceivedNotes do
  use Ecto.Migration

  def change do
    create table(:goods_received_notes) do
      add :reference, :string, null: false
      add :purchase_order_id, references(:purchase_orders, on_delete: :restrict), null: false
      add :invoice_id, references(:invoices, on_delete: :restrict), null: false
      add :shipment_advice_id, references(:shipment_advices, on_delete: :restrict), null: false
      add :supplier_id, references(:suppliers, on_delete: :restrict), null: false
      add :received_date, :date
      add :received_time, :time
      add :received_by_id, references(:users, on_delete: :nilify_all)
      add :overall_condition, :string
      add :delivery_remarks, :text
      add :discrepancy_description, :text
      add :discrepancy_action, :string
      add :resolution_deadline, :date
      add :status, :string, default: "draft", null: false
      add :finalised_by_id, references(:users, on_delete: :nilify_all)
      add :finalised_at, :utc_datetime
      add :packages_received, :integer

      timestamps(type: :utc_datetime)
    end

    create unique_index(:goods_received_notes, [:reference])
    create index(:goods_received_notes, [:purchase_order_id])
    create index(:goods_received_notes, [:invoice_id])
    create index(:goods_received_notes, [:shipment_advice_id])
    create index(:goods_received_notes, [:supplier_id])
    create index(:goods_received_notes, [:status])
  end
end
