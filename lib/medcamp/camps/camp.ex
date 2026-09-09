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

  @doc false
  def changeset(camp, attrs) do
    camp
    |> cast(attrs, [:name, :location, :description, :start_date, :end_date])
    |> validate_required([:name])
    |> validate_length(:name, max: 255)
    |> validate_dates()
    |> put_org_id()
    |> unique_constraint([:organisation_id, :name],
      message: "a camp with this name already exists"
    )
  end

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
end
