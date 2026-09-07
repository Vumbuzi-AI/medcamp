defmodule Medcamp.Repo.Migrations.MakeText do
  use Ecto.Migration

  def change do
    alter table(:lab_consumables) do
      modify :purpose, :text
    end
  end
end
