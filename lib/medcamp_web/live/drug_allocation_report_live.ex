defmodule MedcampWeb.DrugAllocationReportLive do
  @moduledoc false
  use MedcampWeb, :html

  alias Medcamp.DrugAllocations
  alias Medcamp.InventoriesReceived
  alias Phoenix.LiveView.Socket

  def mount(%Socket{} = socket) do
    today = Date.utc_today()

    socket =
      socket
      |> assign(:active_tab, :drug_allocation_report)
      |> assign(:page_title, "Drug Allocation Report")
      |> assign(:search, "")
      |> assign(:category, "")
      |> assign(:inventory_type, "")
      |> assign(:date_from, Date.to_string(Date.beginning_of_month(today)))
      |> assign(:date_to, Date.to_string(today))
      |> assign(:category_options, InventoriesReceived.list_categories_for_selection())
      |> assign(:inventory_type_options, InventoriesReceived.list_types_for_selection())

    {:ok, load_report(socket)}
  end

  def handle_event("filter", params, %Socket{} = socket) do
    {:noreply,
     socket
     |> assign(:search, params["search"] || socket.assigns.search)
     |> assign(:category, params["category"] || socket.assigns.category)
     |> assign(:inventory_type, params["inventory_type"] || socket.assigns.inventory_type)
     |> assign(:date_from, params["date_from"] || socket.assigns.date_from)
     |> assign(:date_to, params["date_to"] || socket.assigns.date_to)
     |> load_report()}
  end

  def handle_event("reset_filters", _params, %Socket{} = socket) do
    today = Date.utc_today()

    {:noreply,
     socket
     |> assign(:search, "")
     |> assign(:category, "")
     |> assign(:inventory_type, "")
     |> assign(:date_from, Date.to_string(Date.beginning_of_month(today)))
     |> assign(:date_to, Date.to_string(today))
     |> load_report()}
  end

  defp load_report(socket) do
    rows =
      DrugAllocations.issued_drug_report(%{
        search: socket.assigns.search,
        category: socket.assigns.category,
        inventory_type: socket.assigns.inventory_type,
        date_from: socket.assigns.date_from,
        date_to: socket.assigns.date_to
      })

    socket
    |> assign(:rows, rows)
    |> assign(:category_summary, summarize_categories(rows))
    |> assign(:total_issued, Enum.sum(Enum.map(rows, & &1.issued_quantity)))
    |> assign(:total_issue_count, Enum.sum(Enum.map(rows, & &1.issue_count)))
  end

  defp summarize_categories(rows) do
    rows
    |> Enum.group_by(&classification/1)
    |> Enum.map(fn {category, items} ->
      %{
        category: category,
        item_count: length(items),
        issued_quantity: Enum.sum(Enum.map(items, & &1.issued_quantity)),
        issue_count: Enum.sum(Enum.map(items, & &1.issue_count))
      }
    end)
    |> Enum.sort_by(& &1.issued_quantity, :desc)
  end

  defp classification(%{category: category}) when is_binary(category) and category != "",
    do: category

  defp classification(_row), do: "Unclassified"

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.dashboard_top_card
        title="Drug Allocations"
        subtitle="Issued drug quantities by received-inventory category, such as Antibiotics."
        search_name="search"
        search_value={@search}
        search_placeholder="Brand, generic name, or GTIN"
        search_event="filter"
        filter_id="drug-allocation-report-filters"
        filter_apply_event="filter"
        filter_clear_event="reset_filters"
        active_filter_count={active_filter_count(assigns)}
        camps={assigns[:camp_options] || []}
        camp_filter={assigns[:camp_filter]}
      >
        <:filter_group label="Classification">
          <div>
            <label
              for="drug-allocation-category"
              class="mb-1 block text-xs font-medium text-slate-600"
            >
              Inventory Category
            </label>
            <select
              id="drug-allocation-category"
              name="category"
              class="h-10 w-full rounded-md border border-slate-300 px-3 text-sm focus:border-brand-accent focus:ring-brand-accent"
            >
              <option value="">All categories</option>
              <option :for={option <- @category_options} value={option} selected={@category == option}>
                {option}
              </option>
            </select>
          </div>

          <div>
            <label for="drug-allocation-type" class="mb-1 block text-xs font-medium text-slate-600">
              Product Type
            </label>
            <select
              id="drug-allocation-type"
              name="inventory_type"
              class="h-10 w-full rounded-md border border-slate-300 px-3 text-sm focus:border-brand-accent focus:ring-brand-accent"
            >
              <option value="">All types</option>
              <option
                :for={option <- @inventory_type_options}
                value={option}
                selected={@inventory_type == option}
              >
                {option}
              </option>
            </select>
          </div>
        </:filter_group>
        <:filter_group label="Issued date">
          <.date_range_fields
            from_name="date_from"
            to_name="date_to"
            from_value={@date_from}
            to_value={@date_to}
            from_label="Issued From"
            to_label="Issued To"
          />
        </:filter_group>
      </.dashboard_top_card>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <.report_stat_card label="Total units issued" value={@total_issued} />
        <.report_stat_card label="Drug items issued" value={length(@rows)} />
        <.report_stat_card label="Issue records" value={@total_issue_count} />
      </div>

      <section class="space-y-3">
        <div>
          <h2 class="font-semibold text-slate-900">Issued by Inventory Category</h2>
          <p class="mt-1 text-sm text-slate-500">
            Category totals use the classification saved when each inventory item was received.
          </p>
        </div>

        <.data_table id="drug-allocation-category-summary" rows={@category_summary}>
          <:col :let={summary} label="Category" class="font-medium text-slate-900">
            {summary.category}
          </:col>
          <:col :let={summary} label="Units Issued" align="right" class="font-bold text-brand-primary">
            {summary.issued_quantity}
          </:col>
          <:col :let={summary} label="Drug Items" align="right">
            {summary.item_count}
          </:col>
          <:col :let={summary} label="Issue Records" align="right">
            {summary.issue_count}
          </:col>
          <:empty>
            No issued drugs match the selected filters.
          </:empty>
        </.data_table>
      </section>

      <section class="space-y-3">
        <div>
          <h2 class="font-semibold text-slate-900">Issued Drug Details</h2>
        </div>

        <.data_table
          id="issued-drug-details"
          rows={@rows}
          row_id={&"issued-drug-#{&1.inventory_received_id}"}
        >
          <:col :let={row} label="Drug">
            <p class="font-medium text-slate-900">{present(row.brand_name)}</p>
            <p class="text-xs text-slate-500">{present(row.generic_name)}</p>
          </:col>
          <:col :let={row} label="Category" hide_below="md">
            {classification(row)}
          </:col>
          <:col :let={row} label="Product Type" hide_below="md">
            {present(row.inventory_type)}
          </:col>
          <:col :let={row} label="GTIN" class="font-mono text-xs text-slate-600" hide_below="lg">
            {present(row.gtin)}
          </:col>
          <:col :let={row} label="Units Issued" align="right" class="font-bold text-brand-primary">
            {row.issued_quantity} {row.unit_of_measurement || "units"}
          </:col>
          <:col :let={row} label="Allocations" align="right" hide_below="sm">
            {row.allocation_count}
          </:col>
          <:col :let={row} label="Last Issued" hide_below="lg">
            {format_datetime(row.last_issued_at)}
          </:col>
          <:empty>
            No drugs have been issued for this period and classification.
          </:empty>
        </.data_table>
      </section>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true

  defp report_stat_card(assigns) do
    ~H"""
    <div class="rounded-2xl border border-slate-200 bg-white p-5">
      <p class="text-xs font-medium uppercase tracking-wide text-slate-500">{@label}</p>
      <p class="mt-2 text-2xl font-bold leading-none text-brand-primary">{@value}</p>
    </div>
    """
  end

  defp active_filter_count(assigns) do
    today = Date.utc_today()
    default_from = Date.to_string(Date.beginning_of_month(today))
    default_to = Date.to_string(today)

    [
      assigns.category != "",
      assigns.inventory_type != "",
      assigns.date_from != default_from,
      assigns.date_to != default_to
    ]
    |> Enum.count(& &1)
  end

  defp present(value) when value in [nil, ""], do: "—"
  defp present(value), do: value

  defp format_datetime(nil), do: "—"
  defp format_datetime(datetime), do: Calendar.strftime(datetime, "%d %b %Y, %H:%M")
end
