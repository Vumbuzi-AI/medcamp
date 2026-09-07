defmodule Medcamp.Repo.Migrations.AddCategory do
  use Ecto.Migration

  def change do
    alter table(:inventories_received) do
      add :category, :string
    end
  end
end
