defmodule Medcamp.Repo.Migrations.AddManufacturer do
  use Ecto.Migration

  def change do
    alter table(:general_inventory_items) do
      add :manufacturer, :string
    end
  end
end
