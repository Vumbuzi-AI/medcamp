defmodule Medcamp.Repo.Migrations.AddBatchIdToDrugs do
  use Ecto.Migration

  def change do
    alter table(:drugs) do
      add :generic_name, :string
      add :brand_name, :string
      add :inventory_received_id, references(:inventories_received, on_delete: :nothing)
    end
  end
end
