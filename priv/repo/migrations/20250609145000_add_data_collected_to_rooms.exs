defmodule Medcamp.Repo.Migrations.AddDataCollectedToRooms do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :data_collected, :text
    end
  end
end
