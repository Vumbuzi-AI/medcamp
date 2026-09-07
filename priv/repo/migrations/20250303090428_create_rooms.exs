defmodule Medcamp.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add :room_number, :string
      add :is_free, :boolean, default: false, null: false
      add :added_by, references(:users, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:rooms, [:added_by])
  end
end
