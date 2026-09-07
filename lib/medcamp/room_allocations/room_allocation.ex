defmodule Medcamp.RoomAllocations.RoomAllocation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "room_allocations" do
    field :start_date, :date
    field :end_date, :date
    field :payment_type, :string
    field :total_amount_paid, :integer
    field :has_paid, :boolean, default: false
    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :nurse, Medcamp.Accounts.User
    belongs_to :room, Medcamp.Rooms.Room

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room_allocation, attrs) do
    room_allocation
    |> cast(attrs, [
      :start_date,
      :end_date,
      :patient_id,
      :nurse_id,
      :room_id,
      :payment_type,
      :total_amount_paid,
      :has_paid
    ])
    |> validate_required([:start_date, :patient_id, :nurse_id, :room_id])
  end
end
