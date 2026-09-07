defmodule Medcamp.Repo.Migrations.AddCountedAllocatedQuantityToStockTakeEntries do
  use Ecto.Migration

  def change do
    alter table(:stock_take_entries) do
      add :counted_allocated_quantity, :integer
    end
  end
end
