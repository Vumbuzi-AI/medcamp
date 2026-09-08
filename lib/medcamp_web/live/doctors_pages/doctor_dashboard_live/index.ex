defmodule MedcampWeb.DoctorDashboardLive.Index do
  use MedcampWeb, :doctor_live_view

  alias Medcamp.DoctorNotes
  alias Medcamp.LabResults
  alias Medcamp.PatientVisits
  alias Medcamp.Patients
  alias MedcampWeb.Dashboards.WidgetResolver

  @role "doctor"

  @impl true
  def mount(_params, _session, socket) do
    today = today_eat()
    {date_from, date_to} = period_to_range(:this_month, today)

    {:ok,
     socket
     |> assign(:active_tab, :dashboard)
     |> assign(:page_title, "Doctor Dashboard")
     |> assign(:period, :this_month)
     |> assign(:date_from, date_from)
     |> assign(:date_to, date_to)
     |> assign(:search, "")
     |> assign(:visit_chart_tab, :visit_type)
     |> assign(:visible_summary_cards, WidgetResolver.summary_cards(@role))
     |> assign(:visible_analytics_tabs, WidgetResolver.analytics_tabs(@role))
     |> assign(:dashboard_analytics_tab, WidgetResolver.default_analytics_tab(@role))
     |> load_data()}
  end

  @impl true
  def handle_event("set_period", %{"period" => period}, socket) do
    period_atom = String.to_existing_atom(period)
    today = today_eat()

    socket =
      case period_atom do
        :custom ->
          assign(socket, :period, :custom)

        _ ->
          {date_from, date_to} = period_to_range(period_atom, today)

          socket
          |> assign(:period, period_atom)
          |> assign(:date_from, date_from)
          |> assign(:date_to, date_to)
          |> load_data()
      end

    {:noreply, socket}
  end

  def handle_event("filter", %{"filter" => params}, socket) do
    date_from = parse_date(params["date_from"]) || socket.assigns.date_from
    date_to = parse_date(params["date_to"]) || socket.assigns.date_to

    {:noreply,
     socket
     |> assign(:period, :custom)
     |> assign(:date_from, date_from)
     |> assign(:date_to, date_to)
     |> load_data()}
  end

  def handle_event("clear_filters", _params, socket) do
    today = today_eat()
    {date_from, date_to} = period_to_range(:this_month, today)

    {:noreply,
     socket
     |> assign(:period, :this_month)
     |> assign(:date_from, date_from)
     |> assign(:date_to, date_to)
     |> load_data()}
  end

  def handle_event("search", %{"search" => %{"term" => term}}, socket) do
    {:noreply,
     socket
     |> assign(:search, term)
     |> load_data()}
  end

  def handle_event("set_visit_chart_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :visit_chart_tab, String.to_existing_atom(tab))}
  end

  def handle_event("set_dashboard_analytics_tab", %{"tab" => tab}, socket) do
    tab = String.to_existing_atom(tab)

    if tab in socket.assigns.visible_analytics_tabs do
      {:noreply, assign(socket, :dashboard_analytics_tab, tab)}
    else
      {:noreply, socket}
    end
  end

  defp load_data(socket) do
    doctor_id = socket.assigns.current_user.id
    date_from = socket.assigns.date_from
    date_to = socket.assigns.date_to
    search = socket.assigns.search

    visits =
      PatientVisits.filter_patient_visits(%{
        doctor_id: doctor_id,
        date_from: date_from,
        date_to: date_to,
        search: search
      })

    doctor_notes = filter_doctor_notes_for_doctor(doctor_id, date_from, date_to)

    lab_results =
      LabResults.filter_lab_results(%{
        doctor_id: doctor_id,
        date_from: date_from,
        date_to: date_to
      })

    patients = visits |> Enum.map(& &1.patient) |> Enum.reject(&is_nil/1) |> Enum.uniq_by(& &1.id)
    stats = Patients.compute_camp_stats_for_patients(patients)

    daily_registrations = build_daily_registrations(patients, date_from, date_to)
    gender_breakdown = build_gender_breakdown(stats)
    age_groups = build_age_groups(stats)
    geographic = build_geographic_breakdown(patients)
    visit_types = build_visit_types(visits)
    visit_statuses = build_visit_statuses(visits)

    socket
    |> assign(:visits, visits)
    |> assign(:doctor_notes, doctor_notes)
    |> assign(:lab_results, lab_results)
    |> assign(:stats, stats)
    |> assign(:daily_registrations, daily_registrations)
    |> assign(:gender_breakdown, gender_breakdown)
    |> assign(:age_groups, age_groups)
    |> assign(:geographic, geographic)
    |> assign(:visit_types, visit_types)
    |> assign(:visit_statuses, visit_statuses)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 -m-4 sm:-m-6 p-4 sm:p-6">
      <div class="w-[95%] mx-auto space-y-6">
        <.dashboard_top_card
          title="Doctor Dashboard"
          subtitle={"Your patients and visits for #{format_date(@date_from)} to #{format_date(@date_to)}"}
          search_name="search[term]"
          search_value={@search}
          search_placeholder="Search my patients or visits..."
          filter_id="doctor-dashboard-filters"
          active_filter_count={if @period == :custom, do: 1, else: 0}
        >
          <:filter_group label="Date range">
            <.date_range_fields
              from_name="filter[date_from]"
              to_name="filter[date_to]"
              from_value={Date.to_iso8601(@date_from)}
              to_value={Date.to_iso8601(@date_to)}
            />
          </:filter_group>
          <:actions>
            <.period_btn label="This Month" period="this_month" active={@period} />
            <.period_btn label="Last Month" period="last_month" active={@period} />
            <.period_btn label="Last 30 Days" period="last_30_days" active={@period} />
            <.period_btn label="This Year" period="this_year" active={@period} />
            <.period_btn label="All Time" period="all_time" active={@period} />
          </:actions>
        </.dashboard_top_card>
        
    <!-- Summary Cards -->
        <.summary_card_grid cards={summary_cards(assigns)} />
        
    <!-- Dashboard Analytics -->
        <.analytics_section
          title="Dashboard analytics"
          subtitle={analytics_subtitle(@dashboard_analytics_tab)}
        >
          <:actions>
            <.analytics_tab_toggle
              visible_tabs={@visible_analytics_tabs}
              active_tab={@dashboard_analytics_tab}
            />
          </:actions>
          <div
            :if={@dashboard_analytics_tab == :patients}
            class="grid grid-cols-1 xl:grid-cols-2 gap-6"
          >
            <.chart_panel
              title="Daily New Patients"
              subtitle="Your patient registrations per day."
              config={daily_registrations_chart(@daily_registrations)}
              height="320px"
            />
            <.chart_panel
              title="Age Distribution"
              subtitle="Age segmentation of your patients."
              config={age_chart(@age_groups)}
              height="320px"
            />
            <.chart_panel
              title="Gender Distribution"
              subtitle="Patient mix by gender."
              config={gender_chart(@gender_breakdown)}
              height="320px"
            />
            <.age_group_breakdown_card age_groups={@stats.age_groups} total={@stats.total} />
          </div>

          <div
            :if={@dashboard_analytics_tab == :operations}
            class="grid grid-cols-1 xl:grid-cols-2 gap-6"
          >
            <.visit_breakdown_card
              active_view={@visit_chart_tab}
              visit_types={@visit_types}
              visit_statuses={@visit_statuses}
            />
            <.geographic_spread_table rows={@geographic} />
          </div>
        </.analytics_section>
      </div>
    </div>
    """
  end

  # ---- Components ----

  attr :label, :string, required: true
  attr :period, :string, required: true
  attr :active, :atom, required: true

  defp period_btn(assigns) do
    assigns = assign(assigns, :is_active, to_string(assigns.active) == assigns.period)

    ~H"""
    <button
      phx-click="set_period"
      phx-value-period={@period}
      class={[
        "px-3 py-1.5 rounded-full text-xs font-semibold transition-colors",
        if(@is_active,
          do: "bg-brand-primary text-white",
          else: "bg-gray-100 text-gray-600 hover:bg-gray-200"
        )
      ]}
    >
      {@label}
    </button>
    """
  end

  defp summary_cards(assigns) do
    summary_cards_for(assigns.visible_summary_cards, %{
      patient_visits: {length(assigns.visits), "Visits in selected window"},
      doctor_notes: {length(assigns.doctor_notes), "Notes recorded"},
      lab_tests_done: {length(assigns.lab_results), "Completed lab tests"}
    })
  end

  defp analytics_subtitle(:patients), do: "Patients — Patient mix and registration trends"
  defp analytics_subtitle(:operations), do: "Operations — Visits, staff and locations"

  # ---- Period & Date helpers ----

  defp today_eat do
    DateTime.utc_now() |> DateTime.add(3 * 3600, :second) |> DateTime.to_date()
  end

  defp period_to_range(:this_month, today) do
    {Date.beginning_of_month(today), Date.end_of_month(today)}
  end

  defp period_to_range(:last_month, today) do
    last_month_day = Date.add(Date.beginning_of_month(today), -1)
    {Date.beginning_of_month(last_month_day), Date.end_of_month(last_month_day)}
  end

  defp period_to_range(:last_30_days, today) do
    {Date.add(today, -29), today}
  end

  defp period_to_range(:this_year, today) do
    {%{today | month: 1, day: 1}, %{today | month: 12, day: 31}}
  end

  defp period_to_range(:all_time, today) do
    {~D[2020-01-01], today}
  end

  defp period_to_range(:custom, today), do: {today, today}

  defp parse_date(nil), do: nil
  defp parse_date(""), do: nil

  defp parse_date(value) when is_binary(value) do
    case Date.from_iso8601(value) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%d %b %Y")
  defp format_date(_), do: "—"

  # ---- Data filters ----

  defp filter_doctor_notes_for_doctor(doctor_id, date_from, date_to) do
    doctor_id
    |> DoctorNotes.list_doctor_notes_for_doctor()
    |> Enum.filter(fn note ->
      d = doctor_note_date(note)
      d != nil and Date.compare(d, date_from) != :lt and Date.compare(d, date_to) != :gt
    end)
  end

  defp doctor_note_date(%{date: %Date{} = date}), do: date
  defp doctor_note_date(%{inserted_at: dt}), do: datetime_to_eat_date(dt)
  defp doctor_note_date(_), do: nil

  defp datetime_to_eat_date(nil), do: nil

  defp datetime_to_eat_date(%DateTime{} = dt) do
    dt |> DateTime.add(3 * 3600, :second) |> DateTime.to_date()
  end

  defp datetime_to_eat_date(%NaiveDateTime{} = dt), do: NaiveDateTime.to_date(dt)
  defp datetime_to_eat_date(_), do: nil

  # ---- Stat builders ----

  defp build_gender_breakdown(stats) do
    other = max(stats.total - stats.male - stats.female, 0)

    [
      %{label: "Male", count: stats.male},
      %{label: "Female", count: stats.female},
      %{label: "Unspecified", count: other}
    ]
  end

  defp build_age_groups(stats) do
    [
      %{label: "Under 5", count: stats.age_groups.under_5},
      %{label: "5 – 17", count: stats.age_groups.age_5_17},
      %{label: "18 – 59", count: stats.age_groups.age_18_59},
      %{label: "60+", count: stats.age_groups.over_60}
    ]
  end

  defp build_visit_types(visits) do
    visits
    |> Enum.group_by(fn v -> v.visit_type || "Unspecified" end)
    |> Enum.map(fn {label, list} -> %{label: label, count: length(list)} end)
    |> Enum.sort_by(& &1.count, :desc)
  end

  # A camp charges nothing, so this charts where patients are in
  # the camp flow instead of how they paid.
  defp build_visit_statuses(visits) do
    visits
    |> Enum.group_by(fn v -> Medcamp.PatientVisits.PatientVisit.status_label(v.status) end)
    |> Enum.map(fn {label, list} -> %{label: label, count: length(list)} end)
    |> Enum.sort_by(& &1.count, :desc)
  end

  defp build_geographic_breakdown(patients) do
    total = max(length(patients), 1)

    patients
    |> Enum.map(&normalize_address/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.frequencies()
    |> Enum.map(fn {address, count} ->
      %{address: address, count: count, pct: round(count * 100 / total)}
    end)
    |> Enum.sort_by(& &1.count, :desc)
  end

  defp normalize_address(%{home_address: address}) when is_binary(address) do
    case String.trim(address) do
      "" -> nil
      value -> value |> String.split(",") |> List.first() |> String.trim()
    end
  end

  defp normalize_address(_), do: nil

  defp build_daily_registrations(patients, date_from, date_to) do
    days = list_days(date_from, date_to) |> Enum.take(-90)

    by_day =
      patients
      |> Enum.group_by(fn p -> datetime_to_eat_date(p.inserted_at) end)
      |> Enum.into(%{}, fn {day, list} -> {day, length(list)} end)

    Enum.map(days, fn day ->
      %{date: day, count: Map.get(by_day, day, 0)}
    end)
  end

  defp list_days(date_from, date_to) do
    Date.range(date_from, date_to) |> Enum.to_list()
  end
end
