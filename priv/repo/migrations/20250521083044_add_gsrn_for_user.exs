defmodule Medcamp.Repo.Migrations.AddGsrnForUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :gsrn, :text
    end
  end
end
