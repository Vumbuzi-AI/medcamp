defmodule Medcamp.Repo.Migrations.AddAdminIdToRoomsAndType do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :type, :string
      add :name, :string
    end
  end
end
