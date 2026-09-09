defmodule Medcamp.Camps.Camp do
  @moduledoc """
  One camp an organisation runs: a place, a set of dates, and the activity
  recorded while it was open.

  Exactly one camp per organisation may be active at a time. The active camp
  is what gets stamped onto new visits, notes, results and dispenses, so
  making a different one active is how an organisation says "we have moved on
  to the next event" - nothing about the previous camp's records changes.
  """

  use Ecto.Schema
  use Medcamp.Tenancy.Schema

  import Ecto.Changeset

  schema "camps" do
    tenant_field()

    field :name, :string
    field :location, :string
    field :description, :string
    field :start_date, :date
    field :end_date, :date
    field :is_active, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc """
  `opts[:reject_past_start]` rejects a `start_date` before today. The database
  and the seeds still accept past camps (backfilling a completed event); only
  the "create a camp" form passes this so it can't be used to schedule one in
  the past by mistake.
  """
  def changeset(camp, attrs, opts \\ []) do
    camp
    |> cast(attrs, [:name, :location, :description, :start_date, :end_date])
    |> validate_required([:name])
    |> validate_length(:name, max: 255)
    |> validate_dates()
    |> maybe_reject_past_start(opts[:reject_past_start])
    |> put_org_id()
    |> unique_constraint([:organisation_id, :name],
      message: "a camp with this name already exists"
    )
  end

  defp maybe_reject_past_start(changeset, true) do
    case get_change(changeset, :start_date) do
      %Date{} = start_date ->
        if Date.compare(start_date, Date.utc_today()) == :lt,
          do: add_error(changeset, :start_date, "cannot be in the past"),
          else: changeset

      _ ->
        changeset
    end
  end

  defp maybe_reject_past_start(changeset, _), do: changeset

  defp validate_dates(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)

    if start_date && end_date && Date.compare(end_date, start_date) == :lt do
      add_error(changeset, :end_date, "must be on or after the start date")
    else
      changeset
    end
  end

  @doc """
  A camp's dates as a single line, for the switcher and the camp list.
  """
  def date_range(%__MODULE__{start_date: nil, end_date: nil}), do: nil
  def date_range(%__MODULE__{start_date: from, end_date: nil}), do: "from #{from}"
  def date_range(%__MODULE__{start_date: nil, end_date: to}), do: "until #{to}"
  def date_range(%__MODULE__{start_date: same, end_date: same}), do: to_string(same)
  def date_range(%__MODULE__{start_date: from, end_date: to}), do: "#{from} - #{to}"

  @doc """
  Every calendar day the camp runs, as a list of `Date`. Empty when the camp
  has no dates set; a single-element list when only one end is known or both
  ends are the same day. Used to build the dashboard's day switcher.
  """
  def days(%__MODULE__{start_date: %Date{} = from, end_date: %Date{} = to}) do
    case Date.compare(from, to) do
      :gt -> [from]
      _ -> Enum.to_list(Date.range(from, to))
    end
  end

  def days(%__MODULE__{start_date: %Date{} = from}), do: [from]
  def days(%__MODULE__{end_date: %Date{} = to}), do: [to]
  def days(_camp), do: []
end
