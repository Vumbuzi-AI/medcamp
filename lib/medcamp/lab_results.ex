defmodule Medcamp.LabResults do
  @moduledoc """
  The LabResults context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.LabResults.LabResult
  alias Medcamp.LabResults.InterpretationBuilder
  alias Phoenix.PubSub

  @pubsub Medcamp.PubSub

  @doc """
  Returns the list of lab_results.

  ## Examples

      iex> list_lab_results()
      [%LabResult{}, ...]

  """
  def list_lab_results do
    LabResult
    |> order_by([l], desc: l.inserted_at)
    |> preload([:doctor_note, :patient, :doctor])
    |> Repo.all()
  end

  def filter_lab_results(filters \\ %{}) do
    filters
    |> lab_results_query()
    |> Repo.all()
    |> Enum.map(fn lr ->
      # Ensure patient has age calculated
      %{lr | patient: Medcamp.Patients.Patient.with_age(lr.patient)}
    end)
  end

  def filter_lab_results_paginated(filters \\ %{}, page \\ 1, per_page \\ 20) do
    filters
    |> lab_results_query()
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Enum.map(fn lr ->
      %{lr | patient: Medcamp.Patients.Patient.with_age(lr.patient)}
    end)
  end

  def count_lab_results(filters \\ %{}) do
    filters
    |> lab_results_query()
    |> Repo.aggregate(:count, :id)
  end

  defp apply_date_filter(query, nil, nil), do: query

  defp apply_date_filter(query, date_from, nil) do
    from [lr, _pat, _doc] in query,
      where: fragment("DATE(?)", lr.inserted_at) >= ^date_from
  end

  defp apply_date_filter(query, nil, date_to) do
    from [lr, _pat, _doc] in query,
      where: fragment("DATE(?)", lr.inserted_at) <= ^date_to
  end

  defp apply_date_filter(query, date_from, date_to) do
    from [lr, _pat, _doc] in query,
      where:
        fragment("DATE(?)", lr.inserted_at) >= ^date_from and
          fragment("DATE(?)", lr.inserted_at) <= ^date_to
  end

  defp apply_time_filter(query, nil, nil), do: query

  defp apply_time_filter(query, time_from, nil) do
    from [lr, _pat, _doc] in query,
      where: lr.time >= ^time_from
  end

  defp apply_time_filter(query, nil, time_to) do
    from [lr, _pat, _doc] in query,
      where: lr.time <= ^time_to
  end

  defp apply_time_filter(query, time_from, time_to) do
    from [lr, _pat, _doc] in query,
      where: lr.time >= ^time_from and lr.time <= ^time_to
  end

  defp apply_gender_filter(query, nil), do: query

  defp apply_gender_filter(query, gender) do
    from [lr, pat, _doc] in query,
      where: pat.gender == ^gender
  end

  defp apply_age_filter(query, nil), do: query

  defp apply_age_filter(query, age_group) when age_group in ["<5", "≥5"] do
    today = Date.utc_today()

    case age_group do
      "<5" ->
        cutoff_date = %{today | year: today.year - 5}
        from [lr, pat, _doc] in query, where: pat.date_of_birth >= ^cutoff_date

      "≥5" ->
        cutoff_date = %{today | year: today.year - 5}
        from [lr, pat, _doc] in query, where: pat.date_of_birth < ^cutoff_date
    end
  end

  defp apply_age_filter(query, _), do: query

  defp apply_urgency_filter(query, nil), do: query
  defp apply_urgency_filter(query, ""), do: query

  defp apply_urgency_filter(query, urgency) do
    from [lr, _pat, _doc] in query,
      where: lr.urgency == ^urgency
  end

  defp apply_report_complete_filter(query, nil), do: query
  defp apply_report_complete_filter(query, ""), do: query

  defp apply_report_complete_filter(query, "true") do
    from [lr, _pat, _doc] in query,
      where: lr.report_complete == true
  end

  defp apply_report_complete_filter(query, "false") do
    from [lr, _pat, _doc] in query,
      where: lr.report_complete == false
  end

  defp apply_report_complete_filter(query, _), do: query

  defp apply_doctor_filter(query, nil), do: query
  defp apply_doctor_filter(query, ""), do: query

  defp apply_doctor_filter(query, doctor_id) when is_binary(doctor_id) do
    doctor_id_int = String.to_integer(doctor_id)

    from [lr, _pat, doc] in query,
      where: doc.id == ^doctor_id_int
  end

  defp apply_doctor_filter(query, doctor_id) when is_integer(doctor_id) do
    from [lr, _pat, doc] in query,
      where: doc.id == ^doctor_id
  end

  defp apply_doctor_filter(query, _), do: query

  defp apply_search_filter(query, nil), do: query
  defp apply_search_filter(query, ""), do: query

  defp apply_search_filter(query, term) do
    search = "%#{term}%"

    from [_lr, pat, _doc] in query,
      where:
        ilike(pat.first_name, ^search) or
          ilike(pat.middle_name, ^search) or
          ilike(pat.last_name, ^search) or
          ilike(pat.email, ^search) or
          ilike(pat.gsrn, ^search)
  end

  defp apply_test_name_filter(query, nil), do: query
  defp apply_test_name_filter(query, ""), do: query

  defp apply_test_name_filter(query, test_name) do
    # Filter by test name in the JSONB tests array
    # The tests are stored as JSONB array, each test has a "name" field
    from [lr, _pat, _doc] in query,
      where:
        fragment(
          "EXISTS (SELECT 1 FROM jsonb_array_elements(?) AS test WHERE test->>'name' = ?)",
          lr.tests,
          ^test_name
        )
  end

  @doc """
  Returns a list of all unique test names from lab results.
  """
  def list_unique_test_names do
    # Query all lab results and extract unique test names from the JSONB tests array
    Repo.all(
      from lr in LabResult,
        where: not is_nil(lr.tests)
    )
    |> Enum.flat_map(fn lr ->
      case lr.tests do
        tests when is_list(tests) ->
          Enum.map(tests, fn test ->
            case test do
              %{name: name} when is_binary(name) -> name
              %{"name" => name} when is_binary(name) -> name
              _ -> nil
            end
          end)

        _ ->
          []
      end
    end)
    |> Enum.filter(&(&1 != nil))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def list_lab_results_for_doctor_note(doctor_note_id) do
    LabResult
    |> where([l], l.doctor_note_id == ^doctor_note_id)
    |> order_by([l], desc: l.inserted_at)
    |> Repo.all()
  end

  def list_lab_results_paginated(page \\ 1, per_page \\ 20) do
    LabResult
    |> order_by([l], desc: l.inserted_at)
    |> preload([:doctor_note, :patient, :doctor])
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def list_lab_results_for_patient(patient_id) do
    LabResult
    |> where([l], l.patient_id == ^patient_id)
    |> order_by([l], desc: l.inserted_at)
    |> preload([:doctor_note, :patient, :doctor])
    |> Repo.all()
  end

  def list_lab_results_for_patient_paginated(patient_id, page \\ 1, per_page \\ 10) do
    LabResult
    |> where([l], l.patient_id == ^patient_id)
    |> order_by([l], desc: l.inserted_at)
    |> preload([:doctor_note, :patient, :doctor])
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
  end

  def count_lab_results_for_patient(patient_id) do
    LabResult
    |> where([l], l.patient_id == ^patient_id)
    |> Repo.aggregate(:count, :id)
  end

  def list_lab_results_for_patients([]), do: []

  def list_lab_results_for_patients(patient_ids) do
    LabResult
    |> where([l], l.patient_id in ^patient_ids)
    |> order_by([l], desc: l.inserted_at)
    |> preload([:doctor_note, :patient, :doctor])
    |> Repo.all()
  end

  def count_lab_results_for_patients(patient_ids) when patient_ids == [], do: 0

  def count_lab_results_for_patients(patient_ids) do
    from(lr in LabResult,
      where: lr.patient_id in ^patient_ids,
      select: count(lr.id)
    )
    |> Repo.one()
  end

  defp lab_results_query(filters) do
    base_query =
      from lr in LabResult,
        join: pat in assoc(lr, :patient),
        join: doc in assoc(lr, :doctor),
        order_by: [desc: lr.inserted_at],
        preload: [:doctor_note, :patient, :doctor]

    base_query
    |> apply_search_filter(filters[:search])
    |> apply_date_filter(filters[:date_from], filters[:date_to])
    |> apply_time_filter(filters[:time_from], filters[:time_to])
    |> apply_gender_filter(filters[:gender])
    |> apply_age_filter(filters[:age_group])
    |> apply_urgency_filter(filters[:urgency])
    |> apply_report_complete_filter(filters[:report_complete])
    |> apply_doctor_filter(filters[:doctor_id])
    |> apply_test_name_filter(filters[:test_name])
  end

  @doc """
  Returns a financial summary for a set of medical camp patients.
  Groups lab results by patient, summing total_amount_paid.
  """
  def camp_financials([]), do: empty_financials()

  def camp_financials(patient_ids) do
    results =
      from(lr in LabResult,
        where: lr.patient_id in ^patient_ids,
        preload: [:patient],
        order_by: [asc: lr.patient_id, desc: lr.inserted_at]
      )
      |> Repo.all()

    by_patient =
      results
      |> Enum.group_by(& &1.patient_id)
      |> Enum.map(fn {_patient_id, lab_results} ->
        patient = List.first(lab_results).patient |> Medcamp.Patients.Patient.with_age()

        total_amount = Enum.sum(Enum.map(lab_results, &(&1.total_amount_paid || 0)))

        paid_amount =
          lab_results
          |> Enum.filter(& &1.has_paid)
          |> Enum.map(&(&1.total_amount_paid || 0))
          |> Enum.sum()

        pending_amount =
          lab_results
          |> Enum.reject(& &1.has_paid)
          |> Enum.map(&(&1.total_amount_paid || 0))
          |> Enum.sum()

        test_count = lab_results |> Enum.flat_map(&(&1.tests || [])) |> length()

        %{
          patient: patient,
          lab_results: lab_results,
          total_amount: total_amount,
          paid_amount: paid_amount,
          pending_amount: pending_amount,
          test_count: test_count
        }
      end)
      |> Enum.sort_by(& &1.total_amount, :desc)

    %{
      total_revenue: Enum.sum(Enum.map(by_patient, & &1.total_amount)),
      total_paid: Enum.sum(Enum.map(by_patient, & &1.paid_amount)),
      total_pending: Enum.sum(Enum.map(by_patient, & &1.pending_amount)),
      patient_count: length(by_patient),
      test_count: Enum.sum(Enum.map(by_patient, & &1.test_count)),
      patient_rows: by_patient
    }
  end

  defp empty_financials,
    do: %{
      total_revenue: 0,
      total_paid: 0,
      total_pending: 0,
      patient_count: 0,
      test_count: 0,
      patient_rows: []
    }

  @doc """
  Backfills all lab results for medical camp patients:
  - sets has_paid = true
  - sets total_amount_paid = sum of embedded test prices (if tests have prices and current total is 0)
  """
  def backfill_camp_lab_results do
    alias Medcamp.Patients.Patient

    camp_patient_ids =
      Repo.all(from p in Patient, where: p.is_for_medical_camp == true, select: p.id)

    results =
      Repo.all(
        from lr in LabResult,
          where: lr.patient_id in ^camp_patient_ids
      )

    Enum.each(results, fn lr ->
      tests = lr.tests || []
      total_from_tests = Enum.sum(Enum.map(tests, fn t -> t.price || 0 end))

      new_total =
        if total_from_tests > 0, do: total_from_tests, else: lr.total_amount_paid || 0

      if lr.has_paid != true or lr.total_amount_paid != new_total do
        Repo.update_all(
          from(r in LabResult, where: r.id == ^lr.id),
          set: [has_paid: true, total_amount_paid: new_total]
        )
      end
    end)

    updated = length(results)
    {:ok, updated}
  end

  @doc """
  Count pending lab results for a doctor (not yet completed).
  """
  def count_pending_labs_for_doctor(doctor_id) do
    from(lr in LabResult,
      where: lr.doctor_id == ^doctor_id and lr.report_complete == false,
      select: count(lr.id)
    )
    |> Repo.one()
  end

  @doc """
  Gets a single lab_result.

  Raises `Ecto.NoResultsError` if the Lab result does not exist.

  ## Examples

      iex> get_lab_result!(123)
      %LabResult{}

      iex> get_lab_result!(456)
      ** (Ecto.NoResultsError)

  """
  def get_lab_result!(id) do
    Repo.get!(LabResult, id)
    |> Repo.preload([
      :doctor_note,
      :patient,
      :doctor
    ])
  end

  @doc """
  Creates a lab_result.

  ## Examples

      iex> create_lab_result(%{field: value})
      {:ok, %LabResult{}}

      iex> create_lab_result(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_lab_result(attrs \\ %{}) do
    %LabResult{}
    |> LabResult.changeset(attrs)
    |> Repo.insert()
    |> Medcamp.CampFlow.advance("lab_pending")
  end

  def create_camp_lab_order(attrs \\ %{}) do
    %LabResult{}
    |> LabResult.camp_changeset(attrs)
    |> Repo.insert()
  end

  def change_camp_lab_result(lab_result \\ %LabResult{}, attrs \\ %{}) do
    LabResult.camp_changeset(lab_result, attrs)
  end

  @doc """
  Updates a lab_result.

  ## Examples

      iex> update_lab_result(lab_result, %{field: new_value})
      {:ok, %LabResult{}}

      iex> update_lab_result(lab_result, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_lab_result(%LabResult{} = lab_result, attrs) do
    lab_result
    |> LabResult.changeset(attrs)
    |> Repo.audited_update()
  end

  @doc """
  Deletes a lab_result.

  ## Examples

      iex> delete_lab_result(lab_result)
      {:ok, %LabResult{}}

      iex> delete_lab_result(lab_result)
      {:error, %Ecto.Changeset{}}

  """
  def delete_lab_result(%LabResult{} = lab_result) do
    Repo.delete(lab_result)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking lab_result changes.

  ## Examples

      iex> change_lab_result(lab_result)
      %Ecto.Changeset{data: %LabResult{}}

  """
  def change_lab_result(%LabResult{} = lab_result, attrs \\ %{}) do
    LabResult.changeset(lab_result, attrs)
  end

  def refresh_lab_result_interpretation(%LabResult{} = lab_result) do
    payload = InterpretationBuilder.generate_payload(lab_result)

    attrs = %{
      interpretation_payload: payload,
      interpretation_status: Map.get(payload, "status", "failed"),
      interpretation_generated_at: DateTime.utc_now() |> DateTime.truncate(:second)
    }

    lab_result
    |> Repo.preload([:doctor_note, :patient, :doctor, :lab_technician])
    |> LabResult.interpretation_changeset(attrs)
    |> Repo.update()
  rescue
    error ->
      failed_payload = %{
        "generated_at" =>
          DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
        "source" => "interpretation_builder",
        "status" => "failed",
        "abnormal_findings" => [],
        "clinical_interpretation" => [],
        "recommended_attention" => [],
        "disclaimer" =>
          "For clinician review only. Correlate with history, examination, and previous results.",
        "generation_note" => "Interpretation generation failed: #{Exception.message(error)}"
      }

      lab_result
      |> LabResult.interpretation_changeset(%{
        interpretation_payload: failed_payload,
        interpretation_status: "failed",
        interpretation_generated_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })
      |> Repo.update()
  end

  def refresh_lab_result_interpretation(lab_result_id) when is_integer(lab_result_id) do
    lab_result_id
    |> get_lab_result!()
    |> refresh_lab_result_interpretation()
  end

  @doc """
  PubSub topic carrying interpretation updates for a single lab result.
  """
  def interpretation_topic(lab_result_id), do: "lab_result_interpretation:#{lab_result_id}"

  @doc """
  Subscribes the calling process to interpretation updates for a lab result.
  When generation finishes a `{:interpretation_updated, %LabResult{}}` message
  is delivered.
  """
  def subscribe_to_interpretation(lab_result_id) do
    PubSub.subscribe(@pubsub, interpretation_topic(lab_result_id))
  end

  @doc """
  Refreshes the interpretation in the background so callers (e.g. a LiveView
  modal) are not blocked on the external AI call. The interpretation is marked
  `"pending"` immediately and an `{:interpretation_updated, %LabResult{}}`
  message is broadcast on `interpretation_topic/1` once generation completes.
  """
  def async_refresh_lab_result_interpretation(%LabResult{} = lab_result) do
    lab_result
    |> LabResult.interpretation_changeset(%{interpretation_status: "pending"})
    |> Repo.update()

    spawn_interpretation_refresh(lab_result.id)

    {:ok, lab_result}
  end

  def async_refresh_lab_result_interpretation(lab_result_id) when is_integer(lab_result_id) do
    lab_result_id
    |> get_lab_result!()
    |> async_refresh_lab_result_interpretation()
  end

  defp spawn_interpretation_refresh(lab_result_id) do
    Task.Supervisor.start_child(Medcamp.TaskSupervisor, fn ->
      case refresh_lab_result_interpretation(lab_result_id) do
        {:ok, lab_result} ->
          PubSub.broadcast(
            @pubsub,
            interpretation_topic(lab_result_id),
            {:interpretation_updated, lab_result}
          )

        _ ->
          :ok
      end
    end)
  end
end
