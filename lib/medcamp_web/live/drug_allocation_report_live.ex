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
      <.page_header
        icon_path="M19.428 15.428a8 8 0 11-11.314-11.314 8 8 0 0111.314 11.314zM8.586 8.586l6.828 6.828"
        title="Drug Allocations"
        subtitle="Issued drug quantities by received-inventory category, such as Antibiotics."
      />

      <form
        id="drug-allocation-report-filters"
        phx-change="filter"
        phx-submit="filter"
        class="rounded-lg border border-gray-200 bg-white p-4 shadow-sm"
      >
        <div class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-6">
          <div class="xl:col-span-2">
            <label for="drug-allocation-search" class="mb-1 block text-xs font-medium text-gray-600">
              Drug
            </label>
            <input
              id="drug-allocation-search"
              type="search"
              name="search"
              value={@search}
              placeholder="Brand, generic name, or GTIN"
              phx-debounce="300"
              class="h-10 w-full rounded-md border border-gray-300 px-3 text-sm focus:border-brand-accent focus:ring-brand-accent"
            />
          </div>

          <div>
            <label for="drug-allocation-category" class="mb-1 block text-xs font-medium text-gray-600">
              Inventory Category
            </label>
            <select
              id="drug-allocation-category"
              name="category"
              class="h-10 w-full rounded-md border border-gray-300 px-3 text-sm focus:border-brand-accent focus:ring-brand-accent"
            >
              <option value="">All categories</option>
              <option :for={option <- @category_options} value={option} selected={@category == option}>
                {option}
              </option>
            </select>
          </div>

          <div>
            <label for="drug-allocation-type" class="mb-1 block text-xs font-medium text-gray-600">
              Product Type
            </label>
            <select
              id="drug-allocation-type"
              name="inventory_type"
              class="h-10 w-full rounded-md border border-gray-300 px-3 text-sm focus:border-brand-accent focus:ring-brand-accent"
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

          <div>
            <label for="drug-allocation-from" class="mb-1 block text-xs font-medium text-gray-600">
              Issued From
            </label>
            <input
              id="drug-allocation-from"
              type="date"
              name="date_from"
              value={@date_from}
              class="h-10 w-full rounded-md border border-gray-300 px-3 text-sm focus:border-brand-accent focus:ring-brand-accent"
            />
          </div>

          <div>
            <label for="drug-allocation-to" class="mb-1 block text-xs font-medium text-gray-600">
              Issued To
            </label>
            <div class="flex gap-2">
              <input
                id="drug-allocation-to"
                type="date"
                name="date_to"
                value={@date_to}
                class="h-10 min-w-0 flex-1 rounded-md border border-gray-300 px-3 text-sm focus:border-brand-accent focus:ring-brand-accent"
              />
              <button
                type="button"
                phx-click="reset_filters"
                class="h-10 rounded-md border border-gray-300 px-3 text-sm text-gray-600 hover:bg-gray-50"
              >
                Reset
              </button>
            </div>
          </div>
        </div>
      </form>

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <.report_stat_card label="Total units issued" value={@total_issued} />
        <.report_stat_card label="Drug items issued" value={length(@rows)} />
        <.report_stat_card label="Issue records" value={@total_issue_count} />
      </div>

      <section class="overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm">
        <div class="border-b border-gray-200 px-4 py-3">
          <h2 class="font-semibold text-gray-900">Issued by Inventory Category</h2>
          <p class="mt-1 text-sm text-gray-500">
            Category totals use the classification saved when each inventory item was received.
          </p>
        </div>

        <div :if={@category_summary != []} class="overflow-x-auto">
          <table id="drug-allocation-category-summary" class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <.heading>Category</.heading>
                <.heading align="right">Units Issued</.heading>
                <.heading align="right">Drug Items</.heading>
                <.heading align="right">Issue Records</.heading>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr :for={summary <- @category_summary}>
                <td class="px-4 py-3 text-sm font-medium text-gray-900">{summary.category}</td>
                <td class="px-4 py-3 text-right text-sm font-bold text-brand-primary">
                  {summary.issued_quantity}
                </td>
                <td class="px-4 py-3 text-right text-sm text-gray-700">{summary.item_count}</td>
                <td class="px-4 py-3 text-right text-sm text-gray-700">{summary.issue_count}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div :if={@category_summary == []} class="px-4 py-10 text-center text-sm text-gray-500">
          No issued drugs match the selected filters.
        </div>
      </section>

      <section class="overflow-hidden rounded-lg border border-gray-200 bg-white shadow-sm">
        <div class="border-b border-gray-200 px-4 py-3">
          <h2 class="font-semibold text-gray-900">Issued Drug Details</h2>
        </div>

        <div :if={@rows != []} class="overflow-x-auto">
          <table id="issued-drug-details" class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <.heading>Drug</.heading>
                <.heading>Category</.heading>
                <.heading>Product Type</.heading>
                <.heading>GTIN</.heading>
                <.heading align="right">Units Issued</.heading>
                <.heading align="right">Allocations</.heading>
                <.heading>Last Issued</.heading>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr :for={row <- @rows} id={"issued-drug-#{row.inventory_received_id}"}>
                <td class="px-4 py-3 text-sm">
                  <p class="font-medium text-gray-900">{present(row.brand_name)}</p>
                  <p class="text-xs text-gray-500">{present(row.generic_name)}</p>
                </td>
                <td class="px-4 py-3 text-sm text-gray-700">{classification(row)}</td>
                <td class="px-4 py-3 text-sm text-gray-700">{present(row.inventory_type)}</td>
                <td class="px-4 py-3 font-mono text-xs text-gray-600">{present(row.gtin)}</td>
                <td class="px-4 py-3 text-right text-sm font-bold text-brand-primary">
                  {row.issued_quantity} {row.unit_of_measurement || "units"}
                </td>
                <td class="px-4 py-3 text-right text-sm text-gray-700">{row.allocation_count}</td>
                <td class="whitespace-nowrap px-4 py-3 text-sm text-gray-600">
                  {format_datetime(row.last_issued_at)}
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div :if={@rows == []} class="px-4 py-10 text-center text-sm text-gray-500">
          No drugs have been issued for this period and classification.
        </div>
      </section>
    </div>
    """
  end

  attr :label, :string, required: true
  attr :value, :any, required: true

  defp report_stat_card(assigns) do
    ~H"""
    <div class="rounded-lg border border-brand-100 bg-brand-50 p-4">
      <p class="text-xs font-medium uppercase tracking-wide text-gray-500">{@label}</p>
      <p class="mt-1 text-2xl font-bold text-brand-primary">{@value}</p>
    </div>
    """
  end

  attr :align, :string, default: "left"
  slot :inner_block, required: true

  defp heading(assigns) do
    ~H"""
    <th class={[
      "px-4 py-3 text-xs font-medium uppercase tracking-wider text-gray-500",
      @align == "right" && "text-right",
      @align != "right" && "text-left"
    ]}>
      {render_slot(@inner_block)}
    </th>
    """
  end

  defp present(value) when value in [nil, ""], do: "—"
  defp present(value), do: value

  defp format_datetime(nil), do: "—"
  defp format_datetime(datetime), do: Calendar.strftime(datetime, "%d %b %Y, %H:%M")
end
