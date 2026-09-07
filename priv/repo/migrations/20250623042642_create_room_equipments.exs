defmodule Medcamp.Repo.Migrations.CreateRoomEquipments do
  use Ecto.Migration

  def change do
    create table(:room_equipments) do
      add :name, :string
      add :description, :text
      add :image, :string
      add :room_id, references(:rooms, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:room_equipments, [:room_id])
  end
end
