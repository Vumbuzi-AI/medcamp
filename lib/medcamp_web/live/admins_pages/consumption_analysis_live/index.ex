defmodule MedcampWeb.AdminConsumptionAnalysisLive.Index do
  @moduledoc """
  Admin view of consumption analysis (pharmaceuticals and non-pharmaceuticals).
  """
  use MedcampWeb, :admin_live_view

  @impl true
  def mount(_params, _session, socket) do
    today = Date.utc_today()
    month_start = Date.beginning_of_month(today)

    {:ok,
     socket
     |> assign(:active_tab, :consumption_analysis)
     |> assign(:page_title, "Consumption Analysis")
     |> assign(:period, "monthly")
     |> assign(:category, "both")
     |> assign(:anchor_date, today |> Date.to_string())
     |> assign(:date_from, month_start |> Date.to_string())
     |> assign(:date_to, today |> Date.to_string())
     |> assign(:search, "")
     |> assign(:results, [])
     |> assign(:period_options, Medcamp.ConsumptionAnalysis.periods())
     |> assign(:category_options, Medcamp.ConsumptionAnalysis.categories())
     |> load_results()}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  defp load_results(socket) do
    opts = [
      period: socket.assigns.period,
      category: socket.assigns.category,
      date: parse_date(socket.assigns.anchor_date),
      date_from: parse_date(socket.assigns.date_from),
      date_to: parse_date(socket.assigns.date_to),
      search: socket.assigns.search
    ]

    results = Medcamp.ConsumptionAnalysis.consumption_analysis(opts)
    assign(socket, :results, results)
  end

  defp parse_date(nil), do: Date.utc_today()
  defp parse_date(""), do: Date.utc_today()

  defp parse_date(s) when is_binary(s) do
    case Date.from_iso8601(s) do
      {:ok, d} -> d
      _ -> Date.utc_today()
    end
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Falling back to the current assign for an absent key means a search-only
  # change doesn't reset the period/category/date fields, and vice versa.
  @impl true
  def handle_event("filter", params, socket) do
    {:noreply,
     socket
     |> assign(:period, params["period"] || socket.assigns.period)
     |> assign(:category, params["category"] || socket.assigns.category)
     |> assign(:anchor_date, params["anchor_date"] || socket.assigns.anchor_date)
     |> assign(:date_from, params["date_from"] || socket.assigns.date_from)
     |> assign(:date_to, params["date_to"] || socket.assigns.date_to)
     |> assign(:search, params["search"] || socket.assigns.search)
     |> load_results()}
  end

  @impl true
  def handle_event("clear_search", _, socket) do
    {:noreply,
     socket
     |> assign(:search, "")
     |> load_results()}
  end

  @impl true
  def handle_event("clear_filters", _, socket) do
    today = Date.utc_today()
    month_start = Date.beginning_of_month(today)

    {:noreply,
     socket
     |> assign(:period, "monthly")
     |> assign(:category, "both")
     |> assign(:anchor_date, Date.to_string(today))
     |> assign(:date_from, Date.to_string(month_start))
     |> assign(:date_to, Date.to_string(today))
     |> load_results()}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => "period"}, socket) do
    handle_event("filter", %{"period" => "monthly"}, socket)
  end

  def handle_event("clear_chip", %{"field" => "category"}, socket) do
    handle_event("filter", %{"category" => "both"}, socket)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.page_header
        icon_path="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
        title="Consumption Analysis"
        subtitle="Live report controls — every change updates results instantly."
      />

      <div class="flex flex-wrap items-center gap-3 mb-4">
        <form phx-change="filter" class="flex-1">
          <.search_input
            name="search"
            value={@search}
            placeholder="Search by brand, generic name, or GTIN"
          />
        </form>

        <.filter_drawer
          id="consumption-analysis-filters-admin"
          title="Report Settings"
          apply_event="filter"
          clear_event="clear_filters"
          instant={true}
          active_count={count_active_filters(assigns)}
        >
          <:group label="Report Period">
            <select
              name="period"
              class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
            >
              <%= for p <- @period_options do %>
                <option value={p} selected={@period == p}>{format_period(p)}</option>
              <% end %>
            </select>
            <select
              name="category"
              class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
            >
              <%= for c <- @category_options do %>
                <option value={c} selected={@category == c}>{format_category(c)}</option>
              <% end %>
            </select>
          </:group>

          <:group label="Date">
            <%= if @period == "custom" do %>
              <div>
                <label class="mb-1 block text-xs font-medium text-gray-600">From</label>
                <input
                  type="date"
                  name="date_from"
                  value={@date_from}
                  class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
                />
              </div>
              <div>
                <label class="mb-1 block text-xs font-medium text-gray-600">To</label>
                <input
                  type="date"
                  name="date_to"
                  value={@date_to}
                  class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
                />
              </div>
            <% else %>
              <div class={if @period == "all_time", do: "col-span-2 opacity-40 pointer-events-none"}>
                <label class="mb-1 block text-xs font-medium text-gray-600">
                  Anchor Date
                  <%= if @period == "all_time" do %>
                    <span class="text-gray-400 font-normal">(ignored for All Time)</span>
                  <% end %>
                </label>
                <input
                  type="date"
                  name="anchor_date"
                  value={@anchor_date}
                  class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
                />
              </div>
            <% end %>
          </:group>

          <:chip
            :for={chip <- filter_chips(assigns)}
            label={chip.label}
            clear={JS.push("clear_chip", value: %{"field" => chip.field})}
          />
        </.filter_drawer>
      </div>

      <%!-- Summary stats bar --%>
      <%= if not Enum.empty?(@results) do %>
        <div class="flex flex-wrap gap-4 mb-4">
          <div class="flex items-center gap-2 px-4 py-2 bg-brand-50 border border-brand-100 rounded-lg">
            <span class="text-xs text-gray-500 font-medium">Distinct items</span>
            <span class="text-lg font-bold text-brand-primary">{length(@results)}</span>
          </div>
          <div class="flex items-center gap-2 px-4 py-2 bg-brand-50 border border-brand-100 rounded-lg">
            <span class="text-xs text-gray-500 font-medium">Total qty consumed</span>
            <span class="text-lg font-bold text-brand-primary">
              {@results |> Enum.map(& &1.total_quantity) |> Enum.sum()}
            </span>
          </div>
          <%= if show_sales_data?(@category) do %>
            <div class="flex items-center gap-2 px-4 py-2 bg-emerald-50 border border-emerald-200 rounded-lg">
              <span class="text-xs text-emerald-700 font-medium">Total sold value</span>
              <span class="text-lg font-bold text-emerald-800">
                {money(total_sold_amount(@results))}
              </span>
            </div>
          <% end %>
          <%= if @search != "" do %>
            <div class="flex items-center gap-2 px-4 py-2 bg-amber-50 border border-amber-200 rounded-lg">
              <svg
                class="h-4 w-4 text-amber-500"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                />
              </svg>
              <span class="text-xs text-amber-700">
                Filtered by "<strong>{@search}</strong>"
              </span>
              <button
                phx-click="clear_search"
                class="text-amber-600 hover:text-amber-800 text-xs underline ml-1"
              >
                Clear
              </button>
            </div>
          <% end %>
        </div>
      <% end %>

      <%= if Enum.empty?(@results) do %>
        <.blank_state
          icon_path="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"
          title="No consumption data"
        >
          <:description_slot>
            <%= if @search != "" do %>
              No results for "<strong>{@search}</strong>" in the selected period.
              <button phx-click="clear_search" class="ml-1 text-brand-accent underline">
                Clear search
              </button>
            <% else %>
              No records found for the selected period and category.
            <% end %>
          </:description_slot>
        </.blank_state>
      <% else %>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Rank
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Brand Name
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Generic Name
                </th>
                <th class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  GTIN
                </th>
                <th class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Qty Consumed
                </th>
                <th
                  :if={show_sales_data?(@category)}
                  class="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Sold For
                </th>
                <th
                  :if={@category == "both"}
                  class="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                >
                  Category
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-gray-200">
              <%= for {item, idx} <- Enum.with_index(@results, 1) do %>
                <tr class={if rem(idx, 2) == 0, do: "bg-gray-50", else: "bg-white"}>
                  <td class="px-4 py-3 text-sm text-gray-900">
                    <span class="px-2 py-0.5 rounded-full bg-brand-100 text-brand-primary font-medium">
                      {item.rank}
                    </span>
                  </td>
                  <td class="px-4 py-3 text-sm font-medium text-gray-900">
                    {highlight_match(item.brand_name, @search)}
                  </td>
                  <td class="px-4 py-3 text-sm text-gray-600">
                    {highlight_match(item.generic_name, @search)}
                  </td>
                  <td class="px-4 py-3 text-sm text-gray-500 font-mono">
                    {item.gtin || "—"}
                  </td>
                  <td class="px-4 py-3 text-sm text-gray-900 text-right font-semibold">
                    {item.total_quantity}
                  </td>
                  <td :if={show_sales_data?(@category)} class="px-4 py-3 text-sm text-right">
                    <%= if is_nil(item.total_sold_amount) do %>
                      <span class="text-gray-400">—</span>
                    <% else %>
                      <div class="font-semibold text-gray-900">{money(item.total_sold_amount)}</div>
                      <div class="text-xs text-gray-500">
                        Avg {money(item.average_unit_price)} / unit
                      </div>
                    <% end %>
                  </td>
                  <td :if={@category == "both"} class="px-4 py-3 text-sm">
                    <span class={category_badge_class(item.category)}>
                      {format_category_atom(item.category)}
                    </span>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      <% end %>
    </div>
    """
  end

  defp highlight_match(nil, _search), do: "—"
  defp highlight_match(text, ""), do: text

  defp highlight_match(text, search) do
    if String.contains?(String.downcase(text), String.downcase(search)) do
      Phoenix.HTML.raw(
        String.replace(
          text,
          ~r/#{Regex.escape(search)}/i,
          "<mark class=\"bg-yellow-200 rounded px-0.5\">\\0</mark>"
        )
      )
    else
      text
    end
  end

  defp format_period("all_time"), do: "All Time"
  defp format_period("weekly"), do: "Weekly"
  defp format_period("monthly"), do: "Monthly"
  defp format_period("quarterly"), do: "Quarterly"
  defp format_period("yearly"), do: "Yearly"
  defp format_period("custom"), do: "Custom Range"
  defp format_period(p), do: p

  defp format_category("pharmaceuticals"), do: "Pharmaceuticals"
  defp format_category("non_pharmaceuticals"), do: "Non-pharmaceuticals"
  defp format_category("both"), do: "Both"
  defp format_category(c), do: c

  defp format_category_atom(:pharmaceuticals), do: "Pharmaceuticals"
  defp format_category_atom(:non_pharmaceuticals), do: "Non-pharmaceuticals"
  defp format_category_atom(:both), do: "Combined"
  defp format_category_atom(_), do: ""

  defp category_badge_class(:pharmaceuticals),
    do: "px-2 py-0.5 text-xs rounded-full bg-blue-100 text-blue-800"

  defp category_badge_class(:non_pharmaceuticals),
    do: "px-2 py-0.5 text-xs rounded-full bg-green-100 text-green-800"

  defp category_badge_class(_),
    do: "px-2 py-0.5 text-xs rounded-full bg-gray-100 text-gray-800"

  defp show_sales_data?(category), do: category in ["pharmaceuticals", "both"]

  defp total_sold_amount(results) do
    Enum.reduce(results, 0, fn item, acc -> acc + (item.total_sold_amount || 0) end)
  end

  defp money(amount) when is_integer(amount),
    do: "KES " <> Number.Delimit.number_to_delimited(amount, precision: 0)

  defp money(amount) when is_float(amount) do
    precision = if amount == Float.round(amount, 0), do: 0, else: 2
    "KES " <> Number.Delimit.number_to_delimited(amount, precision: precision)
  end

  defp money(_), do: "KES 0"

  defp count_active_filters(assigns) do
    [assigns.period != "monthly", assigns.category != "both"]
    |> Enum.count(& &1)
  end

  defp filter_chips(assigns) do
    [
      filter_chip(assigns.period, "period", format_period(assigns.period), ["monthly"]),
      filter_chip(assigns.category, "category", format_category(assigns.category), ["both"])
    ]
    |> Enum.reject(&is_nil/1)
  end
end
