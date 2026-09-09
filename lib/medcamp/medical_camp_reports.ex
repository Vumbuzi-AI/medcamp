defmodule Medcamp.MedicalCampReports do
  @moduledoc """
  Aggregates billable medical camp activity into a report-friendly structure.
  """

  import Ecto.Query, warn: false

  alias Medcamp.Camps
  alias Medcamp.Patients
  alias Medcamp.Repo

  alias Medcamp.LabResults.LabResult

  def report do
    camp = Camps.get_active_camp()

    patients =
      case camp do
        nil ->
          Patients.list_all_medical_camp_patients()
          |> Enum.filter(&medical_camp_patient?/1)

        camp ->
          Patients.list_patients_for_camp(camp.id)
      end

    patient_map = Map.new(patients, &{&1.id, &1})
    patient_ids = Map.keys(patient_map)

    records = build_records(patient_ids, patient_map)
    total_amount = Enum.sum(Enum.map(records, &(&1.amount || 0)))

    paid_amount =
      records |> Enum.filter(& &1.has_paid) |> Enum.map(&(&1.amount || 0)) |> Enum.sum()

    pending_amount = max(total_amount - paid_amount, 0)

    %{
      generated_at: DateTime.utc_now(),
      cohort_name: "Medical Camp",
      medical_camp_name: camp && camp.name,
      patient_type: nil,
      insurer_name: insurer_name(records),
      payer_names:
        records
        |> Enum.map(& &1.cover_name)
        |> Enum.reject(&blank?/1)
        |> Enum.uniq()
        |> Enum.sort(),
      total_amount: total_amount,
      paid_amount: paid_amount,
      pending_amount: pending_amount,
      total_records: length(records),
      patient_count: length(patients),
      unique_days: records |> Enum.map(& &1.date) |> Enum.uniq() |> length(),
      insurer_summary: build_insurer_summary(length(records), total_amount, length(patients)),
      category_totals: build_category_totals(records),
      claim_data: build_claim_data(records, patient_map),
      patient_rows: build_patient_rows(records, patient_map),
      type_rows: build_type_rows(records),
      grouped_records: build_grouped_records(records)
    }
  end

  defp build_records([], _patient_map), do: []

  defp build_records(patient_ids, patient_map) do
    lab_results(patient_ids, patient_map)
    |> Enum.filter(&medical_camp_record?/1)
    |> Enum.sort_by(
      fn record ->
        {
          Date.to_gregorian_days(record.date),
          DateTime.to_unix(record.inserted_at, :microsecond)
        }
      end,
      :desc
    )
  end

  defp lab_results(patient_ids, patient_map) do
    from(l in LabResult,
      where: l.patient_id in ^patient_ids,
      order_by: [desc: l.inserted_at]
    )
    |> Repo.all()
    |> Enum.map(fn result ->
      description =
        result.tests
        |> Enum.map(& &1.name)
        |> Enum.reject(&blank?/1)
        |> Enum.join(", ")
        |> case do
          "" -> result.name || result.description || "Lab Test"
          names -> names
        end

      build_record(
        patient_map[result.patient_id],
        :lab,
        "Lab Test",
        description,
        result.total_amount_paid,
        result.has_paid,
        result.payment_type,
        result.insurance_name,
        result.date_of_test || to_nairobi_date(result.inserted_at),
        result.inserted_at
      )
    end)
  end

  defp build_record(
         patient,
         type,
         label,
         description,
         amount,
         has_paid,
         payment_type,
         cover_name,
         date,
         inserted_at
       ) do
    %{
      patient: patient,
      type: type,
      label: label,
      description: description,
      amount: amount || 0,
      has_paid: has_paid == true,
      payment_type: payment_type,
      cover_name: cover_name,
      date: date,
      inserted_at: inserted_at
    }
  end

  defp build_patient_rows(records, patient_map) do
    records
    |> Enum.group_by(& &1.patient.id)
    |> Enum.map(fn {patient_id, patient_records} ->
      total_amount = Enum.sum(Enum.map(patient_records, & &1.amount))

      paid_amount =
        patient_records |> Enum.filter(& &1.has_paid) |> Enum.map(& &1.amount) |> Enum.sum()

      %{
        patient: patient_map[patient_id],
        total_records: length(patient_records),
        total_amount: total_amount,
        paid_amount: paid_amount,
        pending_amount: max(total_amount - paid_amount, 0)
      }
    end)
    |> Enum.sort_by(& &1.total_amount, :desc)
  end

  defp build_claim_data(records, patient_map) do
    records
    |> Enum.group_by(& &1.patient.id)
    |> Enum.map(fn {patient_id, patient_records} ->
      %{
        patient: patient_map[patient_id],
        records: Enum.sort_by(patient_records, & &1.inserted_at, {:asc, DateTime}),
        total_amount: Enum.sum(Enum.map(patient_records, & &1.amount))
      }
    end)
    |> Enum.sort_by(& &1.total_amount, :desc)
  end

  defp build_type_rows(records) do
    records
    |> Enum.group_by(& &1.label)
    |> Enum.map(fn {label, items} ->
      %{
        label: label,
        total_records: length(items),
        total_amount: Enum.sum(Enum.map(items, & &1.amount))
      }
    end)
    |> Enum.sort_by(& &1.total_amount, :desc)
  end

  defp build_category_totals(records) do
    [{"Lab Tests", :lab, "bg-amber-50 text-amber-700 ring-amber-200"}]
    |> Enum.map(fn {label, type, badge_class} ->
      category_records = Enum.filter(records, &(&1.type == type))

      %{
        label: label,
        type: type,
        badge_class: badge_class,
        total_records: length(category_records),
        total_amount: Enum.sum(Enum.map(category_records, & &1.amount))
      }
    end)
  end

  defp build_insurer_summary(total_records, total_amount, patient_count) do
    %{
      total_records: total_records,
      total_amount: total_amount,
      patient_count: patient_count
    }
  end

  defp build_grouped_records(records) do
    records
    |> Enum.group_by(& &1.date)
    |> Enum.sort_by(fn {date, _items} -> date end, {:desc, Date})
  end

  defp to_nairobi_date(datetime) do
    datetime
    |> DateTime.shift_zone!("Africa/Nairobi")
    |> DateTime.to_date()
  end

  defp insurer_name(records) do
    records
    |> Enum.map(& &1.cover_name)
    |> Enum.reject(&blank?/1)
    |> Enum.uniq()
    |> case do
      [] -> "Human Development Fund ( HDF )"
      [name | _] -> name
    end
  end

  defp blank?(value), do: value in [nil, ""]

  defp medical_camp_patient?(%{is_for_medical_camp: true}), do: true
  defp medical_camp_patient?(_patient), do: false

  defp medical_camp_record?(%{patient: patient}) when not is_nil(patient) do
    medical_camp_patient?(patient)
  end

  defp medical_camp_record?(_record), do: false
end
