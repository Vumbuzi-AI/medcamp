defmodule Medcamp.Repo.Migrations.AddGsrn do
  use Ecto.Migration

  def change do
    alter table(:patients) do
      add :gsrn, :text
    end
  end
end
