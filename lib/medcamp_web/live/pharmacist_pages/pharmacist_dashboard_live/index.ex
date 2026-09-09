defmodule MedcampWeb.PharmacistDashboardLive.Index do
  use MedcampWeb, :pharmacist_live_view

  alias Medcamp.DrugAllocations
  alias Medcamp.Drugs
  alias Medcamp.DrugsGiven
  alias Medcamp.StockAlerts
  alias MedcampWeb.Dashboards.WidgetResolver

  @role "pharmacist"

  @impl true
  def mount(_params, _session, socket) do
    today = today_eat()
    {date_from, date_to} = period_to_range(:this_month, today)

    {:ok,
     socket
     |> assign(:active_tab, :dashboard)
     |> assign(:page_title, "Pharmacy Dashboard")
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

  @impl true
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

  @impl true
  def handle_event("search", %{"search" => %{"term" => term}}, socket) do
    {:noreply,
     socket
     |> assign(:search, term)
     |> load_data()}
  end

  @impl true
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

    allocations =
      DrugAllocations.list_drug_allocations()
      |> Enum.filter(&inserted_in_range?(&1.inserted_at, date_from, date_to))
      |> filter_pharmacy_search(search)

    drugs = Drugs.list_drugs() |> filter_drugs(search)

    dispensed_drugs =
      DrugsGiven.list_drugs_given()
      |> Enum.filter(&inserted_in_range?(&1.inserted_at, date_from, date_to))
      |> filter_dispensed_drugs(search)

    low_stock_items =
      StockAlerts.list_below_reorder_items()
      |> Enum.filter(&(&1.type == :drug))

    stock = stock_totals(drugs)

    socket
    |> assign(:allocations, allocations)
    |> assign(:drugs, drugs)
    |> assign(:dispensed_drugs, dispensed_drugs)
    |> assign(:low_stock_items, low_stock_items)
    |> assign(:stock_units, stock.units)
    |> assign(:stock_value, stock.value)
    |> assign(:dispensed_units, sum_field(dispensed_drugs, :quantity))
    |> assign(:dispensed_value, sum_field(dispensed_drugs, :price))
    |> assign(:daily_dispensing, build_daily_dispensing(dispensed_drugs, date_from, date_to))
    |> assign(:allocation_status_breakdown, build_status_breakdown(allocations))
    |> assign(:top_drug_usage, build_drug_breakdown(dispensed_drugs, :quantity))
    |> assign(:dispensed_value_breakdown, build_drug_breakdown(dispensed_drugs, :price))
    |> assign(:stock_value_breakdown, build_stock_value_breakdown(drugs))
    |> assign(:low_stock_breakdown, build_low_stock_breakdown(low_stock_items))
    |> assign(:recent_items, recent_allocation_items(allocations))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-slate-50 -m-4 sm:-m-6 p-4 sm:p-6">
      <div class="space-y-6">
        <.dashboard_top_card
          title="Pharmacy Dashboard"
          subtitle={"Dispensing activity and stock pressure for #{format_date(@date_from)} to #{format_date(@date_to)}"}
          search_name="search[term]"
          search_value={@search}
          search_placeholder="Search patients, prescriptions or drugs..."
          filter_id="pharmacy-dashboard-filters"
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
          subtitle="Drug usage, dispensing value, allocation status, and current stock pressure"
        >
          <div class="grid grid-cols-1 xl:grid-cols-2 gap-6">
            <.chart_panel
              title="Daily Units Dispensed"
              subtitle="Number of drug units issued each day in the selected period."
              config={daily_registrations_chart(@daily_dispensing)}
              height="320px"
            />
            <.chart_panel
              title="Top Drugs by Usage"
              subtitle="Highest-volume drugs ranked by units dispensed."
              config={revenue_by_reason_chart(@top_drug_usage)}
              height="320px"
            />
            <.chart_panel
              title="Dispensed Value by Drug"
              subtitle="Value of drugs issued in the selected period."
              config={revenue_by_reason_chart(@dispensed_value_breakdown)}
              height="320px"
            />
            <.chart_panel
              title="Current Stock Value by Drug"
              subtitle="Retail value of available stock, ranked by drug."
              config={revenue_by_reason_chart(@stock_value_breakdown)}
              height="320px"
            />
            <.chart_panel
              title="Allocation Status"
              subtitle="Completed versus pending dispensing work."
              config={visit_type_chart(@allocation_status_breakdown)}
              height="320px"
            />
            <.chart_panel
              title="Low Stock Pressure"
              subtitle="Drugs below reorder level, ranked by shortage gap."
              config={revenue_by_reason_chart(@low_stock_breakdown)}
              height="320px"
            />
          </div>
        </.analytics_section>

        <.recent_items
          title="Recent Drug Allocations"
          items={@recent_items}
          empty_message="No drug allocations match the selected period and search."
        />
      </div>
    </div>
    """
  end

  defp dashboard_cards(assigns) do
    summary_cards_for(assigns.visible_summary_cards, %{
      drug_catalog: {length(assigns.drugs), "Drugs matching the current view"},
      pharmacy_stock_units: {format_number(assigns.stock_units), "Available units"},
      pharmacy_stock_value: {format_money(assigns.stock_value), "Retail value of stock on hand"},
      drug_allocations:
        {length(assigns.allocations), "Allocations created in the selected period"},
      dispensed_units:
        {format_number(assigns.dispensed_units), "Units issued in the selected period"},
      dispensed_value:
        {format_money(assigns.dispensed_value), "Value issued in the selected period"},
      pending_drug_allocations: {count_pending(assigns.allocations), "Still awaiting assignment"},
      low_stock_items: {length(assigns.low_stock_items), "Drugs below reorder level"}
    })
  end

  defp count_assigned(allocations), do: Enum.count(allocations, & &1.has_been_assigned)
  defp count_pending(allocations), do: Enum.count(allocations, &(!&1.has_been_assigned))

  defp build_daily_dispensing(dispensed_drugs, date_from, date_to) do
    counts =
      Enum.reduce(dispensed_drugs, %{}, fn drug_given, acc ->
        date = DateTime.to_date(drug_given.inserted_at)
        Map.update(acc, date, drug_given.quantity || 0, &(&1 + (drug_given.quantity || 0)))
      end)

    chart_dates(counts, date_from, date_to)
    |> Enum.map(fn date -> %{date: date, count: Map.get(counts, date, 0)} end)
  end

  defp build_status_breakdown(allocations) do
    [
      %{label: "Assigned", count: count_assigned(allocations)},
      %{label: "Pending", count: count_pending(allocations)}
    ]
  end

  defp build_drug_breakdown(dispensed_drugs, field) do
    dispensed_drugs
    |> Enum.group_by(&drug_name(&1.drug))
    |> Enum.map(fn {label, rows} -> %{label: label, total: sum_field(rows, field)} end)
    |> Enum.reject(&(&1.total <= 0))
    |> Enum.sort_by(& &1.total, :desc)
    |> Enum.take(8)
  end

  defp build_stock_value_breakdown(drugs) do
    drugs
    |> Enum.map(fn drug -> %{label: drug_name(drug), total: stock_totals([drug]).value} end)
    |> Enum.reject(&(&1.total <= 0))
    |> Enum.sort_by(& &1.total, :desc)
    |> Enum.take(8)
  end

  defp build_low_stock_breakdown(items) do
    items
    |> Enum.map(fn item ->
      current_quantity = Map.get(item, :current_quantity, 0) || 0
      reorder_level = Map.get(item, :reorder_level, 0) || 0

      %{
        label: item.item_name || "Unknown item",
        total: max(reorder_level - current_quantity, 0)
      }
    end)
    |> Enum.reject(&(&1.total <= 0))
    |> Enum.sort_by(& &1.total, :desc)
    |> Enum.take(6)
  end

  defp stock_totals(drugs) do
    Enum.reduce(drugs, %{units: 0, value: 0}, fn drug, totals ->
      Enum.reduce(drug.drug_batches || [], totals, fn drug_batch, acc ->
        if available_batch?(drug_batch) do
          quantity = drug_batch.remaining_quantity || 0
          unit_price = (drug_batch.batch && drug_batch.batch.price_per_unit) || 0

          %{units: acc.units + quantity, value: acc.value + quantity * unit_price}
        else
          acc
        end
      end)
    end)
  end

  defp available_batch?(batch) do
    batch.is_active != false and
      (batch.remaining_quantity || 0) > 0
  end

  defp sum_field(rows, field), do: Enum.sum(Enum.map(rows, &(Map.get(&1, field) || 0)))

  defp chart_dates(counts, date_from, date_to) do
    if Date.diff(date_to, date_from) <= 120 do
      Enum.to_list(Date.range(date_from, date_to))
    else
      counts
      |> Map.keys()
      |> Enum.sort(Date)
      |> case do
        [] -> Enum.uniq([date_from, date_to])
        dates -> dates
      end
    end
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
          do: "bg-brand-primary text-white",
          else: "bg-slate-100 text-slate-600 hover:bg-slate-200"
        )
      ]}
    >
      {@label}
    </button>
    """
  end

  defp filter_pharmacy_search(allocations, search) when search in [nil, ""], do: allocations

  defp filter_pharmacy_search(allocations, search) do
    term = String.downcase(search)

    Enum.filter(allocations, fn allocation ->
      searchable_fields = [
        searchable_patient_text(allocation.patient),
        allocation.prescription,
        allocation.payment_type,
        allocation.insurance_name,
        assigned_drug_text(allocation.drugs_assigned)
      ]

      Enum.any?(searchable_fields, fn value ->
        value
        |> to_string_or_blank()
        |> String.downcase()
        |> String.contains?(term)
      end)
    end)
  end

  defp filter_drugs(drugs, search) when search in [nil, ""], do: drugs

  defp filter_drugs(drugs, search) do
    term = search |> String.trim() |> String.downcase()

    Enum.filter(drugs, fn drug ->
      drug
      |> drug_search_text()
      |> String.downcase()
      |> String.contains?(term)
    end)
  end

  defp filter_dispensed_drugs(rows, search) when search in [nil, ""], do: rows

  defp filter_dispensed_drugs(rows, search) do
    term = search |> String.trim() |> String.downcase()

    Enum.filter(rows, fn drug_given ->
      allocation = drug_given.drug_allocation

      [
        drug_search_text(drug_given.drug),
        allocation && allocation.prescription,
        allocation && allocation.payment_type,
        allocation && allocation.insurance_name
      ]
      |> Enum.map(&to_string_or_blank/1)
      |> Enum.any?(&(String.downcase(&1) |> String.contains?(term)))
    end)
  end

  defp assigned_drug_text(drugs_assigned) when is_list(drugs_assigned) do
    drugs_assigned
    |> Enum.flat_map(&[&1.brand_name, &1.generic_name])
    |> Enum.reject(&is_nil_or_blank/1)
    |> Enum.join(" ")
  end

  defp assigned_drug_text(_), do: ""

  defp drug_search_text(nil), do: ""

  defp drug_search_text(drug) do
    inventory_received = Map.get(drug, :inventory_received)

    [
      Map.get(drug, :brand_name),
      Map.get(drug, :generic_name),
      loaded_field(inventory_received, :brand_name),
      loaded_field(inventory_received, :generic_name),
      loaded_field(inventory_received, :gtin)
    ]
    |> Enum.reject(&is_nil_or_blank/1)
    |> Enum.join(" ")
  end

  defp drug_name(nil), do: "Unknown drug"

  defp drug_name(drug) do
    inventory_received = Map.get(drug, :inventory_received)

    Map.get(drug, :brand_name) ||
      loaded_field(inventory_received, :brand_name) ||
      Map.get(drug, :generic_name) ||
      loaded_field(inventory_received, :generic_name) ||
      "Unknown drug"
  end

  defp loaded_field(%Ecto.Association.NotLoaded{}, _field), do: nil
  defp loaded_field(nil, _field), do: nil
  defp loaded_field(value, field), do: Map.get(value, field)

  defp recent_allocation_items(allocations) do
    allocations
    |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
    |> Enum.take(6)
    |> Enum.map(fn allocation ->
      %{
        title: patient_name(allocation.patient),
        subtitle: allocation.prescription || assigned_drug_text(allocation.drugs_assigned),
        badge: if(allocation.has_been_assigned, do: "Completed", else: "Pending"),
        badge_color:
          if(allocation.has_been_assigned,
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
    |> case do
      "" -> "Patient"
      name -> name
    end
  end

  defp searchable_patient_text(nil), do: ""

  defp searchable_patient_text(patient) do
    [patient.first_name, patient.middle_name, patient.last_name, patient.email, patient.gsrn]
    |> Enum.reject(&is_nil_or_blank/1)
    |> Enum.join(" ")
  end

  defp to_string_or_blank(nil), do: ""
  defp to_string_or_blank(value), do: to_string(value)

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

  defp format_number(value),
    do: Number.Delimit.number_to_delimited(value || 0, precision: 0)

  defp format_money(value), do: "KES #{format_number(value)}"

  defp inserted_in_range?(nil, _from, _to), do: false

  defp inserted_in_range?(inserted_at, from, to) do
    date = DateTime.to_date(inserted_at)
    Date.compare(date, from) != :lt and Date.compare(date, to) != :gt
  end

  defp is_nil_or_blank(nil), do: true
  defp is_nil_or_blank(""), do: true
  defp is_nil_or_blank(_), do: false
end
