defmodule Medcamp.Repo.Migrations.AddUomAndWeight do
  use Ecto.Migration

  def change do
    alter table(:inventories_received) do
      add :weight, :float
      add :uom, :string
    end
  end
end
