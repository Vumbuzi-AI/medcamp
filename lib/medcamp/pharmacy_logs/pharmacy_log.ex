defmodule Medcamp.PharmacyLogs.PharmacyLog do
  use Ecto.Schema
  import Ecto.Changeset

  @log_types [
    "room_temperature_humidity",
    "fridge_temperature",
    "cold_room_temperature"
  ]

  schema "pharmacy_logs" do
    field :log_type, :string
    field :month, :integer
    field :year, :integer
    field :daily_entries, :map, default: %{}
    belongs_to :created_by, Medcamp.Accounts.User, foreign_key: :created_by_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(log, attrs) do
    log
    |> cast(attrs, [:log_type, :month, :year, :daily_entries, :created_by_id])
    |> validate_required([:log_type, :month, :year])
    |> validate_inclusion(:log_type, @log_types)
    |> validate_inclusion(:month, 1..12)
    |> validate_number(:year, greater_than: 2020, less_than: 2100)
    |> unique_constraint([:log_type, :month, :year], name: :unique_pharmacy_log_per_month)
  end

  def log_types, do: @log_types

  def log_type_label("room_temperature_humidity"), do: "Room Temperature & Humidity Monitor"
  def log_type_label("fridge_temperature"), do: "Fridge Temperature Monitor"
  def log_type_label("cold_room_temperature"), do: "Cold Room Temperature Monitor"
  def log_type_label(_), do: "Unknown Log"

  def has_humidity?("room_temperature_humidity"), do: true
  def has_humidity?(_), do: false

  def normal_range("room_temperature_humidity"), do: "Temperature: 15–25 °C | Humidity: 35–65 %RH"
  def normal_range("fridge_temperature"), do: "Temperature: 2–8 °C"
  def normal_range("cold_room_temperature"), do: "Temperature: 2–8 °C"
  def normal_range(_), do: ""
end
