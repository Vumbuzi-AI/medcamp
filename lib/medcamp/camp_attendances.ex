defmodule Medcamp.CampAttendances do
  @moduledoc """
  Records and counts patient attendance across an organisation's camps.

  `camp_attendances` is org-scoped, so every function here is already limited
  to the current organisation by `Medcamp.Repo.prepare_query/3`.
  """

  import Ecto.Query, warn: false

  alias Medcamp.Camps.CampAttendance
  alias Medcamp.Repo

  @doc """
  Marks that `patient_id` attended `camp_id`. Idempotent - a repeat call for
  the same pair is a no-op, so it is safe to call on every visit.
  """
  def record(patient_id, camp_id) when is_integer(patient_id) and is_integer(camp_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %CampAttendance{}
    |> CampAttendance.changeset(%{
      patient_id: patient_id,
      camp_id: camp_id,
      first_seen_at: now
    })
    |> Repo.insert(on_conflict: :nothing, conflict_target: [:patient_id, :camp_id])
  end

  def record(_patient_id, _camp_id), do: {:ok, :skipped}

  @doc "How many distinct camps `patient_id` has attended for this organisation."
  def camp_count(patient_id) do
    Repo.aggregate(
      from(a in CampAttendance, where: a.patient_id == ^patient_id),
      :count,
      :id
    )
  end

  @doc "Has `patient_id` already attended `camp_id`?"
  def attended?(patient_id, camp_id) do
    Repo.exists?(
      from a in CampAttendance,
        where: a.patient_id == ^patient_id and a.camp_id == ^camp_id
    )
  end

  @doc "Patient ids with an attendance row for `camp_id`."
  def patient_ids_for_camp(camp_id) do
    Repo.all(
      from a in CampAttendance,
        where: a.camp_id == ^camp_id,
        select: a.patient_id
    )
  end

  @doc "Count of distinct patients who attended `camp_id`."
  def patient_count_for_camp(camp_id) do
    Repo.aggregate(
      from(a in CampAttendance, where: a.camp_id == ^camp_id),
      :count,
      :patient_id
    )
  end
end
