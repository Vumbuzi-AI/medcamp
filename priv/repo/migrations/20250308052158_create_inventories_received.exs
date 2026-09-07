defmodule Medcamp.Repo.Migrations.CreateInventoriesReceived do
  use Ecto.Migration

  def change do
    create table(:inventories_received) do
      add :gtin, :text
      add :brand_name, :string
      add :description, :text
      add :image, :text
      add :generic_name, :string
      add :weight, :string
      add :uom, :string
      add :supplier, :string
      add :quantity, :integer
      add :gln, :text
      add :type, :string
      add :location, :string
      add :price_per_unit, :integer
      add :inventory_manager_id, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end
  end
end
