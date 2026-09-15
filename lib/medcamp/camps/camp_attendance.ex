defmodule Medcamp.Camps.CampAttendance do
  @moduledoc """
  A patient's presence at one camp. One row per (patient, camp).

  Deliberately org-scoped but **not** `use Medcamp.Camps.Schema` - questions
  like "how many camps has this patient attended" have to span camps, so this
  table must not be silently narrowed to the viewer's camp filter.
  """

  use Ecto.Schema
  use Medcamp.Tenancy.Schema

  import Ecto.Changeset

  schema "camp_attendances" do
    tenant_field()

    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :camp, Medcamp.Camps.Camp

    field :first_seen_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(attendance, attrs) do
    attendance
    |> cast(attrs, [:patient_id, :camp_id, :first_seen_at])
    |> validate_required([:patient_id, :camp_id, :first_seen_at])
    |> put_org_id()
    |> unique_constraint([:patient_id, :camp_id])
  end
end
