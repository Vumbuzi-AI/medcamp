defmodule Medcamp.Repo.Migrations.EditInventoriesReceived do
  use Ecto.Migration

  def change do
    alter table(:inventories_received) do
      remove :location
      remove :gln
      remove :price_per_unit
      remove :quantity

      add :room_id, references(:rooms, on_delete: :nothing)
    end
  end
end
