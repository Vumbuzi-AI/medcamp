defmodule Medcamp.Repo.Migrations.AddProfileDetails do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :experience, :string
      add :license_number, :string
      add :image, :string
    end
  end
end
