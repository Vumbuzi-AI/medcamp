defmodule Medcamp.Repo.Migrations.AddCost do
  use Ecto.Migration

  def change do
    alter table(:batches) do
      add :cost, :integer
    end
  end
end
