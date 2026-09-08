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

  def change_camp(%Camp{} = camp, attrs \\ %{}), do: Camp.changeset(camp, attrs)

  @doc """
  Creates a camp. The first camp an organisation ever creates becomes its
  active one, so a new organisation is not left recording work into no camp
  at all.
  """
  def create_camp(attrs \\ %{}) do
    changeset = Camp.changeset(%Camp{}, attrs)

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
