defmodule Medcamp.Repo.Migrations.EditInventoriesReceivedRemoveWeight do
  use Ecto.Migration

  def change do
    alter table(:inventories_received) do
      remove :weight
      remove :uom
    end
  end
end
