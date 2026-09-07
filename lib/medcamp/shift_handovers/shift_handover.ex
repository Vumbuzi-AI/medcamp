defmodule Medcamp.ShiftHandovers.ShiftHandover do
  use Ecto.Schema
  import Ecto.Changeset

  schema "shift_handovers" do
    field :status, :string, default: "pending"
    field :shift_date, :date
    field :shift_start, :date
    field :shift_type, :string
    field :department, :string
    field :handover_from, :string
    field :daily_coldchain_temperature_log, :string
    field :dangerous_drug_register, :string
    field :equipment_maintenance_log, :string
    field :handover_to, :string
    field :patient_count, :integer, default: 0
    field :admissions, :integer, default: 0
    field :discharges, :integer, default: 0
    field :patient_updates, :string
    field :pending_tasks, :string
    field :petty_cash_balance, :integer
    field :equipment_issues, :string
    field :incidents, :string
    field :notes, :string
    field :submitted_at, :utc_datetime
    field :acknowledged_at, :utc_datetime
    belongs_to :submitted_by, Medcamp.Accounts.User
    belongs_to :acknowledged_by, Medcamp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(shift_handover, attrs) do
    shift_handover
    |> cast(attrs, [
      :shift_date,
      :shift_type,
      :department,
      :daily_coldchain_temperature_log,
      :dangerous_drug_register,
      :equipment_maintenance_log,
      :handover_from,
      :handover_to,
      :patient_count,
      :admissions,
      :discharges,
      :patient_updates,
      :petty_cash_balance,
      :pending_tasks,
      :equipment_issues,
      :incidents,
      :shift_start,
      :notes,
      :status,
      :submitted_at,
      :acknowledged_at,
      :submitted_by_id,
      :acknowledged_by_id
    ])
    |> validate_required([
      :shift_date,
      :shift_start,
      :department,
      :handover_from,
      :handover_to,
      :patient_count
    ])
    |> validate_inclusion(:shift_type, ["morning", "afternoon", "night", "day"])
    |> validate_inclusion(:status, ["pending", "acknowledged", "completed"])
    |> validate_number(:patient_count, greater_than_or_equal_to: 0)
    |> validate_number(:admissions, greater_than_or_equal_to: 0)
    |> validate_number(:discharges, greater_than_or_equal_to: 0)
  end
end
