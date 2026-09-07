defmodule Medcamp.Appointments do
  @moduledoc """
  The Appointments context.
  """

  import Ecto.Query, warn: false
  alias Phoenix.PubSub
  alias Medcamp.Repo
  alias Medcamp.Patients

  alias Medcamp.Appointments.{Appointment, PublicBooking}

  @topic "appointments"

  @doc """
  Returns the list of appointments.

  ## Examples

      iex> list_appointments()
      [%Appointment{}, ...]

  """
  def list_appointments(filters \\ %{}) do
    appointments_list_query(filters)
    |> Repo.all()
  end

  def list_appointments_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    appointments_list_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_appointments(filters \\ %{}) do
    appointments_count_query(filters)
    |> select([a], count(a.id))
    |> Repo.one()
  end

  def subscribe do
    PubSub.subscribe(Medcamp.PubSub, @topic)
  end

  def filter_appointments(filters \\ %{}) do
    appointments_list_query(filters)
    |> Repo.all()
  end

  def filter_appointments_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    appointments_list_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def list_appointments_by_patient(patient_id) do
    Appointment
    |> where([a], a.patient_id == ^patient_id)
    |> Repo.all()
    |> Repo.preload([:patient, :doctor])
  end

  def list_appointments_by_patient_paginated(patient_id, page \\ 1, per_page \\ 20) do
    Appointment
    |> where([a], a.patient_id == ^patient_id)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:patient, :doctor])
  end

  def count_appointments_by_patient(patient_id) do
    from(a in Appointment, where: a.patient_id == ^patient_id, select: count(a.id))
    |> Repo.one()
  end

  def list_appointments_by_doctor(doctor_id) do
    Appointment
    |> where([a], a.doctor_id == ^doctor_id)
    |> Repo.all()
    |> Repo.preload([:patient, :doctor])
  end

  def list_appointments_by_doctor_paginated(doctor_id, filters \\ %{}, page \\ 1, per_page \\ 20) do
    doctor_id
    |> appointments_by_doctor_query(filters)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload([:patient, :doctor])
  end

  def count_appointments_by_doctor(doctor_id, filters \\ %{}) do
    doctor_id
    |> appointments_by_doctor_query(filters)
    |> Repo.aggregate(:count, :id)
  end

  defp appointments_by_doctor_query(doctor_id, filters) do
    Appointment
    |> where([a], a.doctor_id == ^doctor_id)
    |> apply_doctor_appointment_search(filters[:search])
  end

  defp apply_doctor_appointment_search(query, nil), do: query
  defp apply_doctor_appointment_search(query, ""), do: query

  defp apply_doctor_appointment_search(query, term) do
    term = String.trim(term)

    if term == "" do
      query
    else
      pattern = "%#{term}%"

      from(a in query,
        left_join: pat in assoc(a, :patient),
        where:
          ilike(pat.first_name, ^pattern) or ilike(pat.middle_name, ^pattern) or
            ilike(pat.last_name, ^pattern) or ilike(a.reason, ^pattern)
      )
    end
  end

  @doc """
  Count today's appointments for a doctor.
  """
  def count_today_appointments_for_doctor(doctor_id) do
    today = Date.utc_today()

    from(a in Appointment,
      where: a.doctor_id == ^doctor_id and a.date == ^today,
      select: count(a.id)
    )
    |> Repo.one()
  end

  @doc """
  Gets a single appointment.

  Raises `Ecto.NoResultsError` if the Appointment does not exist.

  ## Examples

      iex> get_appointment!(123)
      %Appointment{}

      iex> get_appointment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_appointment!(id) do
    Appointment
    |> Repo.get!(id)
    |> Repo.preload([:patient, :doctor])
  end

  @doc """
  Creates a appointment.

  ## Examples

      iex> create_appointment(%{field: value})
      {:ok, %Appointment{}}

      iex> create_appointment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_appointment(attrs \\ %{}) do
    %Appointment{}
    |> Appointment.changeset(attrs)
    |> Repo.insert()
    |> broadcast(:appointment_created)
  end

  def create_public_appointment(attrs \\ %{}) do
    changeset = change_public_booking(attrs)

    with true <- changeset.valid? || {:error, Map.put(changeset, :action, :validate)},
         booking <- Ecto.Changeset.apply_changes(changeset),
         {:ok, patient} <-
           Patients.find_or_create_public_booking_patient(patient_attrs_from_booking(booking)),
         {:ok, appointment} <-
           create_appointment(appointment_attrs_from_booking(booking, patient.id)) do
      {:ok, appointment}
    end
  end

  @doc """
  Updates a appointment.

  ## Examples

      iex> update_appointment(appointment, %{field: new_value})
      {:ok, %Appointment{}}

      iex> update_appointment(appointment, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_appointment(%Appointment{} = appointment, attrs) do
    appointment
    |> Appointment.changeset(attrs)
    |> Repo.audited_update()
    |> broadcast(:appointment_updated)
  end

  @doc """
  Deletes a appointment.

  ## Examples

      iex> delete_appointment(appointment)
      {:ok, %Appointment{}}

      iex> delete_appointment(appointment)
      {:error, %Ecto.Changeset{}}

  """
  def delete_appointment(%Appointment{} = appointment) do
    appointment = Repo.preload(appointment, [:patient, :doctor])

    case Repo.delete(appointment) do
      {:ok, deleted_appointment} = result ->
        PubSub.broadcast(Medcamp.PubSub, @topic, {:appointment_deleted, deleted_appointment})
        result

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking appointment changes.

  ## Examples

      iex> change_appointment(appointment)
      %Ecto.Changeset{data: %Appointment{}}

  """
  def change_appointment(%Appointment{} = appointment, attrs \\ %{}) do
    Appointment.changeset(appointment, attrs)
  end

  def change_public_booking(attrs \\ %{}) do
    PublicBooking.changeset(%PublicBooking{}, attrs)
  end

  defp appointments_list_query(filters) do
    Appointment
    |> join(:left, [a], p in assoc(a, :patient))
    |> join(:left, [a, p], d in assoc(a, :doctor))
    |> preload([_a, p, d], patient: p, doctor: d)
    |> order_by([a, _p, _d], desc: a.date, desc: a.time)
    |> apply_patient_search_filter(filters[:patient_search])
    |> apply_doctor_filter(filters[:doctor_id])
    |> apply_date_from_filter(filters[:date_from])
    |> apply_date_to_filter(filters[:date_to])
  end

  defp appointments_count_query(filters) do
    Appointment
    |> join(:left, [a], p in assoc(a, :patient))
    |> join(:left, [a, p], d in assoc(a, :doctor))
    |> apply_patient_search_filter(filters[:patient_search])
    |> apply_doctor_filter(filters[:doctor_id])
    |> apply_date_from_filter(filters[:date_from])
    |> apply_date_to_filter(filters[:date_to])
  end

  defp apply_patient_search_filter(query, nil), do: query
  defp apply_patient_search_filter(query, ""), do: query

  defp apply_patient_search_filter(query, term) do
    pattern = "%#{String.trim(term)}%"

    from [a, p, d] in query,
      where:
        ilike(p.first_name, ^pattern) or
          ilike(p.middle_name, ^pattern) or
          ilike(p.last_name, ^pattern) or
          ilike(p.phone_number, ^pattern) or
          ilike(p.gsrn, ^pattern) or
          ilike(a.reason, ^pattern)
  end

  defp apply_doctor_filter(query, nil), do: query
  defp apply_doctor_filter(query, ""), do: query

  defp apply_doctor_filter(query, doctor_id) when is_integer(doctor_id) do
    from [a, p, d] in query, where: a.doctor_id == ^doctor_id
  end

  defp apply_doctor_filter(query, doctor_id) when is_binary(doctor_id) do
    case Integer.parse(doctor_id) do
      {id, _} -> from [a, p, d] in query, where: a.doctor_id == ^id
      :error -> query
    end
  end

  defp apply_doctor_filter(query, _), do: query

  defp apply_date_from_filter(query, nil), do: query
  defp apply_date_from_filter(query, ""), do: query

  defp apply_date_from_filter(query, date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, parsed_date} -> from [a, p, d] in query, where: a.date >= ^parsed_date
      _ -> query
    end
  end

  defp apply_date_to_filter(query, nil), do: query
  defp apply_date_to_filter(query, ""), do: query

  defp apply_date_to_filter(query, date) when is_binary(date) do
    case Date.from_iso8601(date) do
      {:ok, parsed_date} -> from [a, p, d] in query, where: a.date <= ^parsed_date
      _ -> query
    end
  end

  defp patient_attrs_from_booking(booking) do
    %{
      "first_name" => booking.first_name,
      "last_name" => booking.last_name,
      "email" => booking.email,
      "phone_number" => booking.phone_number
    }
  end

  defp appointment_attrs_from_booking(booking, patient_id) do
    %{
      "patient_id" => patient_id,
      "date" => booking.date,
      "time" => booking.time,
      "reason" => build_public_booking_reason(booking)
    }
  end

  defp build_public_booking_reason(%PublicBooking{} = booking) do
    "Website booking: #{PublicBooking.service_label(booking.service)}. #{booking.message}"
  end

  defp broadcast({:ok, %Appointment{} = appointment}, event) do
    appointment = Repo.preload(appointment, [:patient, :doctor])
    PubSub.broadcast(Medcamp.PubSub, @topic, {event, appointment})
    {:ok, appointment}
  end

  defp broadcast(result, _event), do: result
end
