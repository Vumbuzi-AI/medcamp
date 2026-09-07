defmodule Medcamp.Repo.Migrations.ModifyText do
  use Ecto.Migration

  def change do
    alter table(:appointments) do
      modify :reason, :text
    end
  end
end
