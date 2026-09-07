defmodule Medcamp.Rooms.Room do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rooms" do
    field :room_number, :string
    field :is_free, :boolean, default: false
    field :description, :string
    field :data_collected, :string
    field :type, :string
    field :image, :string

    field :name, :string
    belongs_to :user, Medcamp.Accounts.User, foreign_key: :added_by
    has_many :room_equipments, Medcamp.RoomEquipments.RoomEquipment

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [
      :room_number,
      :is_free,
      :added_by,
      :image,
      :description,
      :type,
      :name,
      :data_collected
    ])
    |> validate_required([:room_number, :is_free, :added_by, :type, :name])
  end
end
