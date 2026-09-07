defmodule Medcamp.Insurance do
  @moduledoc """
  Context for querying all insurance-tagged records across the system.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo
  alias Medcamp.Patients.Patient
  alias Medcamp.PatientVisits.PatientVisit
  alias Medcamp.DrugAllocations.DrugAllocation
  alias Medcamp.NurseProcedures.NurseProcedure
  alias Medcamp.DoctorProcedures.DoctorProcedure
  alias Medcamp.LabResults.LabResult

  @hospital_source_exclusion_dates [~D[2026-03-28], ~D[2026-03-29]]

  def hospital_source_exclusion_dates, do: @hospital_source_exclusion_dates

  @doc """
  Returns all unique patients who have at least one insurance-tagged record.
  Optionally filters by a search string matching patient name, GSRN, email,
  or insurance name (across all four record types).
  """
  def list_insurance_patients(search \\ "", opts \\ %{}) do
    search = String.trim(search)
    source = opts[:source] || opts["source"] || ""

    patients =
      from(p in Patient, where: p.id in ^insurance_patient_ids(opts))
      |> with_patient_source(source)
      |> Repo.all()

    if search == "" do
      patients
    else
      lower = String.downcase(search)

      # Also collect patient IDs that match by insurance name in any table
      insurance_name_patient_ids = patient_ids_matching_insurance_name(lower)

      Enum.filter(patients, fn p ->
        full_name =
          [p.first_name, p.middle_name, p.last_name]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")
          |> String.downcase()

        String.contains?(full_name, lower) or
          String.contains?(String.downcase(p.gsrn || ""), lower) or
          String.contains?(String.downcase(p.email || ""), lower) or
          p.id in insurance_name_patient_ids
      end)
    end
  end

  @doc """
  Returns a single insurance patient by GSRN, respecting the active insurance filters.
  """
  def get_insurance_patient_by_gsrn(gsrn, opts \\ %{}) when is_binary(gsrn) do
    trimmed_gsrn = String.trim(gsrn)
    source = opts[:source] || opts["source"] || ""

    from(p in Patient, where: p.id in ^insurance_patient_ids(opts) and p.gsrn == ^trimmed_gsrn)
    |> with_patient_source(source)
    |> Repo.one()
  end

  defp patient_ids_matching_insurance_name(lower) do
    term = "%#{lower}%"

    []
    |> Kernel.++(
      Repo.all(
        from(v in PatientVisit,
          where: v.payment_type == "Insurance" and ilike(v.insurance_name, ^term),
          select: v.patient_id
        )
        |> exclude_removed_invoice_items()
      )
    )
    |> Kernel.++(
      Repo.all(
        from(d in DrugAllocation,
          where: d.payment_type == "Insurance" and ilike(d.insurance_name, ^term),
          select: d.patient_id
        )
        |> exclude_removed_invoice_items()
      )
    )
    |> Kernel.++(
      Repo.all(
        from(n in NurseProcedure,
          where: n.payment_type == "Insurance" and ilike(n.insurance_name, ^term),
          select: n.patient_id
        )
        |> exclude_removed_invoice_items()
      )
    )
    |> Kernel.++(
      Repo.all(
        from(d in DoctorProcedure,
          where: d.payment_type == "Insurance" and ilike(d.insurance_name, ^term),
          select: d.patient_id
        )
        |> exclude_removed_invoice_items()
      )
    )
    |> Kernel.++(
      Repo.all(
        from(l in LabResult,
          where: l.payment_type == "Insurance" and ilike(l.insurance_name, ^term),
          select: l.patient_id
        )
        |> exclude_removed_invoice_items()
      )
    )
    |> Enum.uniq()
    |> Enum.reject(&is_nil/1)
  end

  # ── Patient source helper ───────────────────────────────────────────────────

  defp with_patient_source(query, "hospital") do
    query
  end

  defp with_patient_source(query, "medical_camp"),
    do: where(query, [p], fragment("coalesce(?, false) = true", p.is_for_medical_camp))

  defp with_patient_source(query, _), do: query

  # ── Date helpers ────────────────────────────────────────────────────────────

  defp parse_filter_date(nil), do: nil
  defp parse_filter_date(""), do: nil
  defp parse_filter_date(%Date{} = date), do: date

  defp parse_filter_date(date_str) when is_binary(date_str) do
    case Date.from_iso8601(String.trim(date_str)) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp parse_filter_date(_), do: nil

  defp parse_date_start(nil), do: nil
  defp parse_date_start(""), do: nil

  defp parse_date_start(%Date{} = date) do
    DateTime.new!(date, ~T[00:00:00], "Africa/Nairobi")
    |> DateTime.shift_zone!("Etc/UTC")
  end

  defp parse_date_start(date_str) when is_binary(date_str) do
    case Date.from_iso8601(String.trim(date_str)) do
      {:ok, date} ->
        DateTime.new!(date, ~T[00:00:00], "Africa/Nairobi")
        |> DateTime.shift_zone!("Etc/UTC")

      _ ->
        nil
    end
  end

  defp parse_date_end(nil), do: nil
  defp parse_date_end(""), do: nil

  defp parse_date_end(%Date{} = date) do
    DateTime.new!(date, ~T[23:59:59], "Africa/Nairobi")
    |> DateTime.shift_zone!("Etc/UTC")
  end

  defp parse_date_end(date_str) when is_binary(date_str) do
    case Date.from_iso8601(String.trim(date_str)) do
      {:ok, date} ->
        DateTime.new!(date, ~T[23:59:59], "Africa/Nairobi")
        |> DateTime.shift_zone!("Etc/UTC")

      _ ->
        nil
    end
  end

  defp with_date_range(query, nil, nil), do: query
  defp with_date_range(query, from_dt, nil), do: where(query, [r], r.inserted_at >= ^from_dt)
  defp with_date_range(query, nil, to_dt), do: where(query, [r], r.inserted_at <= ^to_dt)

  defp with_date_range(query, from_dt, to_dt),
    do: where(query, [r], r.inserted_at >= ^from_dt and r.inserted_at <= ^to_dt)

  defp insurance_date_filters(opts) do
    raw_from = opts[:date_from] || opts["date_from"]
    raw_to = opts[:date_to] || opts["date_to"]
    source = opts[:source] || opts["source"] || ""

    %{
      from_date: parse_filter_date(raw_from),
      to_date: parse_filter_date(raw_to),
      from_dt: parse_date_start(raw_from),
      to_dt: parse_date_end(raw_to),
      excluded_dates: if(source == "hospital", do: hospital_source_exclusion_dates(), else: [])
    }
  end

  defp with_insurance_date_range(
         query,
         :patient_visit,
         %{from_date: from_date, to_date: to_date, excluded_dates: excluded_dates}
       ) do
    query
    |> exclude_removed_invoice_items()
    |> with_date_field_range(:date, from_date, to_date)
    |> exclude_date_field_dates(:date, excluded_dates)
  end

  defp with_insurance_date_range(
         query,
         :lab_result,
         %{from_date: from_date, to_date: to_date, excluded_dates: excluded_dates}
       ) do
    query
    |> exclude_removed_invoice_items()
    |> with_optional_date_field_range(:date_of_test, from_date, to_date)
    |> exclude_optional_date_field_dates(:date_of_test, excluded_dates)
  end

  defp with_insurance_date_range(query, _type, %{
         from_dt: from_dt,
         to_dt: to_dt,
         excluded_dates: excluded_dates
       }) do
    query
    |> exclude_removed_invoice_items()
    |> with_date_range(from_dt, to_dt)
    |> exclude_inserted_at_dates(excluded_dates)
  end

  defp exclude_removed_invoice_items(query) do
    where(
      query,
      [record],
      fragment("COALESCE(?, false) = false", field(record, :excluded_from_insurance_invoice))
    )
  end

  defp with_date_field_range(query, _field_name, nil, nil), do: query

  defp with_date_field_range(query, field_name, from_date, nil),
    do: where(query, [record], field(record, ^field_name) >= ^from_date)

  defp with_date_field_range(query, field_name, nil, to_date),
    do: where(query, [record], field(record, ^field_name) <= ^to_date)

  defp with_date_field_range(query, field_name, from_date, to_date),
    do:
      where(
        query,
        [record],
        field(record, ^field_name) >= ^from_date and field(record, ^field_name) <= ^to_date
      )

  defp with_optional_date_field_range(query, _field_name, nil, nil), do: query

  defp with_optional_date_field_range(query, field_name, from_date, nil) do
    where(
      query,
      [record],
      fragment("COALESCE(?, DATE(?))", field(record, ^field_name), record.inserted_at) >=
        ^from_date
    )
  end

  defp with_optional_date_field_range(query, field_name, nil, to_date) do
    where(
      query,
      [record],
      fragment("COALESCE(?, DATE(?))", field(record, ^field_name), record.inserted_at) <= ^to_date
    )
  end

  defp with_optional_date_field_range(query, field_name, from_date, to_date) do
    where(
      query,
      [record],
      fragment("COALESCE(?, DATE(?))", field(record, ^field_name), record.inserted_at) >=
        ^from_date and
        fragment("COALESCE(?, DATE(?))", field(record, ^field_name), record.inserted_at) <=
          ^to_date
    )
  end

  defp exclude_date_field_dates(query, _field_name, []), do: query

  defp exclude_date_field_dates(query, field_name, dates) do
    Enum.reduce(dates, query, fn date, acc ->
      where(acc, [record], field(record, ^field_name) != ^date)
    end)
  end

  defp exclude_optional_date_field_dates(query, _field_name, []), do: query

  defp exclude_optional_date_field_dates(query, field_name, dates) do
    Enum.reduce(dates, query, fn date, acc ->
      where(
        acc,
        [record],
        fragment(
          "COALESCE(?, DATE(timezone('Africa/Nairobi', ?)))",
          field(record, ^field_name),
          record.inserted_at
        ) !=
          ^date
      )
    end)
  end

  defp exclude_inserted_at_dates(query, []), do: query

  defp exclude_inserted_at_dates(query, dates) do
    Enum.reduce(dates, query, fn date, acc ->
      where(
        acc,
        [record],
        fragment("DATE(timezone('Africa/Nairobi', ?))", record.inserted_at) != ^date
      )
    end)
  end

  # ── End date helpers ─────────────────────────────────────────────────────────

  @doc """
  Returns all unique insurer names used across every insurance record type, sorted alphabetically.
  """
  def list_insurer_names do
    tables = [
      Repo.all(
        from(v in PatientVisit,
          where: v.payment_type == "Insurance" and not is_nil(v.insurance_name),
          select: v.insurance_name,
          distinct: true
        )
        |> exclude_removed_invoice_items()
      ),
      Repo.all(
        from(d in DrugAllocation,
          where: d.payment_type == "Insurance" and not is_nil(d.insurance_name),
          select: d.insurance_name,
          distinct: true
        )
        |> exclude_removed_invoice_items()
      ),
      Repo.all(
        from(n in NurseProcedure,
          where: n.payment_type == "Insurance" and not is_nil(n.insurance_name),
          select: n.insurance_name,
          distinct: true
        )
        |> exclude_removed_invoice_items()
      ),
      Repo.all(
        from(d in DoctorProcedure,
          where: d.payment_type == "Insurance" and not is_nil(d.insurance_name),
          select: d.insurance_name,
          distinct: true
        )
        |> exclude_removed_invoice_items()
      ),
      Repo.all(
        from(l in LabResult,
          where: l.payment_type == "Insurance" and not is_nil(l.insurance_name),
          select: l.insurance_name,
          distinct: true
        )
        |> exclude_removed_invoice_items()
      )
    ]

    tables
    |> List.flatten()
    |> Enum.uniq()
    |> Enum.reject(&is_nil/1)
    |> Enum.sort()
  end

  @doc """
  Returns all unique patients who have records under a specific insurer.
  """
  def list_patients_for_insurer(insurer_name, opts \\ %{}) do
    filters = insurance_date_filters(opts)
    source = opts[:source] || opts["source"] || ""

    patient_ids =
      []
      |> Kernel.++(
        Repo.all(
          from(v in PatientVisit,
            where: v.payment_type == "Insurance" and v.insurance_name == ^insurer_name,
            select: v.patient_id
          )
          |> with_insurance_date_range(:patient_visit, filters)
        )
      )
      |> Kernel.++(
        Repo.all(
          from(d in DrugAllocation,
            where: d.payment_type == "Insurance" and d.insurance_name == ^insurer_name,
            select: d.patient_id
          )
          |> with_insurance_date_range(:drug_allocation, filters)
        )
      )
      |> Kernel.++(
        Repo.all(
          from(n in NurseProcedure,
            where: n.payment_type == "Insurance" and n.insurance_name == ^insurer_name,
            select: n.patient_id
          )
          |> with_insurance_date_range(:nurse_procedure, filters)
        )
      )
      |> Kernel.++(
        Repo.all(
          from(d in DoctorProcedure,
            where: d.payment_type == "Insurance" and d.insurance_name == ^insurer_name,
            select: d.patient_id
          )
          |> with_insurance_date_range(:doctor_procedure, filters)
        )
      )
      |> Kernel.++(
        Repo.all(
          from(l in LabResult,
            where: l.payment_type == "Insurance" and l.insurance_name == ^insurer_name,
            select: l.patient_id
          )
          |> with_insurance_date_range(:lab_result, filters)
        )
      )
      |> Enum.uniq()
      |> Enum.reject(&is_nil/1)

    from(p in Patient, where: p.id in ^patient_ids, order_by: [asc: p.first_name])
    |> with_patient_source(source)
    |> Repo.all()
  end

  @doc """
  Returns aggregate stats for a specific insurer across all record types:
  total records, total amount paid, unique patient count.
  """
  def insurer_summary(insurer_name, opts \\ %{}) do
    filters = insurance_date_filters(opts)
    patient_ids = insurer_patient_ids(insurer_name, opts)

    if patient_ids == [] do
      %{total_records: 0, total_amount: 0, patient_count: 0}
    else
      visit_count =
        Repo.aggregate(
          from(v in PatientVisit,
            where:
              v.payment_type == "Insurance" and v.insurance_name == ^insurer_name and
                v.patient_id in ^patient_ids
          )
          |> with_insurance_date_range(:patient_visit, filters),
          :count
        )

      drug_count =
        Repo.aggregate(
          from(d in DrugAllocation,
            where:
              d.payment_type == "Insurance" and d.insurance_name == ^insurer_name and
                d.patient_id in ^patient_ids
          )
          |> with_insurance_date_range(:drug_allocation, filters),
          :count
        )

      nurse_count =
        Repo.aggregate(
          from(n in NurseProcedure,
            where:
              n.payment_type == "Insurance" and n.insurance_name == ^insurer_name and
                n.patient_id in ^patient_ids
          )
          |> with_insurance_date_range(:nurse_procedure, filters),
          :count
        )

      doctor_count =
        Repo.aggregate(
          from(d in DoctorProcedure,
            where:
              d.payment_type == "Insurance" and d.insurance_name == ^insurer_name and
                d.patient_id in ^patient_ids
          )
          |> with_insurance_date_range(:doctor_procedure, filters),
          :count
        )

      lab_count =
        Repo.aggregate(
          from(l in LabResult,
            where:
              l.payment_type == "Insurance" and l.insurance_name == ^insurer_name and
                l.patient_id in ^patient_ids
          )
          |> with_insurance_date_range(:lab_result, filters),
          :count
        )

      visit_amount =
        Repo.one(
          from(v in PatientVisit,
            where:
              v.payment_type == "Insurance" and v.insurance_name == ^insurer_name and
                v.patient_id in ^patient_ids,
            select: coalesce(sum(v.total_amount_paid), 0)
          )
          |> with_insurance_date_range(:patient_visit, filters)
        ) || 0

      drug_amount =
        Repo.one(
          from(d in DrugAllocation,
            where:
              d.payment_type == "Insurance" and d.insurance_name == ^insurer_name and
                d.patient_id in ^patient_ids,
            select: coalesce(sum(d.total_amount_paid), 0)
          )
          |> with_insurance_date_range(:drug_allocation, filters)
        ) || 0

      nurse_amount =
        Repo.one(
          from(n in NurseProcedure,
            where:
              n.payment_type == "Insurance" and n.insurance_name == ^insurer_name and
                n.patient_id in ^patient_ids,
            select: coalesce(sum(n.total_amount_paid), 0)
          )
          |> with_insurance_date_range(:nurse_procedure, filters)
        ) || 0

      doctor_amount =
        Repo.one(
          from(d in DoctorProcedure,
            where:
              d.payment_type == "Insurance" and d.insurance_name == ^insurer_name and
                d.patient_id in ^patient_ids,
            select: coalesce(sum(d.total_amount_paid), 0)
          )
          |> with_insurance_date_range(:doctor_procedure, filters)
        ) || 0

      lab_amount =
        Repo.one(
          from(l in LabResult,
            where:
              l.payment_type == "Insurance" and l.insurance_name == ^insurer_name and
                l.patient_id in ^patient_ids,
            select: coalesce(sum(l.total_amount_paid), 0)
          )
          |> with_insurance_date_range(:lab_result, filters)
        ) || 0

      %{
        total_records: visit_count + drug_count + nurse_count + doctor_count + lab_count,
        total_amount: visit_amount + drug_amount + nurse_amount + doctor_amount + lab_amount,
        patient_count: length(patient_ids)
      }
    end
  end

  defp insurer_patient_ids(insurer_name, opts) do
    insurer_name
    |> list_patients_for_insurer(opts)
    |> Enum.map(& &1.id)
  end

  defp insurance_patient_ids(opts) do
    filters = insurance_date_filters(opts)

    []
    |> Kernel.++(
      Repo.all(
        from(v in PatientVisit, where: v.payment_type == "Insurance", select: v.patient_id)
        |> with_insurance_date_range(:patient_visit, filters)
      )
    )
    |> Kernel.++(
      Repo.all(
        from(d in DrugAllocation, where: d.payment_type == "Insurance", select: d.patient_id)
        |> with_insurance_date_range(:drug_allocation, filters)
      )
    )
    |> Kernel.++(
      Repo.all(
        from(n in NurseProcedure, where: n.payment_type == "Insurance", select: n.patient_id)
        |> with_insurance_date_range(:nurse_procedure, filters)
      )
    )
    |> Kernel.++(
      Repo.all(
        from(d in DoctorProcedure, where: d.payment_type == "Insurance", select: d.patient_id)
        |> with_insurance_date_range(:doctor_procedure, filters)
      )
    )
    |> Kernel.++(
      Repo.all(
        from(l in LabResult, where: l.payment_type == "Insurance", select: l.patient_id)
        |> with_insurance_date_range(:lab_result, filters)
      )
    )
    |> Enum.uniq()
    |> Enum.reject(&is_nil/1)
  end

  @doc """
  Returns record count and total amount paid for a specific patient under a specific insurer.
  """
  def patient_insurer_stats(patient_id, insurer_name) do
    visit_count =
      Repo.aggregate(
        from(v in PatientVisit,
          where:
            v.payment_type == "Insurance" and v.patient_id == ^patient_id and
              v.insurance_name == ^insurer_name
        )
        |> exclude_removed_invoice_items(),
        :count
      )

    drug_count =
      Repo.aggregate(
        from(d in DrugAllocation,
          where:
            d.payment_type == "Insurance" and d.patient_id == ^patient_id and
              d.insurance_name == ^insurer_name
        )
        |> exclude_removed_invoice_items(),
        :count
      )

    nurse_count =
      Repo.aggregate(
        from(n in NurseProcedure,
          where:
            n.payment_type == "Insurance" and n.patient_id == ^patient_id and
              n.insurance_name == ^insurer_name
        )
        |> exclude_removed_invoice_items(),
        :count
      )

    doctor_count =
      Repo.aggregate(
        from(d in DoctorProcedure,
          where:
            d.payment_type == "Insurance" and d.patient_id == ^patient_id and
              d.insurance_name == ^insurer_name
        )
        |> exclude_removed_invoice_items(),
        :count
      )

    lab_count =
      Repo.aggregate(
        from(l in LabResult,
          where:
            l.payment_type == "Insurance" and l.patient_id == ^patient_id and
              l.insurance_name == ^insurer_name
        )
        |> exclude_removed_invoice_items(),
        :count
      )

    visit_amount =
      Repo.one(
        from(v in PatientVisit,
          where:
            v.payment_type == "Insurance" and v.patient_id == ^patient_id and
              v.insurance_name == ^insurer_name,
          select: coalesce(sum(v.total_amount_paid), 0)
        )
        |> exclude_removed_invoice_items()
      ) || 0

    drug_amount =
      Repo.one(
        from(d in DrugAllocation,
          where:
            d.payment_type == "Insurance" and d.patient_id == ^patient_id and
              d.insurance_name == ^insurer_name,
          select: coalesce(sum(d.total_amount_paid), 0)
        )
        |> exclude_removed_invoice_items()
      ) || 0

    nurse_amount =
      Repo.one(
        from(n in NurseProcedure,
          where:
            n.payment_type == "Insurance" and n.patient_id == ^patient_id and
              n.insurance_name == ^insurer_name,
          select: coalesce(sum(n.total_amount_paid), 0)
        )
        |> exclude_removed_invoice_items()
      ) || 0

    doctor_amount =
      Repo.one(
        from(d in DoctorProcedure,
          where:
            d.payment_type == "Insurance" and d.patient_id == ^patient_id and
              d.insurance_name == ^insurer_name,
          select: coalesce(sum(d.total_amount_paid), 0)
        )
        |> exclude_removed_invoice_items()
      ) || 0

    lab_amount =
      Repo.one(
        from(l in LabResult,
          where:
            l.payment_type == "Insurance" and l.patient_id == ^patient_id and
              l.insurance_name == ^insurer_name,
          select: coalesce(sum(l.total_amount_paid), 0)
        )
        |> exclude_removed_invoice_items()
      ) || 0

    %{
      total_records: visit_count + drug_count + nurse_count + doctor_count + lab_count,
      total_amount: visit_amount + drug_amount + nurse_amount + doctor_amount + lab_amount
    }
  end

  @doc """
  Returns a summary map for a patient: total insurance records count and
  unique insurer names they have been billed under.
  """
  def patient_insurance_summary(patient_id, opts \\ %{}) do
    filters = insurance_date_filters(opts)

    visit_count =
      Repo.aggregate(
        from(v in PatientVisit,
          where: v.payment_type == "Insurance" and v.patient_id == ^patient_id
        )
        |> with_insurance_date_range(:patient_visit, filters),
        :count
      )

    drug_count =
      Repo.aggregate(
        from(d in DrugAllocation,
          where: d.payment_type == "Insurance" and d.patient_id == ^patient_id
        )
        |> with_insurance_date_range(:drug_allocation, filters),
        :count
      )

    nurse_count =
      Repo.aggregate(
        from(n in NurseProcedure,
          where: n.payment_type == "Insurance" and n.patient_id == ^patient_id
        )
        |> with_insurance_date_range(:nurse_procedure, filters),
        :count
      )

    doctor_count =
      Repo.aggregate(
        from(d in DoctorProcedure,
          where: d.payment_type == "Insurance" and d.patient_id == ^patient_id
        )
        |> with_insurance_date_range(:doctor_procedure, filters),
        :count
      )

    lab_count =
      Repo.aggregate(
        from(l in LabResult, where: l.payment_type == "Insurance" and l.patient_id == ^patient_id)
        |> with_insurance_date_range(:lab_result, filters),
        :count
      )

    visit_insurers =
      Repo.all(
        from(v in PatientVisit,
          where:
            v.payment_type == "Insurance" and v.patient_id == ^patient_id and
              not is_nil(v.insurance_name),
          select: v.insurance_name
        )
        |> with_insurance_date_range(:patient_visit, filters)
      )

    drug_insurers =
      Repo.all(
        from(d in DrugAllocation,
          where:
            d.payment_type == "Insurance" and d.patient_id == ^patient_id and
              not is_nil(d.insurance_name),
          select: d.insurance_name
        )
        |> with_insurance_date_range(:drug_allocation, filters)
      )

    nurse_insurers =
      Repo.all(
        from(n in NurseProcedure,
          where:
            n.payment_type == "Insurance" and n.patient_id == ^patient_id and
              not is_nil(n.insurance_name),
          select: n.insurance_name
        )
        |> with_insurance_date_range(:nurse_procedure, filters)
      )

    doctor_insurers =
      Repo.all(
        from(d in DoctorProcedure,
          where:
            d.payment_type == "Insurance" and d.patient_id == ^patient_id and
              not is_nil(d.insurance_name),
          select: d.insurance_name
        )
        |> with_insurance_date_range(:doctor_procedure, filters)
      )

    lab_insurers =
      Repo.all(
        from(l in LabResult,
          where:
            l.payment_type == "Insurance" and l.patient_id == ^patient_id and
              not is_nil(l.insurance_name),
          select: l.insurance_name
        )
        |> with_insurance_date_range(:lab_result, filters)
      )

    unique_insurers =
      (visit_insurers ++ drug_insurers ++ nurse_insurers ++ doctor_insurers ++ lab_insurers)
      |> Enum.uniq()
      |> Enum.reject(&is_nil/1)

    visit_amount =
      Repo.one(
        from(v in PatientVisit,
          where: v.payment_type == "Insurance" and v.patient_id == ^patient_id,
          select: coalesce(sum(v.total_amount_paid), 0)
        )
        |> with_insurance_date_range(:patient_visit, filters)
      ) || 0

    drug_amount =
      Repo.one(
        from(d in DrugAllocation,
          where: d.payment_type == "Insurance" and d.patient_id == ^patient_id,
          select: coalesce(sum(d.total_amount_paid), 0)
        )
        |> with_insurance_date_range(:drug_allocation, filters)
      ) || 0

    nurse_amount =
      Repo.one(
        from(n in NurseProcedure,
          where: n.payment_type == "Insurance" and n.patient_id == ^patient_id,
          select: coalesce(sum(n.total_amount_paid), 0)
        )
        |> with_insurance_date_range(:nurse_procedure, filters)
      ) || 0

    doctor_amount =
      Repo.one(
        from(d in DoctorProcedure,
          where: d.payment_type == "Insurance" and d.patient_id == ^patient_id,
          select: coalesce(sum(d.total_amount_paid), 0)
        )
        |> with_insurance_date_range(:doctor_procedure, filters)
      ) || 0

    lab_amount =
      Repo.one(
        from(l in LabResult,
          where: l.payment_type == "Insurance" and l.patient_id == ^patient_id,
          select: coalesce(sum(l.total_amount_paid), 0)
        )
        |> with_insurance_date_range(:lab_result, filters)
      ) || 0

    %{
      total_records: visit_count + drug_count + nurse_count + doctor_count + lab_count,
      total_amount: visit_amount + drug_amount + nurse_amount + doctor_amount + lab_amount,
      unique_insurers: unique_insurers
    }
  end

  @doc """
  Returns full claim data for a patient, grouped by insurer and filtered with the
  same options as the insurance dashboard.
  """
  def get_patient_claim_data(patient_id, opts \\ %{}) do
    patient_id
    |> patient_insurance_summary(opts)
    |> Map.get(:unique_insurers, [])
    |> Enum.map(fn insurer_name ->
      records = get_insurance_records_for_patient_and_insurer(patient_id, insurer_name, opts)

      %{
        insurer_name: insurer_name,
        records: records,
        total_amount: Enum.reduce(records, 0, fn record, acc -> acc + (record.amount || 0) end)
      }
    end)
    |> Enum.reject(&Enum.empty?(&1.records))
  end

  @doc """
  Returns full claim data for an insurer: a list of patient maps each containing
  their itemized records (filtered to this insurer only) and their subtotal.
  Suitable for generating an invoice or claim statement.
  """
  def get_insurer_claim_data(insurer_name, opts \\ %{}) do
    patients = list_patients_for_insurer(insurer_name, opts)

    Enum.map(patients, fn patient ->
      records = get_insurance_records_for_patient_and_insurer(patient.id, insurer_name, opts)
      total = Enum.reduce(records, 0, fn r, acc -> acc + (r.amount || 0) end)

      %{
        patient: patient,
        records: records,
        total_amount: total
      }
    end)
  end

  defp get_insurance_records_for_patient_and_insurer(patient_id, insurer_name, opts) do
    filters = insurance_date_filters(opts)

    visits =
      from(v in PatientVisit,
        where:
          v.payment_type == "Insurance" and v.patient_id == ^patient_id and
            v.insurance_name == ^insurer_name,
        order_by: [asc: v.inserted_at]
      )
      |> with_insurance_date_range(:patient_visit, filters)
      |> Repo.all()
      |> Enum.map(fn v ->
        %{
          id: v.id,
          type: :visit,
          label: "Consultancy",
          date: v.date || to_nairobi_date(v.inserted_at),
          description: v.reason || "General Visit",
          amount: v.total_amount_paid || 0,
          has_paid: v.has_paid,
          inserted_at: v.inserted_at
        }
      end)

    drugs =
      from(d in DrugAllocation,
        where:
          d.payment_type == "Insurance" and d.patient_id == ^patient_id and
            d.insurance_name == ^insurer_name,
        preload: [drugs_given: :drug],
        order_by: [asc: d.inserted_at]
      )
      |> with_insurance_date_range(:drug_allocation, filters)
      |> Repo.all()
      |> Enum.map(fn d ->
        drug_names =
          d.drugs_given
          |> Enum.map(fn dg -> dg.drug && (dg.drug.brand_name || dg.drug.generic_name) end)
          |> Enum.reject(&is_nil/1)
          |> Enum.join(", ")

        %{
          id: d.id,
          type: :drug,
          label: "Pharmacy",
          date: to_nairobi_date(d.inserted_at),
          description:
            if(drug_names != "", do: drug_names, else: d.prescription || "Drug Allocation"),
          amount: d.total_amount_paid || 0,
          has_paid: d.has_paid,
          inserted_at: d.inserted_at
        }
      end)

    nurse_procs =
      from(n in NurseProcedure,
        where:
          n.payment_type == "Insurance" and n.patient_id == ^patient_id and
            n.insurance_name == ^insurer_name,
        preload: [:procedure, :subsidized_procedure],
        order_by: [asc: n.inserted_at]
      )
      |> with_insurance_date_range(:nurse_procedure, filters)
      |> Repo.all()
      |> Enum.map(fn n ->
        proc_name =
          (n.procedure && n.procedure.name) ||
            (n.subsidized_procedure && n.subsidized_procedure.name) ||
            "Nurse Procedure"

        %{
          id: n.id,
          type: :nurse_procedure,
          label: "Nursing",
          date: to_nairobi_date(n.inserted_at),
          description: proc_name,
          amount: n.total_amount_paid || 0,
          has_paid: n.has_paid,
          inserted_at: n.inserted_at
        }
      end)

    doctor_procs =
      from(d in DoctorProcedure,
        where:
          d.payment_type == "Insurance" and d.patient_id == ^patient_id and
            d.insurance_name == ^insurer_name,
        preload: [:procedure, :subsidized_procedure],
        order_by: [asc: d.inserted_at]
      )
      |> with_insurance_date_range(:doctor_procedure, filters)
      |> Repo.all()
      |> Enum.map(fn d ->
        proc_name =
          (d.procedure && d.procedure.name) ||
            (d.subsidized_procedure && d.subsidized_procedure.name) ||
            "Doctor Procedure"

        %{
          id: d.id,
          type: :doctor_procedure,
          label: "Doctor Procedure",
          date: to_nairobi_date(d.inserted_at),
          description: proc_name,
          amount: d.total_amount_paid || 0,
          has_paid: d.has_paid,
          inserted_at: d.inserted_at
        }
      end)

    lab_results =
      from(l in LabResult,
        where:
          l.payment_type == "Insurance" and l.patient_id == ^patient_id and
            l.insurance_name == ^insurer_name,
        order_by: [asc: l.inserted_at]
      )
      |> with_insurance_date_range(:lab_result, filters)
      |> Repo.all()
      |> Enum.map(fn l ->
        test_names =
          l.tests
          |> Enum.map(& &1.name)
          |> Enum.reject(&is_nil/1)
          |> Enum.join(", ")

        description =
          if test_names != "", do: test_names, else: l.name || l.description || "Lab Test"

        %{
          id: l.id,
          type: :lab,
          label: "Lab Test",
          date: l.date_of_test || to_nairobi_date(l.inserted_at),
          description: description,
          amount: l.total_amount_paid || 0,
          has_paid: l.has_paid,
          inserted_at: l.inserted_at
        }
      end)

    (visits ++ drugs ++ nurse_procs ++ doctor_procs ++ lab_results)
    |> Enum.sort_by(& &1.inserted_at, {:asc, DateTime})
  end

  @doc """
  Returns all insurance-tagged records for a specific patient across all record types.
  Result is a list of {date, records} tuples sorted descending by date.
  Each record has: type, label, date, insurance_name, amount, description, has_paid, inserted_at.
  """
  def get_insurance_records_for_patient(patient_id) do
    visits =
      from(v in PatientVisit,
        where: v.payment_type == "Insurance" and v.patient_id == ^patient_id,
        order_by: [desc: v.inserted_at]
      )
      |> exclude_removed_invoice_items()
      |> Repo.all()
      |> Enum.map(fn v ->
        %{
          type: :visit,
          label: "Patient Visit",
          date: v.date || to_nairobi_date(v.inserted_at),
          insurance_name: v.insurance_name,
          amount: v.total_amount_paid,
          description: v.reason || "General Visit",
          has_paid: v.has_paid,
          inserted_at: v.inserted_at
        }
      end)

    drugs =
      from(d in DrugAllocation,
        where: d.payment_type == "Insurance" and d.patient_id == ^patient_id,
        preload: [:drugs_given],
        order_by: [desc: d.inserted_at]
      )
      |> exclude_removed_invoice_items()
      |> Repo.all()
      |> Enum.map(fn d ->
        drug_names =
          Enum.map(d.drugs_assigned || [], & &1.brand_name)
          |> Enum.reject(&is_nil/1)
          |> Enum.join(", ")

        description =
          if drug_names != "", do: drug_names, else: d.prescription || "Drug Allocation"

        %{
          type: :drug,
          label: "Pharmacy",
          date: to_nairobi_date(d.inserted_at),
          insurance_name: d.insurance_name,
          amount: d.total_amount_paid,
          description: description,
          has_paid: d.has_paid,
          inserted_at: d.inserted_at
        }
      end)

    nurse_procs =
      from(n in NurseProcedure,
        where: n.payment_type == "Insurance" and n.patient_id == ^patient_id,
        preload: [:procedure, :subsidized_procedure],
        order_by: [desc: n.inserted_at]
      )
      |> exclude_removed_invoice_items()
      |> Repo.all()
      |> Enum.map(fn n ->
        proc_name =
          (n.procedure && n.procedure.name) ||
            (n.subsidized_procedure && n.subsidized_procedure.name) ||
            "Procedure"

        %{
          type: :nurse_procedure,
          label: "Nurse Procedure",
          date: to_nairobi_date(n.inserted_at),
          insurance_name: n.insurance_name,
          amount: n.total_amount_paid,
          description: proc_name,
          has_paid: n.has_paid,
          inserted_at: n.inserted_at
        }
      end)

    doctor_procs =
      from(d in DoctorProcedure,
        where: d.payment_type == "Insurance" and d.patient_id == ^patient_id,
        preload: [:procedure, :subsidized_procedure],
        order_by: [desc: d.inserted_at]
      )
      |> exclude_removed_invoice_items()
      |> Repo.all()
      |> Enum.map(fn d ->
        proc_name =
          (d.procedure && d.procedure.name) ||
            (d.subsidized_procedure && d.subsidized_procedure.name) ||
            "Procedure"

        %{
          type: :doctor_procedure,
          label: "Doctor Procedure",
          date: to_nairobi_date(d.inserted_at),
          insurance_name: d.insurance_name,
          amount: d.total_amount_paid,
          description: proc_name,
          has_paid: d.has_paid,
          inserted_at: d.inserted_at
        }
      end)

    lab_results =
      from(l in LabResult,
        where: l.payment_type == "Insurance" and l.patient_id == ^patient_id,
        order_by: [desc: l.inserted_at]
      )
      |> exclude_removed_invoice_items()
      |> Repo.all()
      |> Enum.map(fn l ->
        test_names =
          l.tests
          |> Enum.map(& &1.name)
          |> Enum.reject(&is_nil/1)
          |> Enum.join(", ")

        description =
          if test_names != "", do: test_names, else: l.name || l.description || "Lab Tests"

        %{
          type: :lab,
          label: "Lab Test",
          date: l.date_of_test || to_nairobi_date(l.inserted_at),
          insurance_name: l.insurance_name,
          amount: l.total_amount_paid,
          description: description,
          has_paid: l.has_paid,
          inserted_at: l.inserted_at
        }
      end)

    (visits ++ drugs ++ nurse_procs ++ doctor_procs ++ lab_results)
    |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
    |> Enum.group_by(& &1.date)
    |> Enum.sort_by(fn {date, _} -> date end, {:desc, Date})
  end

  @doc """
  Excludes a billable insurance record from invoice totals and reports.
  """
  def exclude_record_from_invoice(type, record_id),
    do: update_record_invoice_exclusion(type, record_id, true)

  @doc """
  Excludes every currently included invoice record for the given patient, insurer,
  and record type from insurance totals and reports.
  """
  def exclude_category_from_invoice(patient_id, insurer_name, type, opts \\ %{}) do
    parsed_type =
      case type do
        atom when is_atom(atom) -> atom
        binary when is_binary(binary) -> parse_record_type(binary)
        _ -> nil
      end

    if is_nil(parsed_type) do
      {:error, :unsupported_type}
    else
      patient_id
      |> get_insurance_records_for_patient_and_insurer(insurer_name, opts)
      |> Enum.filter(&(&1.type == parsed_type))
      |> Enum.reduce_while({:ok, 0}, fn record, {:ok, count} ->
        case exclude_record_from_invoice(record.type, record.id) do
          {:ok, _updated_record} -> {:cont, {:ok, count + 1}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end)
    end
  end

  @doc """
  Restores a previously excluded insurance record back into invoice totals and reports.
  """
  def restore_record_to_invoice(type, record_id),
    do: update_record_invoice_exclusion(type, record_id, false)

  defp update_record_invoice_exclusion(type, record_id, excluded?) when is_binary(type) do
    case parse_record_type(type) do
      nil -> {:error, :unsupported_type}
      parsed_type -> update_record_invoice_exclusion(parsed_type, record_id, excluded?)
    end
  end

  defp update_record_invoice_exclusion(type, record_id, excluded?) when is_binary(record_id) do
    case Integer.parse(record_id) do
      {parsed_id, ""} -> update_record_invoice_exclusion(type, parsed_id, excluded?)
      _ -> {:error, :invalid_id}
    end
  end

  defp update_record_invoice_exclusion(:visit, record_id, excluded?) do
    record = Repo.get!(PatientVisit, record_id)

    Medcamp.PatientVisits.update_patient_visit(record, %{excluded_from_insurance_invoice: excluded?})
  end

  defp update_record_invoice_exclusion(:drug, record_id, excluded?) do
    record = Repo.get!(DrugAllocation, record_id)

    Medcamp.DrugAllocations.update_drug_allocation(record, %{
      excluded_from_insurance_invoice: excluded?
    })
  end

  defp update_record_invoice_exclusion(:nurse_procedure, record_id, excluded?) do
    record = Repo.get!(NurseProcedure, record_id)

    Medcamp.NurseProcedures.update_nurse_procedure(record, %{
      excluded_from_insurance_invoice: excluded?
    })
  end

  defp update_record_invoice_exclusion(:doctor_procedure, record_id, excluded?) do
    record = Repo.get!(DoctorProcedure, record_id)

    Medcamp.DoctorProcedures.update_doctor_procedure(record, %{
      excluded_from_insurance_invoice: excluded?
    })
  end

  defp update_record_invoice_exclusion(:lab, record_id, excluded?) do
    record = Repo.get!(LabResult, record_id)
    Medcamp.LabResults.update_lab_result(record, %{excluded_from_insurance_invoice: excluded?})
  end

  defp update_record_invoice_exclusion(_type, _record_id, _excluded?),
    do: {:error, :unsupported_type}

  defp parse_record_type("visit"), do: :visit
  defp parse_record_type("drug"), do: :drug
  defp parse_record_type("nurse_procedure"), do: :nurse_procedure
  defp parse_record_type("doctor_procedure"), do: :doctor_procedure
  defp parse_record_type("lab"), do: :lab
  defp parse_record_type(_), do: nil

  defp to_nairobi_date(datetime) do
    datetime
    |> DateTime.shift_zone!("Africa/Nairobi")
    |> DateTime.to_date()
  end
end
