defmodule Medcamp.Repo.Migrations.AddStrength do
  use Ecto.Migration

  def change do
    alter table(:inventories_received) do
      add :strength, :string
      add :uom, :string
      add :weight, :integer
    end
  end
end
