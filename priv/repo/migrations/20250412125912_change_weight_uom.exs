defmodule Medcamp.Repo.Migrations.ChangeWeightUom do
  use Ecto.Migration

  def change do
    alter table(:inventories_received) do
      remove :weight
      remove :uom
    end

    alter table(:batches) do
      add :weight, :float
      add :uom, :string
    end
  end
end
