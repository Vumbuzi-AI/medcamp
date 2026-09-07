defmodule MedcampWeb.AdminInsuranceLive.Show do
  use MedcampWeb, :admin_live_view

  alias Medcamp.Insurance
  alias Medcamp.Patients

  @impl true
  def mount(%{"patient_id" => patient_id}, _session, socket) do
    patient = Patients.get_patient!(patient_id)
    grouped_records = Insurance.get_insurance_records_for_patient(patient_id)
    summary = Insurance.patient_insurance_summary(patient_id)

    {:ok,
     socket
     |> assign(:active_tab, :insurance)
     |> assign(:patient, patient)
     |> assign(:grouped_records, grouped_records)
     |> assign(:summary, summary)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <%!-- Back link --%>
      <div>
        <.link
          navigate="/admin/insurance"
          class="inline-flex items-center gap-1.5 text-sm text-gray-500 hover:text-gray-700"
        >
          <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" /> Back to Insurance List
        </.link>
      </div>

      <%!-- Patient Info Card --%>
      <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 px-6 py-5">
        <div class="flex items-start gap-4">
          <div class="flex h-14 w-14 shrink-0 items-center justify-center rounded-full bg-blue-100 text-blue-700 font-bold text-xl">
            {String.first(@patient.first_name || "?")}
          </div>
          <div class="flex-1 min-w-0">
            <h1 class="text-xl font-semibold text-slate-900">
              {[@patient.first_name, @patient.middle_name, @patient.last_name]
              |> Enum.filter(&(&1 != nil))
              |> Enum.join(" ")}
            </h1>
            <div class="mt-1 flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-slate-500">
              <span :if={@patient.gsrn} class="flex items-center gap-1">
                <Heroicons.icon name="identification" type="outline" class="h-3.5 w-3.5" />
                {@patient.gsrn}
              </span>
              <span :if={@patient.email} class="flex items-center gap-1">
                <Heroicons.icon name="envelope" type="outline" class="h-3.5 w-3.5" />
                {@patient.email}
              </span>
              <span :if={@patient.phone_number} class="flex items-center gap-1">
                <Heroicons.icon name="phone" type="outline" class="h-3.5 w-3.5" />
                {@patient.phone_number}
              </span>
              <span :if={@patient.gender} class="flex items-center gap-1">
                <Heroicons.icon name="user" type="outline" class="h-3.5 w-3.5" />
                {@patient.gender}
              </span>
            </div>
          </div>

          <%!-- Summary Stats --%>
          <div class="flex shrink-0 gap-4">
            <div class="text-center">
              <p class="text-2xl font-bold text-slate-900">{@summary.total_records}</p>
              <p class="text-xs text-slate-500 mt-0.5">Total Records</p>
            </div>
            <div class="text-center">
              <p class="text-2xl font-bold text-blue-700">{length(@summary.unique_insurers)}</p>
              <p class="text-xs text-slate-500 mt-0.5">Insurer(s)</p>
            </div>
            <div class="text-center">
              <p class="text-2xl font-bold text-slate-900">{length(@grouped_records)}</p>
              <p class="text-xs text-slate-500 mt-0.5">Days</p>
            </div>
          </div>
        </div>

        <%!-- Insurer badges --%>
        <%= if length(@summary.unique_insurers) > 0 do %>
          <div class="mt-4 flex flex-wrap gap-2 pt-4 border-t border-slate-100">
            <span class="text-xs font-medium text-slate-500 self-center">Insurers:</span>
            <%= for insurer <- @summary.unique_insurers do %>
              <span class="inline-flex items-center gap-1 rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700 ring-1 ring-inset ring-blue-700/10">
                <Heroicons.icon name="shield-check" type="solid" class="h-3 w-3" />
                {insurer}
              </span>
            <% end %>
          </div>
        <% end %>
      </div>

      <%!-- Timeline --%>
      <%= if Enum.empty?(@grouped_records) do %>
        <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 flex flex-col items-center justify-center py-20 px-4 text-center">
          <div class="flex h-16 w-16 items-center justify-center rounded-full bg-blue-50">
            <Heroicons.icon name="document-text" type="outline" class="h-8 w-8 text-blue-400" />
          </div>
          <h3 class="mt-4 text-base font-medium text-slate-900">No insurance records</h3>
          <p class="mt-2 text-sm text-slate-500">
            No insurance-tagged records found for this patient.
          </p>
        </div>
      <% else %>
        <div class="space-y-6">
          <%= for {date, records} <- @grouped_records do %>
            <div class="bg-white rounded-xl shadow-sm border border-slate-200/80 overflow-hidden">
              <%!-- Day header --%>
              <div class="flex items-center gap-3 px-6 py-4 bg-slate-50 border-b border-slate-200">
                <div class="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-blue-600 text-white">
                  <Heroicons.icon name="calendar-days" type="solid" class="h-4 w-4" />
                </div>
                <div>
                  <p class="font-semibold text-slate-800">{format_date(date)}</p>
                  <p class="text-xs text-slate-500">
                    {length(records)} insurance record{if length(records) != 1, do: "s", else: ""}
                  </p>
                </div>
                <div class="ml-auto">
                  <% day_total =
                    records |> Enum.map(& &1.amount) |> Enum.reject(&is_nil/1) |> Enum.sum() %>
                  <%= if day_total > 0 do %>
                    <span class="inline-flex items-center rounded-full bg-green-50 px-3 py-1 text-sm font-semibold text-green-700 ring-1 ring-inset ring-green-600/20">
                      KES {day_total} /=
                    </span>
                  <% end %>
                </div>
              </div>

              <%!-- Records for the day --%>
              <div class="divide-y divide-slate-100">
                <%= for record <- records do %>
                  <div class="px-6 py-4 flex items-start gap-4 hover:bg-slate-50/50 transition-colors">
                    <%!-- Type icon --%>
                    <div class={[
                      "flex h-9 w-9 shrink-0 items-center justify-center rounded-lg",
                      record_bg_color(record.type)
                    ]}>
                      <Heroicons.icon
                        name={record_icon(record.type)}
                        type="outline"
                        class={"h-5 w-5 #{record_icon_color(record.type)}"}
                      />
                    </div>

                    <%!-- Record info --%>
                    <div class="flex-1 min-w-0">
                      <div class="flex items-center gap-2 flex-wrap">
                        <span class={[
                          "inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold ring-1 ring-inset",
                          record_badge_class(record.type)
                        ]}>
                          {record.label}
                        </span>
                        <%= if record.has_paid do %>
                          <span class="inline-flex items-center gap-1 rounded-full bg-emerald-50 px-2.5 py-0.5 text-xs font-semibold text-emerald-700 ring-1 ring-inset ring-emerald-600/20">
                            <Heroicons.icon name="check-circle" type="solid" class="h-3 w-3" /> Paid
                          </span>
                        <% else %>
                          <span class="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2.5 py-0.5 text-xs font-semibold text-amber-700 ring-1 ring-inset ring-amber-600/20">
                            <Heroicons.icon name="clock" type="solid" class="h-3 w-3" /> Pending
                          </span>
                        <% end %>
                        <%= if record.insurance_name do %>
                          <span class="inline-flex items-center gap-1 rounded-full bg-blue-50 px-2.5 py-0.5 text-xs font-medium text-blue-700 ring-1 ring-inset ring-blue-700/10">
                            <Heroicons.icon name="shield-check" type="solid" class="h-3 w-3" />
                            {record.insurance_name}
                          </span>
                        <% end %>
                      </div>
                      <p class="mt-1 text-sm font-medium text-slate-800">{record.description}</p>
                      <p class="mt-0.5 text-xs text-slate-400">{format_time(record.inserted_at)}</p>
                    </div>

                    <%!-- Amount --%>
                    <div class="shrink-0 text-right">
                      <%= if record.amount && record.amount > 0 do %>
                        <p class="text-sm font-semibold text-slate-900">KES {record.amount}</p>
                      <% else %>
                        <p class="text-sm text-slate-400">—</p>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  defp record_icon(:visit), do: "home-modern"
  defp record_icon(:drug), do: "beaker"
  defp record_icon(:nurse_procedure), do: "heart"
  defp record_icon(:doctor_procedure), do: "academic-cap"
  defp record_icon(:lab), do: "document-magnifying-glass"

  defp record_bg_color(:visit), do: "bg-purple-100"
  defp record_bg_color(:drug), do: "bg-green-100"
  defp record_bg_color(:nurse_procedure), do: "bg-pink-100"
  defp record_bg_color(:doctor_procedure), do: "bg-orange-100"
  defp record_bg_color(:lab), do: "bg-cyan-100"

  defp record_icon_color(:visit), do: "text-purple-600"
  defp record_icon_color(:drug), do: "text-green-600"
  defp record_icon_color(:nurse_procedure), do: "text-pink-600"
  defp record_icon_color(:doctor_procedure), do: "text-orange-600"
  defp record_icon_color(:lab), do: "text-cyan-600"

  defp record_badge_class(:visit), do: "bg-slate-50 text-purple-700 ring-purple-700/10"
  defp record_badge_class(:drug), do: "bg-green-50 text-green-700 ring-green-600/20"
  defp record_badge_class(:nurse_procedure), do: "bg-pink-50 text-pink-700 ring-pink-700/10"

  defp record_badge_class(:doctor_procedure),
    do: "bg-orange-50 text-orange-700 ring-orange-700/10"

  defp record_badge_class(:lab), do: "bg-cyan-50 text-cyan-700 ring-cyan-700/10"

  defp format_date(date) do
    day_of_week = Calendar.strftime(date, "%A")
    "#{day_of_week}, #{Calendar.strftime(date, "%B %-d, %Y")}"
  end

  defp format_time(datetime) do
    datetime
    |> DateTime.shift_zone!("Africa/Nairobi")
    |> Timex.format!("{h12}:{m} {AM}")
  end
end
