defmodule Medcamp.Repo.Migrations.CreateStockTakeEntries do
  use Ecto.Migration

  def change do
    create table(:stock_take_entries) do
      add :entity_type, :string, null: false
      add :entity_id, :integer, null: false
      add :entity_name, :string, null: false
      add :category, :string
      add :previous_quantity, :integer, null: false
      add :counted_quantity, :integer
      add :difference, :integer
      add :notes, :text
      add :has_been_applied, :boolean, default: false, null: false
      add :stock_take_id, references(:stock_takes, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:stock_take_entries, [:stock_take_id])
    create index(:stock_take_entries, [:entity_type, :entity_id])
  end
end
