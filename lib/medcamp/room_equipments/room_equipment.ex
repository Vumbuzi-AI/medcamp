defmodule Medcamp.RoomEquipments.RoomEquipment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "room_equipments" do
    field :name, :string
    field :description, :string
    field :image, :string
    belongs_to :room, Medcamp.Rooms.Room

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room_equipment, attrs) do
    room_equipment
    |> cast(attrs, [:name, :description, :image, :room_id])
    |> validate_required([:name, :description, :room_id])
  end
end
