defmodule Medcamp.PatientVisits do
  @moduledoc """
  The PatientVisits context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.PatientVisits.PatientVisit
  alias Medcamp.Patients.Patient

  @doc """
  Returns the list of patient_visits.

  ## Examples

      iex> list_patient_visits()
      [%PatientVisit{}, ...]

  """
  def list_patient_visits do
    PatientVisit
    |> order_by([p], desc: p.inserted_at)
    |> preload([:patient, :creator, :doctor])
    |> Repo.all()
  end

  def filter_patient_visits(filters \\ %{}) do
    patient_visits_query(filters)
    |> Repo.all()
    |> Enum.map(fn pv ->
      %{pv | patient: Patient.with_age(pv.patient)}
    end)
  end

  def filter_patient_visits_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    patient_visits_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Enum.map(fn pv ->
      %{pv | patient: Patient.with_age(pv.patient)}
    end)
  end

  def count_patient_visits(filters \\ %{}) do
    filter_patient_visits(filters) |> length()
  end

  defp patient_visits_query(filters) do
    base_query =
      from pv in PatientVisit,
        join: pat in assoc(pv, :patient),
        left_join: dn in Medcamp.DoctorNotes.DoctorNote,
        on: dn.patient_id == pat.id and fragment("DATE(?) = DATE(?)", dn.date, pv.date),
        order_by: [desc: pv.inserted_at],
        preload: [:patient, :creator, :doctor]

    base_query
    |> apply_date_filter(filters[:date_from], filters[:date_to])
    |> apply_time_filter(filters[:time_from], filters[:time_to])
    |> apply_gender_filter(filters[:gender])
    |> apply_age_filter(filters[:age_group])
    |> apply_diagnosis_filter(filters[:diagnosis])
    |> apply_visit_type_filter(filters[:visit_type])
    |> apply_patient_search_filter(filters[:search])
    |> apply_doctor_filter(filters[:doctor_id])
    |> apply_creator_filter(filters[:creator_id])
    |> apply_status_filter(filters[:status])
  end

  defp apply_status_filter(query, nil), do: query
  defp apply_status_filter(query, ""), do: query

  defp apply_status_filter(query, status) do
    from [pv, _pat, _dn] in query, where: pv.status == ^status
  end

  defp apply_date_filter(query, nil, nil), do: query

  defp apply_date_filter(query, date_from, nil) do
    from [pv, _pat, _dn] in query,
      where: pv.date >= ^date_from
  end

  defp apply_date_filter(query, nil, date_to) do
    from [pv, _pat, _dn] in query,
      where: pv.date <= ^date_to
  end

  defp apply_date_filter(query, date_from, date_to) do
    from [pv, _pat, _dn] in query,
      where: pv.date >= ^date_from and pv.date <= ^date_to
  end

  defp apply_time_filter(query, nil, nil), do: query

  defp apply_time_filter(query, time_from, nil) do
    from [pv, _pat, _dn] in query,
      where: pv.time >= ^time_from
  end

  defp apply_time_filter(query, nil, time_to) do
    from [pv, _pat, _dn] in query,
      where: pv.time <= ^time_to
  end

  defp apply_time_filter(query, time_from, time_to) do
    from [pv, _pat, _dn] in query,
      where: pv.time >= ^time_from and pv.time <= ^time_to
  end

  defp apply_gender_filter(query, nil), do: query

  defp apply_gender_filter(query, gender) do
    from [pv, pat, _dn] in query,
      where: pat.gender == ^gender
  end

  defp apply_age_filter(query, nil), do: query

  defp apply_age_filter(query, age_group) when age_group in ["<5", "5-17", "18-59", "60+"] do
    today = Date.utc_today()
    cutoff = fn years -> %{today | year: today.year - years} end

    case age_group do
      "<5" ->
        from [pv, pat, _dn] in query, where: pat.date_of_birth >= ^cutoff.(5)

      "5-17" ->
        from [pv, pat, _dn] in query,
          where: pat.date_of_birth < ^cutoff.(5) and pat.date_of_birth >= ^cutoff.(18)

      "18-59" ->
        from [pv, pat, _dn] in query,
          where: pat.date_of_birth < ^cutoff.(18) and pat.date_of_birth >= ^cutoff.(60)

      "60+" ->
        from [pv, pat, _dn] in query, where: pat.date_of_birth < ^cutoff.(60)
    end
  end

  defp apply_age_filter(query, _), do: query

  defp apply_diagnosis_filter(query, nil), do: query

  defp apply_diagnosis_filter(query, diagnosis) do
    search_term = "%#{diagnosis}%"

    from [pv, _pat, dn] in query,
      where: not is_nil(dn.id) and ilike(dn.diagnosis, ^search_term)
  end

  defp apply_visit_type_filter(query, nil), do: query

  defp apply_visit_type_filter(query, visit_type) do
    from [pv, _pat, _dn] in query,
      where: pv.visit_type == ^visit_type
  end

  defp apply_patient_search_filter(query, nil), do: query
  defp apply_patient_search_filter(query, ""), do: query

  defp apply_patient_search_filter(query, term) do
    search = "%#{term}%"

    from [pv, pat, _dn] in query,
      where:
        ilike(pat.first_name, ^search) or
          ilike(pat.middle_name, ^search) or
          ilike(pat.last_name, ^search) or
          ilike(pat.gsrn, ^search)
  end

  defp apply_doctor_filter(query, nil), do: query
  defp apply_doctor_filter(query, ""), do: query

  defp apply_doctor_filter(query, doctor_id) when is_binary(doctor_id) do
    case Integer.parse(doctor_id) do
      {id, ""} -> from [pv, _pat, _dn] in query, where: pv.doctor_id == ^id
      _ -> query
    end
  end

  defp apply_doctor_filter(query, doctor_id) when is_integer(doctor_id) do
    from [pv, _pat, _dn] in query, where: pv.doctor_id == ^doctor_id
  end

  defp apply_creator_filter(query, nil), do: query
  defp apply_creator_filter(query, ""), do: query

  defp apply_creator_filter(query, creator_id) when is_binary(creator_id) do
    case Integer.parse(creator_id) do
      {id, ""} -> from [pv, _pat, _dn] in query, where: pv.creator_id == ^id
      _ -> query
    end
  end

  defp apply_creator_filter(query, creator_id) when is_integer(creator_id) do
    from [pv, _pat, _dn] in query, where: pv.creator_id == ^creator_id
  end

  @doc """
  Moves `visit` to `status`, rejecting anything outside the camp flow.

  Kept in one place so the role queues and the pages that advance a patient
  cannot drift apart: each queue filters on a status, and the only way a
  visit reaches that status is one of these calls.
  """
  def update_status(%PatientVisit{} = visit, status) do
    visit
    |> PatientVisit.changeset(%{"status" => status})
    |> Repo.audited_update()
  end

  @doc """
  Marks the visit triaged, after a nurse records observations.
  """
  def mark_triaged(%PatientVisit{} = visit), do: update_status(visit, "triaged")

  @doc """
  Marks the visit as picked up by a doctor.
  """
  def mark_with_doctor(%PatientVisit{} = visit), do: update_status(visit, "with_doctor")

  @doc """
  Sends the visit to the lab queue, after a doctor requests tests.
  """
  def mark_lab_pending(%PatientVisit{} = visit), do: update_status(visit, "lab_pending")

  @doc """
  Sends the visit to the pharmacy queue, after a doctor prescribes drugs.
  """
  def mark_pharmacy_pending(%PatientVisit{} = visit),
    do: update_status(visit, "pharmacy_pending")

  @doc """
  Closes the visit - the patient is done with the camp.
  """
  def mark_completed(%PatientVisit{} = visit), do: update_status(visit, "completed")

  @doc """
  Today's visits sitting at `status`, oldest first - the shape every role
  queue (triage list, doctor's pending cases, pharmacy queue) is built from.
  """
  def list_queue(status, date \\ nil) do
    date = date || Date.utc_today()

    from(pv in PatientVisit,
      where: pv.status == ^status and pv.date == ^date,
      order_by: [asc: pv.inserted_at],
      preload: [:patient, :creator, :doctor]
    )
    |> Repo.all()
  end

  @doc """
  The patient's currently open visit for today, if any - what a scan-in page
  resolves a scanned patient to.
  """
  def current_visit_for_patient(patient_id, date \\ nil) do
    date = date || Date.utc_today()

    from(pv in PatientVisit,
      where:
        pv.patient_id == ^patient_id and pv.date == ^date and
          pv.status != "completed",
      order_by: [desc: pv.inserted_at],
      limit: 1,
      preload: [:patient, :creator, :doctor]
    )
    |> Repo.one()
  end

  @doc """
  Lists patient visits for a patient on a given date that do not yet have a doctor note.
  Used when adding a doctor note to enforce one-to-one visit-to-note relationship.
  """
  def list_visits_without_doctor_note(patient_id, date) do
    from(pv in PatientVisit,
      left_join: dn in Medcamp.DoctorNotes.DoctorNote,
      on: dn.patient_visit_id == pv.id,
      where: pv.patient_id == ^patient_id and pv.date == ^date and is_nil(dn.id),
      order_by: [asc: pv.time, asc: pv.inserted_at],
      preload: [:patient, :creator, :doctor]
    )
    |> Repo.all()
  end

  @doc """
  Returns the patient's most recent visit that can still receive a doctor note.
  """
  def latest_visit_without_doctor_note(patient_id) do
    from(pv in PatientVisit,
      left_join: dn in Medcamp.DoctorNotes.DoctorNote,
      on: dn.patient_visit_id == pv.id,
      where: pv.patient_id == ^patient_id and is_nil(dn.id),
      order_by: [desc: pv.date, desc: pv.time, desc: pv.inserted_at],
      limit: 1,
      preload: [:patient, :creator, :doctor]
    )
    |> Repo.one()
  end

  @doc """
  Count visits for a doctor today that do not yet have a doctor note (pending notes).
  """
  def count_visits_without_notes_today(doctor_id) do
    today = Date.utc_today()

    from(pv in PatientVisit,
      left_join: dn in Medcamp.DoctorNotes.DoctorNote,
      on: dn.patient_visit_id == pv.id,
      where: pv.doctor_id == ^doctor_id and pv.date == ^today and is_nil(dn.id),
      select: count(pv.id)
    )
    |> Repo.one()
  end

  def list_patient_visits_by_patient_id(patient_id) do
    PatientVisit
    |> where([p], p.patient_id == ^patient_id)
    |> order_by([p], asc: p.inserted_at)
    |> preload([:patient, :creator, :doctor])
    |> Repo.all()
  end

  def list_patient_visits_by_patient_id_paginated(patient_id, page \\ 1, per_page \\ 20) do
    PatientVisit
    |> where([p], p.patient_id == ^patient_id)
    |> order_by([p], asc: p.inserted_at)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:patient, :creator, :doctor])
  end

  def count_patient_visits_by_patient_id(patient_id) do
    from(p in PatientVisit, where: p.patient_id == ^patient_id, select: count(p.id))
    |> Repo.one()
  end

  def list_patient_visits_by_doctor_id(doctor_id) do
    PatientVisit
    |> where([p], p.doctor_id == ^doctor_id)
    |> order_by([p], asc: p.inserted_at)
    |> preload([:patient, :creator, :doctor])
    |> Repo.all()
  end

  def list_pending_visits(filters \\ %{}) do
    PatientVisit
    |> where([p], is_nil(p.doctor_id))
    |> order_by([p], asc: p.inserted_at)
    |> apply_doctor_visit_search(filters[:search])
    |> preload([:patient, :creator, :doctor])
    |> Repo.all()
  end

  @doc """
  Gets a single patient_visit.

  Raises `Ecto.NoResultsError` if the Patient visit does not exist.

  ## Examples

      iex> get_patient_visit!(123)
      %PatientVisit{}

      iex> get_patient_visit!(456)
      ** (Ecto.NoResultsError)

  """
  def get_patient_visit!(id),
    do: Repo.get!(PatientVisit, id) |> Repo.preload([:patient])

  @doc """
  Creates a patient_visit.

  ## Examples

      iex> create_patient_visit(%{field: value})
      {:ok, %PatientVisit{}}

      iex> create_patient_visit(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_patient_visit(attrs \\ %{}) do
    attrs = ensure_date_today(attrs)

    %PatientVisit{}
    |> PatientVisit.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a patient_visit.

  ## Examples

      iex> update_patient_visit(patient_visit, %{field: new_value})
      {:ok, %PatientVisit{}}

      iex> update_patient_visit(patient_visit, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_patient_visit(%PatientVisit{} = patient_visit, attrs) do
    patient_visit
    |> PatientVisit.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a patient_visit.

  ## Examples

      iex> delete_patient_visit(patient_visit)
      {:ok, %PatientVisit{}}

      iex> delete_patient_visit(patient_visit)
      {:error, %Ecto.Changeset{}}

  """
  def delete_patient_visit(%PatientVisit{} = patient_visit) do
    Repo.delete(patient_visit)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking patient_visit changes.

  ## Examples

      iex> change_patient_visit(patient_visit)
      %Ecto.Changeset{data: %PatientVisit{}}

  """
  def change_patient_visit(%PatientVisit{} = patient_visit, attrs \\ %{}) do
    attrs = ensure_date_today_for_new(patient_visit, attrs)
    PatientVisit.changeset(patient_visit, attrs)
  end

  defp local_date_today do
    DateTime.utc_now()
    |> DateTime.add(3 * 60 * 60)
    |> DateTime.to_date()
  end

  defp ensure_date_today(attrs) when is_map(attrs) do
    today = local_date_today()
    date_str = Date.to_iso8601(today)

    case attrs do
      %{"date" => d} when is_binary(d) and d != "" -> attrs
      %{date: _} -> attrs
      _ -> Map.put(attrs, "date", date_str)
    end
  end

  defp ensure_date_today_for_new(%PatientVisit{id: nil}, attrs) when is_map(attrs) do
    today = local_date_today()
    date_str = Date.to_iso8601(today)

    case attrs do
      %{"date" => d} when is_binary(d) and d != "" -> attrs
      %{date: _} -> attrs
      _ -> Map.put(attrs, "date", date_str)
    end
  end

  defp ensure_date_today_for_new(_patient_visit, attrs), do: attrs

  def list_patient_visits_by_doctor_id_paginated(
        doctor_id,
        filters \\ %{},
        page \\ 1,
        per_page \\ 20
      ) do
    doctor_id
    |> patient_visits_by_doctor_id_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:patient, :creator, :doctor])
  end

  def count_patient_visits_by_doctor_id(doctor_id, filters \\ %{}) do
    doctor_id
    |> patient_visits_by_doctor_id_query(filters)
    |> Repo.aggregate(:count, :id)
  end

  defp patient_visits_by_doctor_id_query(doctor_id, filters) do
    PatientVisit
    |> where([p], p.doctor_id == ^doctor_id)
    |> order_by([p], asc: p.inserted_at)
    |> apply_doctor_visit_search(filters[:search])
  end

  defp apply_doctor_visit_search(query, nil), do: query
  defp apply_doctor_visit_search(query, ""), do: query

  defp apply_doctor_visit_search(query, term) do
    term = String.trim(term)

    if term == "" do
      query
    else
      pattern = "%#{term}%"

      from(p in query,
        left_join: pat in assoc(p, :patient),
        where:
          ilike(pat.first_name, ^pattern) or ilike(pat.middle_name, ^pattern) or
            ilike(pat.last_name, ^pattern) or ilike(p.reason, ^pattern)
      )
    end
  end

  def count_repeat_patients(timeline \\ nil) do
    {date_from, date_to} = timeline || {nil, nil}

    repeat_patient_ids =
      from(v in PatientVisit,
        group_by: v.patient_id,
        having: count(v.id) > 1,
        select: v.patient_id
      )
      |> apply_repeat_patients_date_filter(date_from, date_to)

    from(q in subquery(repeat_patient_ids), select: count(q.patient_id))
    |> Repo.one()
  end

  defp apply_repeat_patients_date_filter(query, nil, nil), do: query

  defp apply_repeat_patients_date_filter(query, date_from, nil) do
    from(v in query, where: v.date >= ^date_from)
  end

  defp apply_repeat_patients_date_filter(query, nil, date_to) do
    from(v in query, where: v.date <= ^date_to)
  end

  defp apply_repeat_patients_date_filter(query, date_from, date_to) do
    from(v in query, where: v.date >= ^date_from and v.date <= ^date_to)
  end

  @doc """
  Buckets the given patient ids by visit count: `new` (exactly one visit),
  `recurring` (more than one visit), and `total` (their sum). Patients with
  no visits at all are excluded from all three counts.
  """
  def patient_visit_figures(patient_ids) do
    counts =
      from(v in PatientVisit,
        where: v.patient_id in ^patient_ids,
        group_by: v.patient_id,
        select: count(v.id)
      )
      |> Repo.all()

    new = Enum.count(counts, &(&1 == 1))
    recurring = Enum.count(counts, &(&1 > 1))

    %{new: new, recurring: recurring, total: new + recurring}
  end
end
