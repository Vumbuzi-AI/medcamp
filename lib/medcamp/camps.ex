defmodule Medcamp.Camps do
  @moduledoc """
  The Camps context - the events an organisation runs.

  `camps` is a tenant table, so everything here is already filtered to the
  current organisation by `Medcamp.Repo.prepare_query/3`; no function needs
  to take an organisation argument.
  """

  import Ecto.Query, warn: false

  alias Medcamp.Camps.Camp
  alias Medcamp.Repo

  @doc "Every camp in the current organisation, most recent first."
  def list_camps do
    Repo.all(
      from c in Camp,
        order_by: [desc: c.is_active, desc_nulls_last: c.start_date, desc: c.inserted_at]
    )
  end

  @doc "Camps for a `<select>`: `[{label, id}, ...]`, active one first."
  def camp_options do
    Enum.map(list_camps(), fn camp ->
      label = if camp.is_active, do: "#{camp.name} (active)", else: camp.name
      {label, camp.id}
    end)
  end

  def get_camp!(id), do: Repo.get!(Camp, id)

  def get_camp(nil), do: nil
  def get_camp(id), do: Repo.get(Camp, id)

  @doc "The organisation's active camp, or `nil` if it has none."
  def get_active_camp, do: Repo.one(from c in Camp, where: c.is_active == true, limit: 1)

  @doc """
  The active camp of `organisation_id`, looked up outside the current
  process's tenancy.

  Used at login and on LiveView mount, where the organisation is known but
  the tenant scope for the request is being established in the same breath.
  """
  def get_active_camp_for_organisation(nil), do: nil

  def get_active_camp_for_organisation(organisation_id) do
    Repo.one(
      from(c in Camp,
        where: c.organisation_id == ^organisation_id and c.is_active == true,
        limit: 1
      ),
      skip_org_id: true
    )
  end

  def change_camp(%Camp{} = camp, attrs \\ %{}, opts \\ []),
    do: Camp.changeset(camp, attrs, opts)

  @doc """
  Creates a camp. The first camp an organisation ever creates becomes its
  active one, so a new organisation is not left recording work into no camp
  at all.

  `opts` is forwarded to `Camp.changeset/3` (e.g. `reject_past_start: true`
  from the admin form; the seeds and backfills leave it off).
  """
  def create_camp(attrs \\ %{}, opts \\ []) do
    changeset = Camp.changeset(%Camp{}, attrs, opts)

    Repo.transaction(fn ->
      case Repo.insert(changeset) do
        {:ok, camp} ->
          if Repo.aggregate(Camp, :count) == 1 do
            camp |> Ecto.Changeset.change(is_active: true) |> Repo.update!()
          else
            camp
          end

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  def update_camp(%Camp{} = camp, attrs) do
    camp
    |> Camp.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Makes `camp` the one new records are stamped with, deactivating whichever
  camp held that place.

  Both writes are in one transaction because the database refuses two active
  camps in an organisation; doing them apart would fail halfway.
  """
  def set_active_camp(%Camp{} = camp) do
    Repo.transaction(fn ->
      Repo.update_all(
        from(c in Camp, where: c.is_active == true and c.id != ^camp.id),
        set: [is_active: false, updated_at: DateTime.utc_now() |> DateTime.truncate(:second)]
      )

      camp
      |> Ecto.Changeset.change(is_active: true)
      |> Repo.update!()
    end)
  end

  @doc """
  Leaves the organisation with no active camp - between events, when work
  recorded should not be attributed to the camp that just ended.
  """
  def clear_active_camp do
    Repo.update_all(
      from(c in Camp, where: c.is_active == true),
      set: [is_active: false, updated_at: DateTime.utc_now() |> DateTime.truncate(:second)]
    )

    :ok
  end

  @doc """
  Deletes a camp.

  Refused once anything has been recorded against it: the records would keep
  existing with their camp silently nulled, which reads as "this never
  happened at a camp" rather than "the camp was removed". Rename or simply
  stop using it instead.
  """
  def delete_camp(%Camp{} = camp) do
    if camp_used?(camp) do
      {:error, :camp_has_records}
    else
      Repo.delete(camp)
    end
  end

  # Every schema that carries a camp_id. `skip_camp_id: true` on the queries
  # below because these ask about one specific camp - the viewer's current
  # filter, which may be a different camp entirely, must not narrow them.
  @camp_scoped_schemas [
    Medcamp.PatientVisits.PatientVisit,
    Medcamp.Triages.Triage,
    Medcamp.DoctorNotes.DoctorNote,
    Medcamp.LabResults.LabResult,
    Medcamp.DrugAllocations.DrugAllocation,
    Medcamp.DrugsGiven.DrugGiven,
    Medcamp.DrugBatches.DrugBatch,
    Medcamp.InventoriesReceived.InventoryReceived
  ]

  defp camp_used?(%Camp{id: id}) do
    Enum.any?(@camp_scoped_schemas, fn schema ->
      Repo.exists?(from(r in schema, where: r.camp_id == ^id), skip_camp_id: true)
    end)
  end

  @doc """
  Every camp across every organisation, active first, with the organisation
  preloaded and a total record count as `[{%Camp{}, count}, ...]`.

  Platform console only - bypasses tenant scoping.
  """
  def list_all_camps_with_counts do
    camps =
      Repo.all(
        from(c in Camp,
          order_by: [desc: c.is_active, desc_nulls_last: c.start_date, desc: c.inserted_at]
        ),
        skip_org_id: true
      )
      |> Repo.preload(:organisation, skip_org_id: true)

    counts = record_counts_by_camp()
    Enum.map(camps, fn camp -> {camp, Map.get(counts, camp.id, 0)} end)
  end

  defp record_counts_by_camp do
    @camp_scoped_schemas
    |> Enum.flat_map(fn schema ->
      Repo.all(
        from(r in schema,
          where: not is_nil(r.camp_id),
          group_by: r.camp_id,
          select: {r.camp_id, count(r.id)}
        ),
        skip_org_id: true,
        skip_camp_id: true
      )
    end)
    |> Enum.reduce(%{}, fn {camp_id, n}, acc -> Map.update(acc, camp_id, n, &(&1 + n)) end)
  end

  @doc """
  Platform-console analytics across every camp and organisation:

    * `total_camps` / `active_camps`
    * `total_records` - camp-scoped rows across all camps
    * `avg_records_per_camp`
    * `patients` - distinct patients with any camp attendance
    * `returning_patients` - patients seen at more than one camp (same org)
    * `new_patients` - `patients - returning_patients`
    * `top_camps` - `[{%Camp{}, record_count}, ...]`, busiest first (max 5)
    * `camps_by_month` - `[{"YYYY-MM", count}, ...]` by start date, last 6

  Bypasses tenant scoping - superadmin only.
  """
  def platform_camp_analytics do
    rows = list_all_camps_with_counts()
    total_camps = length(rows)
    active_camps = Enum.count(rows, fn {camp, _} -> camp.is_active end)
    total_records = rows |> Enum.map(&elem(&1, 1)) |> Enum.sum()

    camp_counts_per_patient =
      Repo.all(
        from(a in Medcamp.Camps.CampAttendance,
          group_by: a.patient_id,
          select: count(a.camp_id)
        ),
        skip_org_id: true
      )

    patients = length(camp_counts_per_patient)
    returning = Enum.count(camp_counts_per_patient, &(&1 > 1))

    %{
      total_camps: total_camps,
      active_camps: active_camps,
      total_records: total_records,
      avg_records_per_camp: (total_camps > 0 && div(total_records, total_camps)) || 0,
      patients: patients,
      returning_patients: returning,
      new_patients: patients - returning,
      top_camps: rows |> Enum.sort_by(&elem(&1, 1), :desc) |> Enum.take(5),
      camps_by_month: camps_by_month(rows)
    }
  end

  defp camps_by_month(rows) do
    rows
    |> Enum.map(fn {camp, _} -> camp.start_date || camp.inserted_at end)
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&(&1 |> to_string() |> String.slice(0, 7)))
    |> Enum.frequencies()
    |> Enum.sort()
    |> Enum.take(-6)
  end

  @doc """
  A single camp from any organisation, with its organisation preloaded.
  Platform console only - bypasses tenant scoping. Returns `nil` if unknown.
  """
  def get_camp_across_orgs(id) do
    case Repo.one(from(c in Camp, where: c.id == ^id), skip_org_id: true) do
      nil -> nil
      camp -> Repo.preload(camp, :organisation, skip_org_id: true)
    end
  end

  @camp_schema_labels %{
    Medcamp.PatientVisits.PatientVisit => "Patient visits",
    Medcamp.Triages.Triage => "Triages",
    Medcamp.DoctorNotes.DoctorNote => "Doctor notes",
    Medcamp.LabResults.LabResult => "Lab results",
    Medcamp.DrugAllocations.DrugAllocation => "Drug allocations",
    Medcamp.DrugsGiven.DrugGiven => "Drugs given",
    Medcamp.DrugBatches.DrugBatch => "Drug batches",
    Medcamp.InventoriesReceived.InventoryReceived => "Inventory received"
  }

  @doc """
  Per-category record counts for one camp, `[{"Patient visits", 12}, ...]`.
  Platform console only - bypasses tenant scoping.
  """
  def camp_record_breakdown(camp_id) do
    Enum.map(@camp_scoped_schemas, fn schema ->
      count =
        Repo.aggregate(from(r in schema, where: r.camp_id == ^camp_id), :count, :id,
          skip_org_id: true,
          skip_camp_id: true
        )

      {Map.fetch!(@camp_schema_labels, schema), count}
    end)
  end

  @doc """
  New / returning / total patient counts for one camp, from `camp_attendances`.
  "Returning" means the patient has an attendance row for more than one camp
  in their organisation. Platform console only - bypasses tenant scoping.
  """
  def camp_patient_stats(camp_id) do
    patient_ids =
      Repo.all(
        from(a in Medcamp.Camps.CampAttendance,
          where: a.camp_id == ^camp_id,
          select: a.patient_id
        ),
        skip_org_id: true
      )

    total = length(patient_ids)

    returning =
      if total == 0 do
        0
      else
        Repo.all(
          from(a in Medcamp.Camps.CampAttendance,
            where: a.patient_id in ^patient_ids,
            group_by: a.patient_id,
            select: count(a.camp_id)
          ),
          skip_org_id: true
        )
        |> Enum.count(&(&1 > 1))
      end

    %{total: total, returning: returning, new: total - returning}
  end

  @doc """
  Patients who attended one camp, `[%{patient: %Patient{}, first_seen_at: _}, ...]`
  ordered by name. Platform console only - bypasses tenant scoping.
  """
  def camp_patients(camp_id) do
    Repo.all(
      from(a in Medcamp.Camps.CampAttendance,
        where: a.camp_id == ^camp_id,
        join: p in assoc(a, :patient),
        order_by: [asc: p.last_name, asc: p.first_name],
        select: %{patient: p, first_seen_at: a.first_seen_at}
      ),
      skip_org_id: true
    )
  end

  @doc """
  How many records a camp holds in total, for the camp list.
  """
  def record_count(%Camp{id: id}) do
    @camp_scoped_schemas
    |> Enum.map(fn schema ->
      Repo.aggregate(from(r in schema, where: r.camp_id == ^id), :count, :id, skip_camp_id: true)
    end)
    |> Enum.sum()
  end
end
