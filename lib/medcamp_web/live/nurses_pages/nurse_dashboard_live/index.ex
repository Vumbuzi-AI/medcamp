defmodule MedcampWeb.NurseDashboardLive.Index do
  use MedcampWeb, :nurse_live_view

  alias Medcamp.NurseProcedures
  alias Medcamp.RoomAllocations
  alias Medcamp.Triages
  alias MedcampWeb.Dashboards.WidgetResolver

  @role "nurse"

  @impl true
  def mount(_params, _session, socket) do
    today = today_eat()
    {date_from, date_to} = period_to_range(:this_month, today)

    {:ok,
     socket
     |> assign(:active_tab, :dashboard)
     |> assign(:page_title, "Nurse Dashboard")
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
    current_user = socket.assigns.current_user
    date_from = socket.assigns.date_from
    date_to = socket.assigns.date_to
    search = socket.assigns.search

    triages =
      Triages.list_triages()
      |> Enum.filter(
        &(same_user?(&1.creator_id, current_user.id) and
            date_in_range?(&1.date, date_from, date_to))
      )
      |> filter_triage_search(search)

    nurse_procedures =
      NurseProcedures.list_nurse_procedures_for_nurse(current_user.id)
      |> Enum.filter(&inserted_in_range?(&1.inserted_at, date_from, date_to))
      |> filter_patient_search(search)

    room_allocations =
      RoomAllocations.list_room_allocations()
      |> Enum.filter(
        &(same_user?(&1.nurse_id, current_user.id) and
            inserted_in_range?(&1.inserted_at, date_from, date_to))
      )
      |> filter_room_search(search)

    patients = triages |> Enum.map(& &1.patient) |> Enum.reject(&is_nil/1)

    socket
    |> assign(:triages, triages)
    |> assign(:nurse_procedures, nurse_procedures)
    |> assign(:room_allocations, room_allocations)
    |> assign(:daily_triages, build_daily_counts(triages, :date, date_from, date_to))
    |> assign(:patient_gender_breakdown, build_gender_breakdown(patients))
    |> assign(:patient_age_groups, build_age_groups(patients))
    |> assign(:workflow_mix, build_workflow_mix(triages, nurse_procedures, room_allocations))
    |> assign(:recent_items, recent_nursing_items(triages, nurse_procedures, room_allocations))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 -m-4 sm:-m-6 p-4 sm:p-6">
      <div class="w-[95%] mx-auto space-y-6">
        <.dashboard_top_card
          title="Nurse Dashboard"
          subtitle={"Patient intake and bedside workflow for #{format_date(@date_from)} to #{format_date(@date_to)}"}
          search_name="search[term]"
          search_value={@search}
          search_placeholder="Search patients, triages, procedures or rooms..."
          filter_id="nurse-dashboard-filters"
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
          subtitle="Nursing workload, patient mix, and room allocation flow"
        >
          <div class="grid grid-cols-1 xl:grid-cols-2 gap-6">
            <.chart_panel
              title="Daily Triage Activity"
              subtitle="Triage entries recorded across the current month."
              config={daily_registrations_chart(@daily_triages)}
              height="320px"
            />
            <.chart_panel
              title="Workflow Mix"
              subtitle="Share of triages, procedures, and room allocations."
              config={visit_type_chart(@workflow_mix)}
              height="320px"
            />
            <.chart_panel
              title="Patient Gender Distribution"
              subtitle="Gender mix of patients seen through triage this month."
              config={gender_chart(@patient_gender_breakdown)}
              height="320px"
            />
            <.chart_panel
              title="Patient Age Distribution"
              subtitle="Age segmentation of patients touched by nursing workflow."
              config={age_chart(@patient_age_groups)}
              height="320px"
            />
          </div>

          <div class="w-full mt-4">
            <.age_group_breakdown_card
              age_groups={age_group_map(@patient_age_groups)}
              total={length(@triages)}
            />
          </div>
        </.analytics_section>
      </div>
    </div>
    """
  end

  defp dashboard_cards(assigns) do
    summary_cards_for(assigns.visible_summary_cards, %{
      triages_completed: {length(assigns.triages), "Triages recorded this month"},
      nurse_procedures: {length(assigns.nurse_procedures), "Procedures logged by you"},
      room_allocations: {length(assigns.room_allocations), "Room assignments updated"}
    })
  end

  defp recent_nursing_items(triages, nurse_procedures, room_allocations) do
    triage_items =
      Enum.map(triages, fn triage ->
        %{
          at: triage.inserted_at,
          title: patient_name(triage.patient),
          subtitle: "Triage recorded on #{format_date(triage.date)}",
          badge: triage.emergency_scale || "Triage",
          badge_color: emergency_badge_color(triage.emergency_scale)
        }
      end)

    procedure_items =
      Enum.map(nurse_procedures, fn procedure ->
        %{
          at: procedure.inserted_at,
          title: patient_name(procedure.patient),
          subtitle: "Procedure logged for nursing follow-up",
          badge: "Procedure",
          badge_color: "bg-emerald-100 text-emerald-700"
        }
      end)

    room_items =
      Enum.map(room_allocations, fn allocation ->
        room_label =
          case allocation.room do
            %{room_number: room_number} when is_binary(room_number) and room_number != "" ->
              room_number

            _ ->
              "assigned room"
          end

        %{
          at: allocation.inserted_at,
          title: patient_name(allocation.patient),
          subtitle: "Room allocation updated for #{room_label}",
          badge: "Room",
          badge_color: "bg-blue-100 text-blue-700"
        }
      end)

    (triage_items ++ procedure_items ++ room_items)
    |> Enum.sort_by(& &1.at, {:desc, DateTime})
    |> Enum.take(5)
    |> Enum.map(&Map.delete(&1, :at))
  end

  defp emergency_badge_color("high"), do: "bg-rose-100 text-rose-700"
  defp emergency_badge_color("medium"), do: "bg-amber-100 text-amber-700"
  defp emergency_badge_color("low"), do: "bg-emerald-100 text-emerald-700"
  defp emergency_badge_color(_), do: "bg-slate-100 text-slate-700"

  defp patient_name(nil), do: "Patient"

  defp patient_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.reject(&is_nil_or_blank/1)
    |> Enum.join(" ")
  end

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
          do: "bg-[#373896] text-white",
          else: "bg-gray-100 text-gray-600 hover:bg-gray-200"
        )
      ]}
    >
      {@label}
    </button>
    """
  end

  defp build_daily_counts(records, date_field, date_from, date_to) do
    counts =
      Enum.reduce(records, %{}, fn record, acc ->
        date = Map.get(record, date_field)

        if date_in_range?(date, date_from, date_to) do
          Map.update(acc, date, 1, &(&1 + 1))
        else
          acc
        end
      end)

    Date.range(date_from, date_to)
    |> Enum.map(fn date -> %{date: date, count: Map.get(counts, date, 0)} end)
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

  defp build_workflow_mix(triages, nurse_procedures, room_allocations) do
    [
      %{label: "Triages", count: length(triages)},
      %{label: "Procedures", count: length(nurse_procedures)},
      %{label: "Room Allocations", count: length(room_allocations)}
    ]
  end

  defp age_group_map(rows) do
    lookup = Map.new(rows, &{&1.label, &1.count})

    %{
      under_5: Map.get(lookup, "Under 5", 0),
      age_5_17: Map.get(lookup, "5 - 17", 0),
      age_18_59: Map.get(lookup, "18 - 59", 0),
      over_60: Map.get(lookup, "60+", 0)
    }
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

  defp filter_triage_search(triages, search) when search in [nil, ""], do: triages

  defp filter_triage_search(triages, search) do
    term = String.downcase(search)

    Enum.filter(triages, fn triage ->
      patient_text = searchable_patient_text(triage.patient)
      emergency_text = String.downcase(to_string(triage.emergency_scale || ""))

      String.contains?(patient_text, term) or String.contains?(emergency_text, term)
    end)
  end

  defp filter_patient_search(records, search) when search in [nil, ""], do: records

  defp filter_patient_search(records, search) do
    term = String.downcase(search)

    Enum.filter(records, fn record ->
      String.contains?(searchable_patient_text(record.patient), term)
    end)
  end

  defp filter_room_search(records, search) when search in [nil, ""], do: records

  defp filter_room_search(records, search) do
    term = String.downcase(search)

    Enum.filter(records, fn record ->
      patient_match = String.contains?(searchable_patient_text(record.patient), term)
      room_match = String.contains?(String.downcase(room_label(record.room)), term)
      patient_match or room_match
    end)
  end

  defp searchable_patient_text(nil), do: ""

  defp searchable_patient_text(patient) do
    [patient.first_name, patient.middle_name, patient.last_name, patient.email, patient.gsrn]
    |> Enum.reject(&is_nil_or_blank/1)
    |> Enum.join(" ")
    |> String.downcase()
  end

  defp room_label(%{room_number: room_number}) when is_binary(room_number), do: room_number
  defp room_label(_), do: ""

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

  defp date_in_range?(nil, _from, _to), do: false

  defp date_in_range?(date, from, to) do
    Date.compare(date, from) != :lt and Date.compare(date, to) != :gt
  end

  defp inserted_in_range?(nil, _from, _to), do: false

  defp inserted_in_range?(inserted_at, from, to),
    do: date_in_range?(DateTime.to_date(inserted_at), from, to)

  defp same_user?(nil, _user_id), do: false
  defp same_user?(user_id, current_user_id), do: user_id == current_user_id

  defp is_nil_or_blank(nil), do: true
  defp is_nil_or_blank(""), do: true
  defp is_nil_or_blank(_), do: false
end
