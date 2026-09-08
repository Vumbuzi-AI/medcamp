defmodule MedcampWeb.LabDashboardLive.Index do
  use MedcampWeb, :lab_live_view

  alias Medcamp.LabResults
  alias MedcampWeb.Dashboards.WidgetResolver

  @role "labtechnician"

  @impl true
  def mount(_params, _session, socket) do
    today = today_eat()
    {date_from, date_to} = period_to_range(:this_month, today)

    {:ok,
     socket
     |> assign(:active_tab, :dashboard)
     |> assign(:page_title, "Lab Dashboard")
     |> assign(:period, :this_month)
     |> assign(:date_from, date_from)
     |> assign(:date_to, date_to)
     |> assign(:search, "")
     |> assign(:visible_summary_cards, WidgetResolver.summary_cards(@role))
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

  def handle_event("search", %{"search" => %{"term" => term}}, socket) do
    {:noreply,
     socket
     |> assign(:search, term)
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
     |> assign(:search, "")
     |> load_data()}
  end

  defp load_data(socket) do
    date_from = socket.assigns.date_from
    date_to = socket.assigns.date_to
    search = socket.assigns.search

    lab_results =
      LabResults.list_lab_results()
      |> Enum.filter(&inserted_in_range?(&1.inserted_at, date_from, date_to))
      |> filter_lab_search(search)

    patients = lab_results |> Enum.map(& &1.patient) |> Enum.reject(&is_nil/1)

    socket
    |> assign(:lab_results, lab_results)
    |> assign(:daily_lab_results, build_daily_counts(lab_results, date_from, date_to))
    |> assign(:lab_status_breakdown, build_status_breakdown(lab_results))
    |> assign(:lab_gender_breakdown, build_gender_breakdown(patients))
    |> assign(:lab_age_groups, build_age_groups(patients))
    |> assign(:test_name_breakdown, build_test_name_breakdown(lab_results))
    |> assign(:recent_items, recent_lab_items(lab_results))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 -m-4 sm:-m-6 p-4 sm:p-6">
      <div class="w-[95%] mx-auto space-y-6">
        <.dashboard_top_card
          title="Lab Dashboard"
          subtitle={"Testing throughput and reporting progress for #{format_date(@date_from)} to #{format_date(@date_to)}"}
          search_name="search[term]"
          search_value={@search}
          search_placeholder="Search patients or test names..."
          filter_id="lab-dashboard-filters"
          active_filter_count={active_filter_count(@period, @search)}
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

        <.summary_card_grid cards={dashboard_cards(assigns)} />

        <.analytics_section
          title="Dashboard analytics"
          subtitle="Lab volume, completion status, and patient mix"
        >
          <div class="grid grid-cols-1 xl:grid-cols-2 gap-6">
            <.chart_panel
              title="Daily Lab Activity"
              subtitle="Lab results recorded across the current month."
              config={daily_registrations_chart(@daily_lab_results)}
              height="320px"
            />
            <.chart_panel
              title="Report Status"
              subtitle="Completed versus pending lab reports."
              config={visit_type_chart(@lab_status_breakdown)}
              height="320px"
            />
            <.chart_panel
              title="Patient Gender Distribution"
              subtitle="Gender mix of patients with lab work this month."
              config={gender_chart(@lab_gender_breakdown)}
              height="320px"
            />
            <.chart_panel
              title="Top Test Mix"
              subtitle="Most common tests appearing in lab results."
              config={revenue_by_reason_chart(@test_name_breakdown)}
              height="320px"
            />
          </div>
          <div class="w-full mt-4">
            <.age_group_breakdown_card
              age_groups={age_group_map(@lab_age_groups)}
              total={length(@lab_results)}
            />
          </div>
        </.analytics_section>
      </div>
    </div>
    """
  end

  defp dashboard_cards(assigns) do
    summary_cards_for(assigns.visible_summary_cards, %{
      lab_results: {length(assigns.lab_results), "Results created this month"},
      completed_lab_reports: {count_completed(assigns.lab_results), "Reports marked complete"},
      pending_lab_results: {count_pending(assigns.lab_results), "Results  awaiting completion"}
    })
  end

  defp count_completed(results), do: Enum.count(results, & &1.report_complete)
  defp count_pending(results), do: Enum.count(results, &(!&1.report_complete))

  defp build_daily_counts(results, date_from, date_to) do
    counts =
      Enum.reduce(results, %{}, fn result, acc ->
        date = DateTime.to_date(result.inserted_at)
        Map.update(acc, date, 1, &(&1 + 1))
      end)

    Date.range(date_from, date_to)
    |> Enum.map(fn date -> %{date: date, count: Map.get(counts, date, 0)} end)
  end

  defp build_status_breakdown(results) do
    [
      %{label: "Completed", count: count_completed(results)},
      %{label: "Pending", count: count_pending(results)}
    ]
  end

  defp build_gender_breakdown(patients) do
    patients
    |> Enum.group_by(&normalize_gender(&1.gender))
    |> Enum.map(fn {label, rows} -> %{label: label, count: length(rows)} end)
    |> Enum.sort_by(& &1.label)
  end

  defp build_age_groups(patients) do
    groups = %{"Under 5" => 0, "5 - 17" => 0, "18 - 59" => 0, "60+" => 0}

    patients
    |> Enum.reduce(groups, fn patient, acc ->
      Map.update!(acc, age_group_for(patient), &(&1 + 1))
    end)
    |> Enum.map(fn {label, count} -> %{label: label, count: count} end)
  end

  defp build_test_name_breakdown(results) do
    results
    |> Enum.flat_map(&extract_test_names/1)
    |> Enum.frequencies()
    |> Enum.map(fn {label, count} -> %{label: label, total: count} end)
    |> Enum.sort_by(& &1.total, :desc)
    |> Enum.take(6)
  end

  defp extract_test_names(%{tests: tests}) when is_list(tests) do
    Enum.map(tests, fn
      %{name: name} when is_binary(name) -> name
      %{"name" => name} when is_binary(name) -> name
      _ -> "Unknown Test"
    end)
  end

  defp extract_test_names(_), do: []

  defp age_group_map(rows) do
    lookup = Map.new(rows, &{&1.label, &1.count})

    %{
      under_5: Map.get(lookup, "Under 5", 0),
      age_5_17: Map.get(lookup, "5 - 17", 0),
      age_18_59: Map.get(lookup, "18 - 59", 0),
      over_60: Map.get(lookup, "60+", 0)
    }
  end

  defp recent_lab_items(results) do
    results
    |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
    |> Enum.take(5)
    |> Enum.map(fn result ->
      %{
        title: patient_name(result.patient),
        subtitle:
          "Lab report #{if result.report_complete, do: "completed", else: "still pending"}",
        badge: if(result.report_complete, do: "Complete", else: "Pending"),
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

  defp normalize_gender(nil), do: "Unknown"
  defp normalize_gender(""), do: "Unknown"
  defp normalize_gender(gender), do: gender

  defp age_group_for(patient) do
    age = patient_age(patient)

    cond do
      age < 5 -> "Under 5"
      age < 18 -> "5 - 17"
      age < 60 -> "18 - 59"
      true -> "60+"
    end
  end

  defp patient_age(%{age: age}) when is_integer(age), do: age

  defp patient_age(%{date_of_birth: %Date{} = dob}) do
    today = Date.utc_today()
    years = today.year - dob.year
    birthday_passed? = {today.month, today.day} >= {dob.month, dob.day}
    if birthday_passed?, do: years, else: years - 1
  end

  defp patient_age(_), do: 0

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

  defp filter_lab_search(results, search) when search in [nil, ""], do: results

  defp filter_lab_search(results, search) do
    term = String.downcase(search)

    Enum.filter(results, fn result ->
      patient_match = String.contains?(searchable_patient_text(result.patient), term)

      test_match =
        result |> extract_test_names() |> Enum.any?(&String.contains?(String.downcase(&1), term))

      patient_match or test_match
    end)
  end

  defp searchable_patient_text(nil), do: ""

  defp searchable_patient_text(patient) do
    [patient.first_name, patient.middle_name, patient.last_name, patient.email, patient.gsrn]
    |> Enum.reject(&is_nil_or_blank/1)
    |> Enum.join(" ")
    |> String.downcase()
  end

  defp active_filter_count(period, search) do
    custom_count = if period == :custom, do: 1, else: 0
    search_count = if search in [nil, ""], do: 0, else: 1
    custom_count + search_count
  end

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

  defp period_to_range(:last_30_days, today), do: {Date.add(today, -29), today}

  defp period_to_range(:this_year, today),
    do: {%{today | month: 1, day: 1}, %{today | month: 12, day: 31}}

  defp period_to_range(:all_time, today), do: {~D[2020-01-01], today}
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

  defp inserted_in_range?(nil, _from, _to), do: false

  defp inserted_in_range?(inserted_at, from, to) do
    date = DateTime.to_date(inserted_at)
    Date.compare(date, from) != :lt and Date.compare(date, to) != :gt
  end

  defp is_nil_or_blank(nil), do: true
  defp is_nil_or_blank(""), do: true
  defp is_nil_or_blank(_), do: false
end
