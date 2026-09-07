defmodule Medcamp.Repo.Migrations.CreateQuoteItems do
  use Ecto.Migration

  def change do
    create table(:quote_items) do
      add :quote_id, references(:quotes, on_delete: :delete_all), null: false
      add :rfq_item_id, references(:rfq_items, on_delete: :restrict), null: false
      add :position, :integer
      add :unit, :string
      add :quantity_available, :decimal, precision: 15, scale: 3
      add :unit_price, :decimal, precision: 15, scale: 2
      add :total, :decimal, precision: 15, scale: 2
      add :brand_origin, :string
      add :expiry_date, :date

      timestamps(type: :utc_datetime)
    end

    create index(:quote_items, [:quote_id])
    create index(:quote_items, [:rfq_item_id])
  end
end
