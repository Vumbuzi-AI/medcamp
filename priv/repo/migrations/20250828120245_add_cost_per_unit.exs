defmodule Medcamp.Repo.Migrations.AddCostPerUnit do
  use Ecto.Migration

  def change do
    alter table(:batches) do
      add :cost_per_unit, :integer
    end
  end
end
