defmodule Medcamp.DailyActivities.DailyActivity do
  @moduledoc """
  Schema for tracking daily housekeeping activities.
  Each record represents a single activity completion for a specific date.
  Only ONE record per activity per day - shows WHO did it.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "daily_activities" do
    field :date, :date
    field :activity_name, :string
    field :completed, :boolean, default: true
    field :completed_at, :utc_datetime
    field :notes, :string

    belongs_to :user, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @required_fields [:date, :activity_name, :user_id]
  @optional_fields [:completed, :completed_at, :notes]

  @valid_activities [
    "Tea Prepared",
    "Laundry Done",
    "Surfaces Dusted",
    "Floor Cleaned",
    "Bins Emptied",
    "Toilet/Bath room Cleaned",
    "Tissue Papers/Hand Towels Refilled",
    "Handwash Refilled",
    "Windows Cleaned",
    "Compound Cleaned"
  ]

  @doc false
  def changeset(activity, attrs) do
    activity
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:activity_name, @valid_activities, message: "is not a valid activity")
    |> unique_constraint([:date, :activity_name],
      name: :daily_activities_date_activity_index,
      message: "activity already done for this day"
    )
    |> foreign_key_constraint(:user_id)
  end
end
