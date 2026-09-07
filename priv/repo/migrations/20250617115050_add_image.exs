defmodule Medcamp.Repo.Migrations.AddImage do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :image, :text
    end
  end
end
