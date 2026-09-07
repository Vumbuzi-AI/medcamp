defmodule Medcamp.Repo.Migrations.CreateGeneralInventoryItems do
  use Ecto.Migration

  def change do
    create table(:general_inventory_items) do
      add :name, :string
      add :category, :string
      add :unit_of_measure, :string
      add :current_quantity, :decimal
      add :reorder_level, :decimal
      add :unit_cost, :decimal
      add :supplier, :string
      add :notes, :text
      add :room_id, references(:rooms, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:general_inventory_items, [:room_id])
  end
end
