defmodule Medcamp.Repo.Migrations.AddDetails do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :phone_number, :string
      add :id_number, :string
    end
  end
end
