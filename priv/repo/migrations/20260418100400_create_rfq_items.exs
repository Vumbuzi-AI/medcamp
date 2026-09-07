defmodule Medcamp.Repo.Migrations.CreateRfqItems do
  use Ecto.Migration

  def change do
    create table(:rfq_items) do
      add :rfq_id, references(:rfqs, on_delete: :delete_all), null: false
      add :position, :integer
      add :description, :text
      add :category, :string
      add :unit, :string
      add :quantity_required, :decimal, precision: 15, scale: 3
      add :estimated_unit_price, :decimal, precision: 15, scale: 2

      timestamps(type: :utc_datetime)
    end

    create index(:rfq_items, [:rfq_id])
  end
end
