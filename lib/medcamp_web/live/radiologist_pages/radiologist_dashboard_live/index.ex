defmodule MedcampWeb.RadiologistDashboardLive.Index do
  use MedcampWeb, :shared_live_view

  alias Medcamp.RadiologyResults
  alias MedcampWeb.Dashboards.WidgetResolver

  @role "radiologist"

  @impl true
  def mount(_params, _session, socket) do
    {date_from, date_to} = current_month_range()

    {:ok,
     socket
     |> assign(:active_tab, :dashboard)
     |> assign(:page_title, "Radiology Dashboard")
     |> assign(:date_from, date_from)
     |> assign(:date_to, date_to)
     |> assign(:visible_summary_cards, WidgetResolver.summary_cards(@role))
     |> load_data()}
  end

  defp load_data(socket) do
    date_from = socket.assigns.date_from
    date_to = socket.assigns.date_to

    results =
      RadiologyResults.list_radiology_results()
      |> Enum.filter(&inserted_in_range?(&1.inserted_at, date_from, date_to))

    socket
    |> assign(:results, results)
    |> assign(:recent_items, recent_radiology_items(results))
  end

  defp radiologist_tabs do
    [
      %{
        name: "Dashboard",
        icon: "home-modern",
        url: "/radiologist/dashboard",
        tab_name: :dashboard
      },
      %{
        name: "Scan Patient",
        icon: "magnifying-glass-circle",
        url: "/radiologist/scan",
        tab_name: :scan
      },
      %{
        name: "Radiology Tests",
        icon: "briefcase",
        url: "/radiologist/radiology_results",
        tab_name: :radiology_results
      },
      %{
        name: "Shift Handover",
        icon: "users",
        url: "/radiologist/shift_handovers",
        tab_name: :shift_handovers
      },
      %{
        name: "Requisitions",
        icon: "document-text",
        url: "/radiologist/requisitions",
        tab_name: :requisitions
      },
      %{
        name: "Forms",
        icon: "clipboard-document-list",
        url: "/radiologist/forms",
        tab_name: :forms
      }
    ]
  end

  defp get_icon_name(icon), do: icon
  defp get_color_for_tab(:dashboard), do: "indigo"
  defp get_color_for_tab(:scan), do: "blue"
  defp get_color_for_tab(:radiology_results), do: "purple"
  defp get_color_for_tab(:shift_handovers), do: "orange"
  defp get_color_for_tab(:requisitions), do: "red"
  defp get_color_for_tab(:forms), do: "amber"
  defp get_color_for_tab(_), do: "gray"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 -m-4 sm:-m-6 p-4 sm:p-6">
      <div class="w-[95%] mx-auto space-y-6">
        <.dashboard_top_card
          title="Radiology Dashboard"
          subtitle={"Imaging throughput and reporting workload for #{month_label(@date_from)}"}
        />

        <.summary_card_grid cards={dashboard_cards(assigns)} />

        <div class="grid grid-cols-1 xl:grid-cols-3 gap-6">
          <div class="xl:col-span-2 bg-white rounded-2xl shadow-sm border border-gray-100 p-6">
            <div class="mb-6">
              <h2 class="text-xl font-semibold text-gray-900">Quick actions</h2>
              <p class="text-sm text-gray-500 mt-1">
                Open imaging queues, handovers, and supporting workflows.
              </p>
            </div>

            <div class="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
              <%= for tab <- radiologist_tabs() do %>
                <.quick_action
                  label={tab.name}
                  icon={"hero-#{get_icon_name(tab.icon)}"}
                  href={tab.url}
                  color={get_color_for_tab(tab.tab_name)}
                />
              <% end %>
            </div>
          </div>

          <.recent_items
            title="Recent imaging work"
            items={@recent_items}
            empty_message="No radiology results recorded for this month yet."
          />
        </div>
      </div>
    </div>
    """
  end

  defp dashboard_cards(assigns) do
    summary_cards_for(assigns.visible_summary_cards, %{
      radiology_exams: {length(assigns.results), "Radiology results recorded this month"},
      completed_radiology_reports: {count_completed(assigns.results), "Reports fully completed"},
      pending_radiology_reports: {count_pending(assigns.results), "Reports awaiting review"},
      urgent_radiology_cases: {count_urgent(assigns.results), "Urgent studies in the period"}
    })
  end

  defp count_completed(results), do: Enum.count(results, & &1.report_complete)
  defp count_pending(results), do: Enum.count(results, &(!&1.report_complete))
  defp count_urgent(results), do: Enum.count(results, &(&1.urgency == "urgent"))

  defp recent_radiology_items(results) do
    results
    |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
    |> Enum.take(5)
    |> Enum.map(fn result ->
      %{
        title: patient_name(result.patient),
        subtitle: result.description || "Radiology result recorded",
        badge: if(result.report_complete, do: "Reported", else: "Pending"),
        badge_color:
          if(result.report_complete,
            do: "bg-emerald-100 text-emerald-700",
            else: "bg-amber-100 text-amber-700"
          )
      }
    end)
  end

  defp patient_name(nil), do: "Patient"

  defp patient_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.reject(&is_nil_or_blank/1)
    |> Enum.join(" ")
  end

  defp month_label(date), do: Calendar.strftime(date, "%B %Y")

  defp current_month_range do
    today = Date.utc_today()
    {%{today | day: 1}, today}
  end

  defp inserted_in_range?(nil, _from, _to), do: false

  defp inserted_in_range?(inserted_at, from, to) do
    date = DateTime.to_date(inserted_at)
    Date.compare(date, from) != :lt and Date.compare(date, to) != :gt
  end

  defp is_nil_or_blank(nil), do: true
  defp is_nil_or_blank(""), do: true
  defp is_nil_or_blank(_), do: false
end
