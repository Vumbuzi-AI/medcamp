defmodule Medcamp.Repo.Migrations.ModifyExperience do
  use Ecto.Migration

  def change do
    alter table(:users) do
      modify :experience, :text
    end
  end
end
