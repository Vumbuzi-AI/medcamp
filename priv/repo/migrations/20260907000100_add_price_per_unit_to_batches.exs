defmodule Medcamp.Repo.Migrations.AddPricePerUnitToBatches do
  use Ecto.Migration

  def change do
    alter table(:batches) do
      add :price_per_unit, :integer, null: false, default: 0
    end
  end
end
