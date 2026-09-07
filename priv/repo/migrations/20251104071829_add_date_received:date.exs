defmodule Medcamp.Repo.Migrations.AddDateReceivedDate do
  use Ecto.Migration

  def change do
    alter table(:general_inventory_items) do
      add :date_received, :date
    end
  end
end
