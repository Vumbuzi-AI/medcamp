defmodule MedcampWeb.MedicalCampExportController do
  use MedcampWeb, :controller

  alias Medcamp.Patients
  alias Medcamp.DoctorNotes
  alias Medcamp.Triages

  @day1 ~D[2026-03-28]
  @day2 ~D[2026-03-29]

  # GET /admin/medical_camp/export/summary?day=all|day1|day2
  def summary(conn, params) do
    patients = load_patients(params["day"])
    stats = Patients.compute_camp_stats_for_patients(patients)

    rows =
      [
        ["Metric", "Value"],
        ["Total Patients Served", stats.total],
        ["Male", stats.male],
        ["Female", stats.female],
        ["Unspecified Gender", max(stats.total - stats.male - stats.female, 0)],
        ["Under 5 yrs", stats.age_groups.under_5],
        ["5 – 17 yrs", stats.age_groups.age_5_17],
        ["18 – 59 yrs", stats.age_groups.age_18_59],
        ["60+ yrs", stats.age_groups.over_60]
      ] ++
        Enum.map(stats.patient_types, fn {type, count} -> ["Patient Type: #{type}", count] end)

    send_csv(conn, rows, "medical_camp_summary_#{day_label(params["day"])}.csv")
  end

  # GET /admin/medical_camp/export/patients?day=all|day1|day2
  def patients(conn, params) do
    patients = load_patients(params["day"])
    patient_ids = Enum.map(patients, & &1.id)

    doctor_notes = DoctorNotes.list_doctor_notes_for_patients(patient_ids)
    triages = Triages.list_most_recent_triages_for_patients(patient_ids)

    # Build lookup maps
    primary_diagnosis =
      doctor_notes
      |> Enum.group_by(& &1.patient_id)
      |> Map.new(fn {patient_id, notes} ->
        diagnosis =
          notes
          |> Enum.find_value(fn note ->
            [note.diagnosis, note.impression, note.reason_for_consulatation]
            |> Enum.find_value(&normalize_text/1)
          end)

        {patient_id, diagnosis || "—"}
      end)

    triaged_ids =
      triages |> Enum.map(& &1.patient_id) |> MapSet.new()

    header = [
      "#",
      "Full Name",
      "GSRN",
      "National ID",
      "Gender",
      "Age",
      "Age Group",
      "Patient Type",
      "Home Address",
      "Phone",
      "Has Insurance",
      "Insurance Scheme",
      "Triaged",
      "Primary Diagnosis",
      "Registered At"
    ]

    data_rows =
      patients
      |> Enum.with_index(1)
      |> Enum.map(fn {p, i} ->
        [
          i,
          full_name(p),
          p.gsrn || "—",
          p.national_id || "—",
          p.gender || "—",
          p.age || "—",
          age_group_label(p.age),
          p.patient_type || "—",
          p.home_address || "—",
          p.phone_number || "—",
          if(p.has_insurance, do: "Yes", else: "No"),
          p.insurance_scheme || "—",
          if(MapSet.member?(triaged_ids, p.id), do: "Yes", else: "No"),
          Map.get(primary_diagnosis, p.id, "—"),
          format_datetime(p.inserted_at)
        ]
      end)

    send_csv(conn, [header | data_rows], "medical_camp_patients_#{day_label(params["day"])}.csv")
  end

  # GET /admin/medical_camp/export/geography?day=all|day1|day2
  def geography(conn, params) do
    patients = load_patients(params["day"])

    rows =
      patients
      |> Enum.group_by(fn p -> normalize_address(p.home_address) end)
      |> Enum.map(fn {address, pts} -> {address, length(pts)} end)
      |> Enum.sort_by(fn {_, count} -> count end, :desc)

    total = length(patients)

    header = ["Location / Address", "Patient Count", "% of Total"]

    data_rows =
      Enum.map(rows, fn {address, count} ->
        pct = if total > 0, do: Float.round(count / total * 100, 1), else: 0.0
        [address, count, "#{pct}%"]
      end)

    send_csv(
      conn,
      [header | data_rows],
      "medical_camp_geography_#{day_label(params["day"])}.csv"
    )
  end

  # GET /admin/medical_camp/export/diagnoses?day=all|day1|day2
  def diagnoses(conn, params) do
    patients = load_patients(params["day"])
    patient_ids = Enum.map(patients, & &1.id)
    doctor_notes = DoctorNotes.list_doctor_notes_for_patients(patient_ids)

    # Patient lookup for gender breakdown per diagnosis
    patient_lookup = Map.new(patients, fn p -> {p.id, p} end)

    rows =
      doctor_notes
      |> Enum.map(fn note ->
        label =
          [note.diagnosis, note.impression, note.reason_for_consulatation]
          |> Enum.find_value(&normalize_text/1)

        patient = Map.get(patient_lookup, note.patient_id)
        gender = (patient && patient.gender) || "Unspecified"
        {label, gender}
      end)
      |> Enum.reject(fn {label, _} -> is_nil(label) end)
      |> Enum.group_by(fn {label, _} -> label end)
      |> Enum.map(fn {label, entries} ->
        total = length(entries)
        male = Enum.count(entries, fn {_, g} -> g == "Male" end)
        female = Enum.count(entries, fn {_, g} -> g == "Female" end)
        other = total - male - female
        {label, total, male, female, other}
      end)
      |> Enum.sort_by(fn {_, total, _, _, _} -> total end, :desc)

    header = ["Diagnosis / Impression", "Total Cases", "Male", "Female", "Unspecified"]

    data_rows =
      Enum.map(rows, fn {label, total, male, female, other} ->
        [label, total, male, female, other]
      end)

    send_csv(
      conn,
      [header | data_rows],
      "medical_camp_diagnoses_#{day_label(params["day"])}.csv"
    )
  end

  # ---- Private helpers ----

  defp load_patients("day1"), do: Patients.list_medical_camp_patients(@day1)
  defp load_patients("day2"), do: Patients.list_medical_camp_patients(@day2)
  defp load_patients(_), do: Patients.list_medical_camp_patients_for_dates([@day1, @day2])

  defp send_csv(conn, rows, filename) do
    csv_content = rows |> Enum.map(&encode_row/1) |> Enum.join("\r\n")

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header("content-disposition", ~s(attachment; filename="#{filename}"))
    |> send_resp(200, csv_content)
  end

  defp encode_row(cells) do
    cells
    |> Enum.map(fn cell ->
      value = to_string(cell)

      if String.contains?(value, [",", "\"", "\n", "\r"]) do
        ~s("#{String.replace(value, "\"", "\"\"")}")
      else
        value
      end
    end)
    |> Enum.join(",")
  end

  defp full_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
  end

  defp age_group_label(nil), do: "Unknown"
  defp age_group_label(age) when age < 5, do: "Under 5"
  defp age_group_label(age) when age < 18, do: "5 – 17"
  defp age_group_label(age) when age < 60, do: "18 – 59"
  defp age_group_label(_age), do: "60+"

  defp normalize_address(nil), do: "Not Specified"

  defp normalize_address(addr) do
    addr
    |> String.trim()
    |> case do
      "" -> "Not Specified"
      v -> v
    end
  end

  defp normalize_text(nil), do: nil

  defp normalize_text(value) when is_binary(value) do
    value
    |> String.trim()
    |> case do
      "" ->
        nil

      trimmed ->
        trimmed
        |> String.split(~r/[\n;,]/, parts: 2)
        |> List.first()
        |> String.trim()
        |> truncate(80)
    end
  end

  defp normalize_text(_), do: nil

  defp truncate(value, max) do
    if String.length(value) > max, do: String.slice(value, 0, max - 3) <> "...", else: value
  end

  defp format_datetime(nil), do: "—"

  defp format_datetime(%DateTime{} = dt) do
    dt |> DateTime.add(3 * 3600, :second) |> Calendar.strftime("%Y-%m-%d %H:%M")
  end

  defp format_datetime(%NaiveDateTime{} = dt) do
    dt |> Calendar.strftime("%Y-%m-%d %H:%M")
  end

  defp day_label("day1"), do: "day1"
  defp day_label("day2"), do: "day2"
  defp day_label(_), do: "all_days"
end
