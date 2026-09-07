defmodule Medcamp.Repo.Migrations.AddGtinToInv do
  use Ecto.Migration

  def change do
    alter table(:general_inventory_items) do
      add :gtin, :string
    end
  end
end
