defmodule Medcamp.PatientVisits.PatientVisit do
  use Ecto.Schema
  use Medcamp.Tenancy.Schema
  use Medcamp.Camps.Schema
  import Ecto.Changeset

  @moduledoc """
  One patient's pass through the camp.

  A visit is created automatically when a nurse registers a patient (see
  `Medcamp.Patients.register_for_camp/2`) - nobody opens one by hand - and
  its `status` is what the role queues are built from as the patient moves
  along:

      triage_pending -> triaged -> with_doctor -> lab_pending
                                              \\-> pharmacy_pending -> completed

  There is no payment gate anywhere in that sequence; camp care is free.
  """

  @statuses ~w(triage_pending triaged with_doctor lab_pending pharmacy_pending completed)

  def statuses, do: @statuses

  @doc """
  Human-readable label for a visit status, for tables and filter chips.
  """
  def status_label("triage_pending"), do: "Awaiting triage"
  def status_label("triaged"), do: "Triaged"
  def status_label("with_doctor"), do: "With doctor"
  def status_label("lab_pending"), do: "Awaiting lab"
  def status_label("pharmacy_pending"), do: "Awaiting pharmacy"
  def status_label("completed"), do: "Completed"
  def status_label(other), do: other

  schema "patient_visits" do
    tenant_field()
    camp_field()

    field :reason, :string
    field :date, :date, default: Date.utc_today()
    field :time, :time
    field :visit_type, :string
    field :status, :string, default: "triage_pending"
    belongs_to :patient, Medcamp.Patients.Patient
    belongs_to :creator, Medcamp.Accounts.User
    belongs_to :doctor, Medcamp.Accounts.User
    has_one :doctor_note, Medcamp.DoctorNotes.DoctorNote
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(patient_visit, attrs) do
    patient_visit
    |> cast(attrs, [
      :date,
      :reason,
      :patient_id,
      :visit_type,
      :status,
      :time,
      :creator_id,
      :doctor_id
    ])
    |> validate_required([:date, :patient_id, :creator_id])
    |> validate_inclusion(:status, @statuses)
    |> put_time_if_missing()
    |> put_date_if_missing()
    |> put_org_id()
    |> put_camp_id()
  end

  defp put_date_if_missing(changeset) do
    if get_field(changeset, :date) do
      changeset
    else
      local_date =
        DateTime.utc_now()
        |> DateTime.add(3 * 60 * 60)
        |> DateTime.to_date()

      put_change(changeset, :date, local_date)
    end
  end

  defp put_time_if_missing(changeset) do
    if get_field(changeset, :time) do
      changeset
    else
      current_time =
        Time.utc_now()
        |> Time.add(3 * 60 * 60)
        |> Time.truncate(:second)

      put_change(changeset, :time, current_time)
    end
  end
end
