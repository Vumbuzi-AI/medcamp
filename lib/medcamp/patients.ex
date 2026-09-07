defmodule Medcamp.Patients do
  alias Medcamp.Gtin

  @moduledoc """
  The Patients context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Patients.{
    Patient,
    PatientDocument
  }

  @doc """
  Returns the list of patients.

  ## Examples

      iex> list_patients()
      [%Patient{}, ...]

  """
  def last_patient_gsrn do
    last_patient_query =
      from p in Patient,
        order_by: [desc: p.inserted_at],
        limit: 1,
        select: {p.inserted_at, p.gsrn}

    last_user_query =
      from u in Medcamp.Accounts.User,
        order_by: [desc: u.inserted_at],
        limit: 1,
        select: {u.inserted_at, u.gsrn}

    last_patient = Repo.one(last_patient_query)
    last_user = Repo.one(last_user_query)

    case {last_patient, last_user} do
      {nil, nil} ->
        nil

      {nil, {_, user_gsrn}} ->
        user_gsrn

      {{_, patient_gsrn}, nil} ->
        patient_gsrn

      {{patient_time, patient_gsrn}, {user_time, user_gsrn}} ->
        if DateTime.compare(patient_time, user_time) == :gt, do: patient_gsrn, else: user_gsrn
    end
  end

  def list_patients do
    filtered_patients_query(%{})
    |> Repo.all()
    |> Repo.preload(:documents)
    |> Enum.map(&Patient.with_age/1)
  end

  def list_patients_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    filtered_patients_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload(:documents)
    |> Enum.map(&Patient.with_age/1)
  end

  def count_patients(filters \\ %{}) do
    filtered_patients_query(filters)
    |> exclude(:order_by)
    |> select([p], count(p.id))
    |> Repo.one()
  end

  def get_available_gsrn do
    base_gsrn =
      if is_nil(last_patient_gsrn()) do
        "616300000000000000"
      else
        last_patient_gsrn()
      end

    new_gsrn =
      base_gsrn
      |> String.slice(0..16)
      |> String.to_integer()
      |> Kernel.+(1)
      |> Gtin.generate!()
      |> to_string()

    if gsrn_exists?(new_gsrn) do
      # If exists, try again with the new GSRN as base
      get_available_gsrn_with_base(new_gsrn)
    else
      new_gsrn
    end
  end

  # Helper function to generate next GSRN with a specific base
  defp get_available_gsrn_with_base(base_gsrn) do
    next_gsrn =
      base_gsrn
      |> String.slice(0..16)
      |> String.to_integer()
      |> Kernel.+(1)
      |> Gtin.generate!()
      |> to_string()

    if gsrn_exists?(next_gsrn) do
      get_available_gsrn_with_base(next_gsrn)
    else
      next_gsrn
    end
  end

  # Function to check if GSRN already exists in the database
  defp gsrn_exists?(gsrn) do
    user_gsrn =
      from u in Medcamp.Accounts.User,
        where: u.gsrn == ^gsrn,
        select: u.id

    patient_gsrn =
      from p in Patient,
        where: p.gsrn == ^gsrn,
        select: p.id

    Repo.exists?(user_gsrn) or Repo.exists?(patient_gsrn)
  end

  def list_patients_for_selection do
    Repo.all(
      from p in Patient,
        select:
          {fragment("concat_ws(' ', ?, ?, ?)", p.first_name, p.middle_name, p.last_name), p.id}
    )
  end

  def get_patient_by_gsrn(gsrn) do
    Repo.get_by(Patient, gsrn: gsrn)
  end

  @doc """
  Gets a single patient.

  Raises `Ecto.NoResultsError` if the Patient does not exist.

  ## Examples

      iex> get_patient!(123)
      %Patient{}

      iex> get_patient!(456)
      ** (Ecto.NoResultsError)

  """
  def get_patient!(id) do
    Repo.get!(Patient, id)
    |> Repo.preload(:documents)
    |> Patient.with_age()
  end

  def get_patient(id) do
    Repo.get(Patient, id)
    |> Repo.preload(:documents)
  end

  def search_patients(search_term) do
    search_term = "%#{search_term}%"

    Repo.all(
      from p in Patient,
        where:
          ilike(p.first_name, ^search_term) or
            ilike(p.middle_name, ^search_term) or
            ilike(p.last_name, ^search_term) or
            ilike(p.national_id, ^search_term) or
            ilike(p.email, ^search_term) or
            ilike(p.phone_number, ^search_term) or
            ilike(p.gsrn, ^search_term)
    )
  end

  @doc """
  Returns patients that have at least one visit matching the given visit-based filters.
  Filters: date_from, date_to, time_from, time_to, age_group, gender, diagnosis, visit_type.
  Optionally filters by search term on patient name, email, phone, etc.
  """
  def list_patients_by_visit_filters(filters \\ %{}) do
    visits = Medcamp.PatientVisits.filter_patient_visits(filters)
    patients = visits |> Enum.map(& &1.patient) |> Enum.uniq_by(& &1.id)

    case filters[:search] do
      nil -> patients
      "" -> patients
      term -> filter_patients_by_search(patients, term)
    end
  end

  defp filter_patients_by_search(patients, term) do
    term = String.downcase(String.trim(term))

    if term == "" do
      patients
    else
      Enum.filter(patients, fn p ->
        [
          p.first_name,
          p.middle_name,
          p.last_name,
          p.email,
          p.phone_number,
          p.national_id,
          p.gsrn
        ]
        |> Enum.any?(fn v -> v && String.contains?(String.downcase(v), term) end)
      end)
    end
  end

  def filter_patients(filters \\ %{}) do
    filtered_patients_query(filters)
    |> Repo.all()
    |> Repo.preload(:documents)
    |> Enum.map(&Patient.with_age/1)
    |> apply_age_filter_post(filters[:age_group])
  end

  def filter_patients_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    filtered_patients_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload(:documents)
    |> Enum.map(&Patient.with_age/1)
    |> apply_age_filter_post(filters[:age_group])
  end

  defp filtered_patients_query(filters) do
    from(p in Patient,
      order_by: [desc: p.inserted_at]
    )
    |> apply_search_filter(filters[:search])
    |> apply_date_filter(filters[:date_from], filters[:date_to])
    |> apply_gender_filter(filters[:gender])
    |> apply_age_filter(filters[:age_group])
    |> apply_creator_filter(filters[:creator_id])
  end

  defp apply_creator_filter(query, nil), do: query
  defp apply_creator_filter(query, ""), do: query

  defp apply_creator_filter(query, creator_id) when is_binary(creator_id) do
    case Integer.parse(creator_id) do
      {id, ""} -> from p in query, where: p.creator_id == ^id
      _ -> query
    end
  end

  defp apply_creator_filter(query, creator_id) when is_integer(creator_id) do
    from p in query, where: p.creator_id == ^creator_id
  end

  defp apply_search_filter(query, nil), do: query
  defp apply_search_filter(query, ""), do: query

  defp apply_search_filter(query, search) do
    search_term = "%#{String.trim(search)}%"

    from p in query,
      where:
        ilike(p.first_name, ^search_term) or
          ilike(p.middle_name, ^search_term) or
          ilike(p.last_name, ^search_term) or
          ilike(p.national_id, ^search_term) or
          ilike(p.email, ^search_term) or
          ilike(p.phone_number, ^search_term) or
          ilike(p.gsrn, ^search_term)
  end

  defp apply_date_filter(query, nil, nil), do: query

  defp apply_date_filter(query, date_from, nil) do
    from p in query,
      where: fragment("DATE(?) >= ?", p.inserted_at, ^date_from)
  end

  defp apply_date_filter(query, nil, date_to) do
    from p in query,
      where: fragment("DATE(?) <= ?", p.inserted_at, ^date_to)
  end

  defp apply_date_filter(query, date_from, date_to) do
    from p in query,
      where:
        fragment("DATE(?) >= ?", p.inserted_at, ^date_from) and
          fragment("DATE(?) <= ?", p.inserted_at, ^date_to)
  end

  defp apply_gender_filter(query, nil), do: query
  defp apply_gender_filter(query, gender), do: from(p in query, where: p.gender == ^gender)

  defp apply_age_filter(query, nil), do: query

  defp apply_age_filter(query, age_group) when age_group in ["<5", "5-17", "18-59", "60+"] do
    today = Date.utc_today()
    cutoff = fn years -> %{today | year: today.year - years} end

    case age_group do
      "<5" ->
        from p in query, where: p.date_of_birth >= ^cutoff.(5)

      "5-17" ->
        from p in query,
          where: p.date_of_birth < ^cutoff.(5) and p.date_of_birth >= ^cutoff.(18)

      "18-59" ->
        from p in query,
          where: p.date_of_birth < ^cutoff.(18) and p.date_of_birth >= ^cutoff.(60)

      "60+" ->
        from p in query, where: p.date_of_birth < ^cutoff.(60)
    end
  end

  defp apply_age_filter(query, _), do: query

  defp apply_age_filter_post(patients, nil), do: patients

  defp apply_age_filter_post(patients, age_group)
       when age_group in ["<5", "5-17", "18-59", "60+"] do
    Enum.filter(patients, fn patient ->
      age = Patient.calculate_age(patient.date_of_birth)

      case age_group do
        "<5" -> age != nil and age < 5
        "5-17" -> age != nil and age >= 5 and age < 18
        "18-59" -> age != nil and age >= 18 and age < 60
        "60+" -> age != nil and age >= 60
      end
    end)
  end

  defp apply_age_filter_post(patients, _), do: patients

  def list_medical_camp_patients(date \\ Date.utc_today()) do
    medical_camp_patients_query()
    |> where([p], fragment("DATE(?)", p.inserted_at) == ^date)
    |> order_by([p], asc: p.inserted_at)
    |> Repo.all()
    |> Enum.map(&Patient.with_age/1)
  end

  def list_all_medical_camp_patients do
    medical_camp_patients_query()
    |> order_by([p], asc: p.inserted_at)
    |> Repo.all()
    |> Enum.map(&Patient.with_age/1)
  end

  def list_medical_camp_patients_for_dates(dates) when is_list(dates) do
    medical_camp_patients_query()
    |> where(
      [p],
      fragment("DATE(? AT TIME ZONE 'Africa/Nairobi')", p.inserted_at) in ^dates
    )
    |> order_by([p], asc: p.inserted_at)
    |> Repo.all()
    |> Enum.map(&Patient.with_age/1)
  end

  def medical_camp_patients_query do
    from(p in Patient,
      where: fragment("coalesce(?, false) = true", p.is_for_medical_camp)
    )
  end

  def medical_camp_stats(date \\ Date.utc_today()) do
    list_medical_camp_patients(date) |> compute_camp_stats()
  end

  def all_medical_camp_stats do
    list_all_medical_camp_patients() |> compute_camp_stats()
  end

  def compute_camp_stats_for_patients(patients), do: compute_camp_stats(patients)

  defp compute_camp_stats(patients) do
    age_groups = %{
      under_5: Enum.count(patients, fn p -> p.age && p.age < 5 end),
      age_5_17: Enum.count(patients, fn p -> p.age && p.age >= 5 && p.age < 18 end),
      age_18_59: Enum.count(patients, fn p -> p.age && p.age >= 18 && p.age < 60 end),
      over_60: Enum.count(patients, fn p -> p.age && p.age >= 60 end)
    }

    patient_types =
      patients
      |> Enum.group_by(fn p -> p.patient_type || "Unspecified" end)
      |> Enum.map(fn {type, pts} -> {type, length(pts)} end)
      |> Enum.sort_by(fn {_, count} -> count end, :desc)

    %{
      total: length(patients),
      male: Enum.count(patients, fn p -> p.gender == "Male" end),
      female: Enum.count(patients, fn p -> p.gender == "Female" end),
      age_groups: age_groups,
      patient_types: patient_types
    }
  end

  @doc """
  Creates a patient.

  ## Examples

      iex> create_patient(%{field: value})
      {:ok, %Patient{}}

      iex> create_patient(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_patient(attrs \\ %{}) do
    random_pin = :rand.uniform(9000) + 999

    attrs =
      attrs
      |> stringify_keys()
      |> Map.put("gsrn", get_available_gsrn())
      |> Map.put("pin", random_pin)

    result =
      %Patient{}
      |> Patient.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, patient} ->
        Task.start(fn -> send_pin(patient) end)

      {:error, _} ->
        nil
    end

    result
  end

  def create_patient_document(attrs \\ %{}) do
    %PatientDocument{}
    |> PatientDocument.changeset(attrs)
    |> Repo.insert()
  end

  def get_patient_document(patient_id, document_type) do
    Repo.get_by(
      PatientDocument,
      patient_id: patient_id,
      document_type: document_type
    )
  end

  def update_patient_document(%PatientDocument{} = document, attrs) do
    document
    |> PatientDocument.changeset(attrs)
    |> Repo.update()
  end

  def list_patient_documents(patient_id) do
    from(d in PatientDocument,
      where: d.patient_id == ^patient_id,
      order_by: [desc: d.inserted_at]
    )
    |> Repo.all()
  end

  def delete_patient_document(%PatientDocument{} = document) do
    Repo.delete(document)
  end

  def change_patient_document(
        %PatientDocument{} = document,
        attrs \\ %{}
      ) do
    PatientDocument.changeset(document, attrs)
  end

  def find_or_create_public_booking_patient(attrs) when is_map(attrs) do
    normalized_attrs =
      attrs
      |> stringify_keys()
      |> Map.update("email", nil, &normalize_value/1)
      |> Map.update("phone_number", nil, &normalize_value/1)
      |> Map.update("first_name", nil, &normalize_value/1)
      |> Map.update("last_name", nil, &normalize_value/1)

    case find_public_booking_patient(normalized_attrs) do
      nil ->
        %Patient{}
        |> Patient.public_booking_changeset(normalized_attrs)
        |> Repo.insert()

      patient ->
        {:ok, patient}
    end
  end

  def send_pin(patient) do
    Medcamp.Postal.deliver_pin_to_patient(patient.email, patient.pin)

    Medcamp.Advanta.send_message(
      "Hello #{patient.first_name}, thank you for visiting GHCE. Your PIN is #{patient.pin}. Please use this PIN for your next visit.",
      patient.phone_number
    )
  end

  @doc """
  Updates a patient.

  ## Examples

      iex> update_patient(patient, %{field: new_value})
      {:ok, %Patient{}}

      iex> update_patient(patient, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_patient(%Patient{} = patient, attrs) do
    patient
    |> Patient.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a patient.

  ## Examples

      iex> delete_patient(patient)
      {:ok, %Patient{}}

      iex> delete_patient(patient)
      {:error, %Ecto.Changeset{}}

  """
  def delete_patient(%Patient{} = patient) do
    Repo.delete(patient)
  end

  defp find_public_booking_patient(%{"email" => email, "phone_number" => phone_number}) do
    find_patient_by_email(email) || find_patient_by_phone_number(phone_number)
  end

  defp find_patient_by_email(nil), do: nil

  defp find_patient_by_email(email) do
    Repo.one(
      from p in Patient,
        where: not is_nil(p.email) and fragment("lower(?)", p.email) == ^String.downcase(email),
        limit: 1
    )
  end

  defp find_patient_by_phone_number(nil), do: nil

  defp find_patient_by_phone_number(phone_number) do
    Repo.get_by(Patient, phone_number: phone_number)
  end

  defp stringify_keys(attrs) do
    Map.new(attrs, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      {key, value} -> {key, value}
    end)
  end

  defp normalize_value(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp normalize_value(value), do: value

  @doc """
  Deletes a patient and every associated record across all tables, looked up by GSRN.
  Runs inside a single database transaction.
  Returns {:ok, patient} or {:error, :not_found} or {:error, reason}.
  """
  def delete_patient_by_gsrn(gsrn) do
    case Repo.get_by(Patient, gsrn: gsrn) do
      nil ->
        {:error, :not_found}

      patient ->
        Repo.transaction(fn ->
          id = patient.id

          # Delete leaf-level records first (those that reference other patient records via FK)
          Repo.delete_all(
            from r in Medcamp.LabConsumables.LabConsumable, where: r.patient_id == ^id
          )

          Repo.delete_all(
            from r in Medcamp.NursingConsumables.NursingConsumable, where: r.patient_id == ^id
          )

          # lab_results references doctor_notes — must go before doctor_notes
          Repo.delete_all(from r in Medcamp.LabResults.LabResult, where: r.patient_id == ^id)

          # radiology and referrals may reference doctor_notes — delete before doctor_notes
          Repo.delete_all(
            from r in Medcamp.RadiologyResults.RadiologyResult, where: r.patient_id == ^id
          )

          Repo.delete_all(from r in Medcamp.Referrals.Referral, where: r.patient_id == ^id)

          # procedures may reference doctor/nurse notes — delete before notes
          Repo.delete_all(
            from r in Medcamp.DoctorProcedures.DoctorProcedure, where: r.patient_id == ^id
          )

          Repo.delete_all(
            from r in Medcamp.NurseProcedures.NurseProcedure, where: r.patient_id == ^id
          )

          # notes
          Repo.delete_all(from r in Medcamp.DoctorNotes.DoctorNote, where: r.patient_id == ^id)
          Repo.delete_all(from r in Medcamp.NurseNotes.NurseNote, where: r.patient_id == ^id)
          Repo.delete_all(from r in Medcamp.Inpatient.AdmissionNote, where: r.patient_id == ^id)
          Repo.delete_all(from r in Medcamp.CadexNotes.CadexNote, where: r.patient_id == ^id)

          # remaining independent records
          Repo.delete_all(
            from r in Medcamp.DrugAllocations.DrugAllocation, where: r.patient_id == ^id
          )

          Repo.delete_all(
            from r in Medcamp.PatientCharges.PatientCharge, where: r.patient_id == ^id
          )

          Repo.delete_all(
            from r in Medcamp.PatientCharges.PatientChargeBatch, where: r.patient_id == ^id
          )

          Repo.delete_all(
            from r in Medcamp.PatientFormRecords.PatientFormRecord, where: r.patient_id == ^id
          )

          Repo.delete_all(from r in Medcamp.PatientVisits.PatientVisit, where: r.patient_id == ^id)
          Repo.delete_all(from r in Medcamp.Appointments.Appointment, where: r.patient_id == ^id)

          Repo.delete_all(
            from r in Medcamp.AdmissionRequests.AdmissionRequest, where: r.patient_id == ^id
          )

          Repo.delete_all(
            from r in Medcamp.RoomAllocations.RoomAllocation, where: r.patient_id == ^id
          )

          Repo.delete_all(from r in Medcamp.Triages.Triage, where: r.patient_id == ^id)
          Repo.delete_all(from r in Medcamp.Mch.Mother, where: r.patient_id == ^id)
          Repo.delete_all(from r in Medcamp.Mpesas.Mpesa, where: r.patient_id == ^id)

          Repo.delete_all(
            from r in Medcamp.WalletDeposits.WalletDeposit, where: r.patient_id == ^id
          )

          Repo.delete_all(
            from r in Medcamp.WalletWithdrawals.WalletWithdrawal, where: r.patient_id == ^id
          )

          Repo.delete!(patient)
          patient
        end)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking patient changes.

  ## Examples

      iex> change_patient(patient)
      %Ecto.Changeset{data: %Patient{}}

  """
  def change_patient(%Patient{} = patient, attrs \\ %{}) do
    Patient.changeset(patient, attrs)
  end
end
