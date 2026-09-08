defmodule Medcamp.Triages do
  @moduledoc """
  The Triages context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Triages.Triage

  @doc """
  Returns the list of triages.

  ## Examples

      iex> list_triages()
      [%Triage{}, ...]

  """
  def list_triages do
    Triage
    |> order_by([t], desc: t.inserted_at)
    |> preload([:patient, :creator])
    |> Repo.all()
  end

  def filter_triages(filters \\ %{}) do
    base_query =
      from t in Triage,
        join: pat in assoc(t, :patient),
        left_join: pv in Medcamp.PatientVisits.PatientVisit,
        on: pv.patient_id == pat.id and pv.date == t.date,
        left_join: dn in Medcamp.DoctorNotes.DoctorNote,
        on: dn.patient_id == pat.id and dn.date == t.date,
        order_by: [desc: t.inserted_at],
        preload: [:patient, :creator]

    query =
      base_query
      |> apply_search_filter(filters[:search])
      |> apply_date_filter(filters[:date_from], filters[:date_to])
      |> apply_time_filter(filters[:time_from], filters[:time_to])
      |> apply_gender_filter(filters[:gender])
      |> apply_age_filter(filters[:age_group])
      |> apply_diagnosis_filter(filters[:diagnosis])
      |> apply_visit_type_filter(filters[:visit_type])

    Repo.all(query)
  end

  defp apply_search_filter(query, nil), do: query
  defp apply_search_filter(query, ""), do: query

  defp apply_search_filter(query, term) do
    search = "%#{term}%"

    from [_t, pat, _pv, _dn] in query,
      where:
        ilike(pat.first_name, ^search) or
          ilike(pat.middle_name, ^search) or
          ilike(pat.last_name, ^search) or
          ilike(pat.email, ^search) or
          ilike(pat.gsrn, ^search)
  end

  defp apply_date_filter(query, nil, nil), do: query

  defp apply_date_filter(query, date_from, nil) do
    from [t, _pat, _pv, _dn] in query, where: t.date >= ^date_from
  end

  defp apply_date_filter(query, nil, date_to) do
    from [t, _pat, _pv, _dn] in query, where: t.date <= ^date_to
  end

  defp apply_date_filter(query, date_from, date_to) do
    from [t, _pat, _pv, _dn] in query,
      where: t.date >= ^date_from and t.date <= ^date_to
  end

  defp apply_time_filter(query, nil, nil), do: query

  defp apply_time_filter(query, time_from, nil) do
    from [t, _pat, _pv, _dn] in query, where: t.time >= ^time_from
  end

  defp apply_time_filter(query, nil, time_to) do
    from [t, _pat, _pv, _dn] in query, where: t.time <= ^time_to
  end

  defp apply_time_filter(query, time_from, time_to) do
    from [t, _pat, _pv, _dn] in query,
      where: t.time >= ^time_from and t.time <= ^time_to
  end

  defp apply_gender_filter(query, nil), do: query

  defp apply_gender_filter(query, gender) do
    from [t, pat, _pv, _dn] in query, where: pat.gender == ^gender
  end

  defp apply_age_filter(query, nil), do: query

  defp apply_age_filter(query, age_group) when age_group in ["<5", "5-17", "18-59", "60+"] do
    today = Date.utc_today()
    cutoff = fn years -> %{today | year: today.year - years} end

    case age_group do
      "<5" ->
        from [t, pat, _pv, _dn] in query, where: pat.date_of_birth >= ^cutoff.(5)

      "5-17" ->
        from [t, pat, _pv, _dn] in query,
          where: pat.date_of_birth < ^cutoff.(5) and pat.date_of_birth >= ^cutoff.(18)

      "18-59" ->
        from [t, pat, _pv, _dn] in query,
          where: pat.date_of_birth < ^cutoff.(18) and pat.date_of_birth >= ^cutoff.(60)

      "60+" ->
        from [t, pat, _pv, _dn] in query, where: pat.date_of_birth < ^cutoff.(60)
    end
  end

  defp apply_age_filter(query, _), do: query

  defp apply_diagnosis_filter(query, nil), do: query

  defp apply_diagnosis_filter(query, diagnosis) do
    search_term = "%#{diagnosis}%"

    from [t, _pat, _pv, dn] in query,
      where: not is_nil(dn.id) and ilike(dn.diagnosis, ^search_term)
  end

  defp apply_visit_type_filter(query, nil), do: query

  defp apply_visit_type_filter(query, visit_type) do
    from [t, _pat, pv, _dn] in query, where: pv.visit_type == ^visit_type
  end

  def list_triages_by_patient(patient_id) do
    Repo.all(
      from t in Triage,
        where: t.patient_id == ^patient_id,
        order_by: [desc: t.inserted_at]
    )
  end

  def list_most_recent_triages_for_patients([]), do: []

  def list_most_recent_triages_for_patients(patient_ids) do
    Repo.all(
      from t in Triage,
        where: t.patient_id in ^patient_ids,
        distinct: t.patient_id,
        order_by: [asc: t.patient_id, desc: t.inserted_at]
    )
  end

  def most_recent_triage(patient_id) do
    Repo.one(
      from t in Triage,
        where: t.patient_id == ^patient_id,
        order_by: [desc: t.inserted_at],
        limit: 1
    )
  end

  @doc """
  Gets a single triage.

  Raises `Ecto.NoResultsError` if the Triage does not exist.

  ## Examples

      iex> get_triage!(123)
      %Triage{}

      iex> get_triage!(456)
      ** (Ecto.NoResultsError)

  """
  def get_triage!(id), do: Repo.get!(Triage, id)

  @doc """
  Creates a triage.

  ## Examples

      iex> create_triage(%{field: value})
      {:ok, %Triage{}}

      iex> create_triage(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_triage(attrs \\ %{}) do
    %Triage{}
    |> Triage.changeset(attrs)
    |> Repo.insert()
    |> Medcamp.CampFlow.advance("triaged")
  end

  @doc """
  Updates a triage.

  ## Examples

      iex> update_triage(triage, %{field: new_value})
      {:ok, %Triage{}}

      iex> update_triage(triage, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_triage(%Triage{} = triage, attrs) do
    triage
    |> Triage.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a triage.

  ## Examples

      iex> delete_triage(triage)
      {:ok, %Triage{}}

      iex> delete_triage(triage)
      {:error, %Ecto.Changeset{}}

  """
  def delete_triage(%Triage{} = triage) do
    Repo.delete(triage)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking triage changes.

  ## Examples

      iex> change_triage(triage)
      %Ecto.Changeset{data: %Triage{}}

  """
  def change_triage(%Triage{} = triage, attrs \\ %{}) do
    Triage.changeset(triage, attrs)
  end

  @doc """
  Sets patient_type to "Community" for all medical camp patients that have no type set.

  Usage:
      Medcamp.Triages.fix_medical_camp_patient_types()
  """
  def fix_medical_camp_patient_types do
    {count, _} =
      from(p in Medcamp.Patients.Patient,
        where: fragment("coalesce(?, false) = true", p.is_for_medical_camp),
        where: is_nil(p.patient_type) or p.patient_type == "" or p.patient_type == "Community"
      )
      |> Repo.update_all(set: [patient_type: "Community Member"])

    {:ok, count}
  end

  def fix_triages_for_march_28 do
    camp_date = ~D[2026-03-28]
    # Set inserted_at to 08:00 EAT (05:00 UTC) on the 28th as a neutral anchor time
    anchor_inserted_at = ~U[2026-03-28 05:00:00Z]

    patient_ids =
      from(p in Medcamp.Patients.Patient,
        where: fragment("coalesce(?, false) = true", p.is_for_medical_camp),
        where: fragment("DATE(? AT TIME ZONE 'Africa/Nairobi')", p.inserted_at) == ^camp_date,
        select: p.id
      )
      |> Repo.all()

    {count, _} =
      from(t in Triage, where: t.patient_id in ^patient_ids)
      |> Repo.update_all(set: [date: camp_date, inserted_at: anchor_inserted_at])

    {:ok, count}
  end
end
