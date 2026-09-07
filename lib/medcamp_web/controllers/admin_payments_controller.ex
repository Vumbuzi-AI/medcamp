defmodule MedcampWeb.AdminPaymentsController do
  use MedcampWeb, :controller
  alias Medcamp.Mpesas

  def export(conn, _params) do
    payments = Mpesas.list_successful_payments()
    csv = build_payments_csv(payments)

    conn
    |> put_resp_content_type("text/csv")
    |> put_resp_header(
      "content-disposition",
      "attachment; filename=\"payments-#{Date.utc_today()}.csv\""
    )
    |> send_resp(200, csv)
  end

  defp build_payments_csv(payments) do
    headers = ["Patient", "Amount (KES)", "Phone Number", "Reason", "Prompter", "Date"]

    rows =
      Enum.map(payments, fn p ->
        patient_name =
          [p.patient.first_name, p.patient.middle_name, p.patient.last_name]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")

        date_str =
          p.inserted_at
          |> DateTime.shift_zone!("Africa/Nairobi")
          |> Timex.format!("{YYYY}-{0M}-{0D} {h24}:{m}:{s}")

        [
          patient_name,
          to_string(p.amount),
          p.account_number || "",
          p.actionable_label || p.actionable_type || "",
          p.prompter.name || "",
          date_str
        ]
      end)

    [headers | rows]
    |> Enum.map(fn row -> Enum.map_join(row, ",", fn cell -> csv_escape(cell) end) end)
    |> Enum.join("\n")
  end

  defp csv_escape(value) when is_binary(value) do
    if String.contains?(value, [",", "\"", "\n", "\r"]) do
      "\"" <> String.replace(value, "\"", "\"\"") <> "\""
    else
      value
    end
  end

  defp csv_escape(value), do: value |> to_string() |> csv_escape()
end
