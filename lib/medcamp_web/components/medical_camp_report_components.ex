defmodule MedcampWeb.MedicalCampReportComponents do
  use Phoenix.Component

  use Gettext, backend: MedcampWeb.Gettext

  attr :report, :map, required: true

  def medical_camp_report(assigns) do
    ~H"""
    <style>
      @media print {
        .medical-camp-report-print-hidden { display: none !important; }
        .medical-camp-report-print-shell { background: white !important; box-shadow: none !important; }
        .medical-camp-report-print-card { box-shadow: none !important; break-inside: avoid; }
        body { background: white !important; }
      }
    </style>

    <div class="space-y-0" id="medical-camp-report-sheet">
      <div class="mx-auto max-w-4xl space-y-0 overflow-hidden rounded-xl border border-gray-200 bg-white shadow-sm print:border-0 print:shadow-none">
        <div class="flex items-center justify-between border-b border-gray-200 bg-white px-8 py-4">
          <div class="flex items-center gap-3">
            <img src="/images/logo.png" alt="GHCE Logo" class="h-12 w-auto" />
            <div>
              <p class="font-medium text-gray-900">Glocal Health Centre of Excellence</p>
              <p class="text-xs uppercase tracking-wide text-gray-500">{@report.cohort_name}</p>
            </div>
          </div>
          <div class="text-right text-xs text-gray-400">
            <p class="text-sm font-semibold text-gray-700">Medical Camp Claim Statement</p>
            <p>Generated: {format_generated_at(@report.generated_at)}</p>
          </div>
        </div>

        <div class="bg-blue-700 px-8 py-6 text-white">
          <div class="flex items-start justify-between gap-4">
            <div>
              <p class="mb-1 text-xs font-medium uppercase tracking-widest text-blue-200">Cohort</p>
              <h2 class="text-2xl font-bold">{@report.insurer_name}</h2>
              <p class="mt-2 text-xs text-blue-200">
                Only patients marked for the medical camp are included.
              </p>
            </div>
            <div class="text-right">
              <p class="text-xs uppercase tracking-wide text-blue-200">Total Claim</p>
              <p class="mt-0.5 text-3xl font-bold tabular-nums">
                KSh {format_currency(@report.insurer_summary.total_amount)}
              </p>
              <p class="mt-1 text-xs text-blue-200">
                {@report.insurer_summary.patient_count} patient{if @report.insurer_summary.patient_count !=
                                                                     1,
                                                                   do: "s",
                                                                   else: ""} · {@report.insurer_summary.total_records} record{if @report.insurer_summary.total_records !=
                                                                                                                                   1,
                                                                                                                                 do:
                                                                                                                                   "s",
                                                                                                                                 else:
                                                                                                                                   ""}
              </p>
            </div>
          </div>
        </div>

        <%= if Enum.empty?(@report.claim_data) do %>
          <div class="flex flex-col items-center justify-center py-16 text-center">
            <Heroicons.icon name="document-text" type="outline" class="h-10 w-10 text-gray-300" />
            <p class="mt-3 text-sm text-gray-500">No records found for this medical camp claim.</p>
          </div>
        <% else %>
          <%= for {entry, idx} <- Enum.with_index(@report.claim_data) do %>
            <div class={[
              "medical-camp-report-print-card px-8 py-6 print:break-inside-avoid",
              if(rem(idx, 2) == 0, do: "bg-white", else: "bg-slate-50/60")
            ]}>
              <div class="mb-3 flex items-center justify-between">
                <div class="flex items-center gap-3">
                  <div class="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-blue-600 text-xs font-bold text-white">
                    {idx + 1}
                  </div>
                  <div>
                    <p class="text-base font-semibold text-gray-900">{patient_name(entry.patient)}</p>
                    <div class="mt-0.5 flex items-center gap-3 text-xs text-gray-500">
                      <%= if entry.patient.gsrn do %>
                        <span class="font-mono">GSRN: {entry.patient.gsrn}</span>
                      <% end %>
                    </div>
                  </div>
                </div>
                <div class="text-right">
                  <p class="text-xs uppercase tracking-wide text-gray-400">Patient Total</p>
                  <p class="text-xl font-bold tabular-nums text-emerald-700">
                    KSh {format_currency(entry.total_amount)}
                  </p>
                  <p class="mt-0.5 text-xs text-gray-400">
                    {length(entry.records)} item{if length(entry.records) != 1, do: "s", else: ""}
                  </p>
                </div>
              </div>

              <% summary_rows = patient_summary_rows(entry.records) %>

              <%= if Enum.empty?(summary_rows) do %>
                <p class="text-sm italic text-gray-400">No records found.</p>
              <% else %>
                <div class="overflow-hidden rounded-lg border border-gray-200">
                  <table class="min-w-full divide-y divide-gray-200 text-sm">
                    <thead class="bg-gray-100">
                      <tr>
                        <th class="px-4 py-2.5 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                          Category
                        </th>
                        <th class="w-24 px-4 py-2.5 text-center text-xs font-semibold uppercase tracking-wider text-gray-500">
                          Items
                        </th>
                        <th class="w-36 px-4 py-2.5 text-right text-xs font-semibold uppercase tracking-wider text-gray-500">
                          Amount (KSh)
                        </th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100 bg-white">
                      <%= for row <- summary_rows do %>
                        <tr>
                          <td class="px-4 py-3">
                            <span class={"inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold #{row.badge}"}>
                              {row.label}
                            </span>
                          </td>
                          <td class="px-4 py-3 text-center tabular-nums text-gray-500">
                            {row.count} item{if row.count != 1, do: "s", else: ""}
                          </td>
                          <td class="px-4 py-3 text-right font-semibold tabular-nums text-gray-900">
                            {format_currency(row.total)}
                          </td>
                        </tr>
                      <% end %>
                    </tbody>
                    <tfoot class="border-t border-gray-200 bg-gray-50">
                      <tr>
                        <td
                          colspan="2"
                          class="px-4 py-2.5 text-right text-sm font-semibold text-gray-700"
                        >
                          Patient Subtotal
                        </td>
                        <td class="px-4 py-2.5 text-right text-sm font-bold tabular-nums text-emerald-700">
                          {format_currency(entry.total_amount)}
                        </td>
                      </tr>
                    </tfoot>
                  </table>
                </div>
              <% end %>
            </div>

            <%= if idx < length(@report.claim_data) - 1 do %>
              <div class="mx-8 border-t border-dashed border-gray-300" />
            <% end %>
          <% end %>

          <div class="border-t-2 border-blue-700 bg-blue-700 px-8 py-5 text-white">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-medium text-blue-100">Grand Total — {@report.insurer_name}</p>
                <p class="mt-0.5 text-xs text-blue-300">
                  {@report.insurer_summary.patient_count} patients · {@report.insurer_summary.total_records} records
                </p>
              </div>
              <div class="text-right">
                <p class="text-xs uppercase tracking-wide text-blue-300">Total Amount Due</p>
                <p class="mt-0.5 text-3xl font-bold tabular-nums">
                  KSh {format_currency(@report.insurer_summary.total_amount)}
                </p>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp patient_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
  end

  defp format_currency(amount) when is_integer(amount),
    do: Number.Delimit.number_to_delimited(amount, precision: 0)

  defp format_currency(nil), do: "0"

  defp format_generated_at(datetime) do
    datetime
    |> DateTime.shift_zone!("Africa/Nairobi")
    |> Timex.format!("%d %b %Y %I:%M %p", :strftime)
  end

  defp patient_summary_rows(records) do
    [:visit, :drug, :nurse_procedure, :doctor_procedure, :lab]
    |> Enum.map(fn type ->
      rows = Enum.filter(records, &(&1.type == type))
      {label, badge} = type_meta(type)

      %{
        label: label,
        badge: badge,
        count: length(rows),
        total: Enum.sum(Enum.map(rows, &(&1.amount || 0)))
      }
    end)
    |> Enum.filter(&(&1.count > 0))
  end

  defp type_meta(:visit), do: {"Consultancy", "bg-purple-100 text-purple-700"}
  defp type_meta(:drug), do: {"Pharmacy", "bg-blue-100 text-blue-700"}
  defp type_meta(:nurse_procedure), do: {"Nursing", "bg-teal-100 text-teal-700"}
  defp type_meta(:doctor_procedure), do: {"Doctor Procedure", "bg-indigo-100 text-indigo-700"}
  defp type_meta(:lab), do: {"Lab Tests", "bg-amber-100 text-amber-700"}
end
