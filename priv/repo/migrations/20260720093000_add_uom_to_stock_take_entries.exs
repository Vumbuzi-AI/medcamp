defmodule Medcamp.Repo.Migrations.AddUomToStockTakeEntries do
  use Ecto.Migration

  def change do
    alter table(:stock_take_entries) do
      add :uom, :string
    end
  end
end
