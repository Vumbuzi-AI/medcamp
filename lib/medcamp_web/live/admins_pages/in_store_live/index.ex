defmodule MedcampWeb.InStoreLive.Index do
  use MedcampWeb, :inventory_manager_live_view

  alias Medcamp.Batches
  alias Medcamp.ExpiryFilter

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    items = Batches.list_in_store()
    categories = extract_categories(items)

    {:ok,
     socket
     |> assign(:active_tab, :in_store)
     |> assign(:search, "")
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:all_items, items)
     |> assign(:categories, categories)
     |> assign(:filters, default_filters())
     |> apply_all_filters(default_filters(), "")}
  end

  defp default_filters,
    do: %{status: "", category: "", expiry_status: "", expiry_from: "", expiry_to: ""}

  @impl true
  def handle_params(_params, _url, socket), do: {:noreply, socket}

  @impl true
  def handle_event("search", %{"search" => query}, socket) do
    {:noreply,
     socket
     |> assign(:page, 1)
     |> apply_all_filters(socket.assigns.filters, query)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    page_num =
      case Integer.parse(page) do
        {i, _} -> max(1, i)
        :error -> 1
      end

    {:noreply,
     socket
     |> assign(:page, page_num)
     |> apply_all_filters(socket.assigns.filters, socket.assigns.search)}
  end

  @impl true
  def handle_event("filter", %{"filters" => filter_params}, socket) do
    new_filters = %{
      status: filter_params["status"] || "",
      category: filter_params["category"] || "",
      expiry_status: ExpiryFilter.normalize(filter_params["expiry_status"]),
      expiry_from: filter_params["expiry_from"] || "",
      expiry_to: filter_params["expiry_to"] || ""
    }

    {:noreply,
     socket
     |> assign(:page, 1)
     |> apply_all_filters(new_filters, socket.assigns.search)}
  end

  @impl true
  def handle_event("clear_all", _, socket) do
    {:noreply,
     socket
     |> assign(:page, 1)
     |> apply_all_filters(default_filters(), "")}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    current = %{
      "status" => socket.assigns.filters.status,
      "category" => socket.assigns.filters.category,
      "expiry_status" => socket.assigns.filters.expiry_status,
      "expiry_from" => socket.assigns.filters.expiry_from,
      "expiry_to" => socket.assigns.filters.expiry_to
    }

    filter_params = Map.put(current, field, "")
    handle_event("filter", %{"filters" => filter_params}, socket)
  end

  defp extract_categories(items) do
    items
    |> Enum.map(fn %{ir: ir} -> ir.category || ir.type end)
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp apply_all_filters(socket, filters, search) do
    filtered = apply_filters(socket.assigns.all_items, search, filters)

    total_count = length(filtered)
    total_pages = max(1, Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page))
    page = min(max(1, socket.assigns.page || 1), total_pages)

    page_items =
      Enum.slice(filtered, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(items: page_items, search: search, filters: filters)
  end

  defp apply_filters(items, search, filters) do
    items
    |> filter_by_search(search)
    |> filter_by_status(filters[:status] || "")
    |> filter_by_category(filters[:category] || "")
    |> filter_by_expiry(filters)
  end

  defp filter_by_search(items, search) do
    q = String.trim(search) |> String.downcase()

    if q == "" do
      items
    else
      Enum.filter(items, fn %{ir: ir} ->
        String.contains?(String.downcase(ir.brand_name || ""), q) ||
          String.contains?(String.downcase(ir.generic_name || ""), q) ||
          String.contains?(String.downcase(ir.gtin || ""), q) ||
          String.contains?(String.downcase(ir.category || ""), q)
      end)
    end
  end

  defp filter_by_status(items, ""), do: items

  defp filter_by_status(items, status) do
    Enum.filter(items, fn %{total_remaining: remaining} ->
      case status do
        "low_stock" -> remaining > 0 and remaining < 10
        "in_stock" -> remaining >= 10
        _ -> true
      end
    end)
  end

  defp filter_by_category(items, ""), do: items

  defp filter_by_category(items, category) do
    Enum.filter(items, fn %{ir: ir} ->
      (ir.category || ir.type) == category
    end)
  end

  # An item's expiry is its earliest-expiring batch, so "Expiring in 30 days"
  # here means the item has stock going out of date within 30 days.
  defp filter_by_expiry(items, filters) do
    status = filters[:expiry_status] || ""
    from = filters[:expiry_from] || ""
    to = filters[:expiry_to] || ""

    if status == "" and from == "" and to == "" do
      items
    else
      Enum.filter(items, fn %{earliest_expiry: expiry} ->
        ExpiryFilter.matches?(expiry, status, from, to)
      end)
    end
  end

  defp count_active_filters(filters) do
    Enum.count(
      [
        filters.status,
        filters.category,
        filters.expiry_status,
        filters.expiry_from,
        filters.expiry_to
      ],
      &(&1 != "")
    )
  end

  defp filter_chips(filters) do
    [
      filter_chip(filters.status, "status", status_label(filters.status)),
      filter_chip(filters.category, "category", filters.category),
      filter_chip(
        filters.expiry_status,
        "expiry_status",
        "Expiry: #{ExpiryFilter.label(filters.expiry_status)}"
      ),
      filter_chip(filters.expiry_from, "expiry_from", "Expiry from #{filters.expiry_from}"),
      filter_chip(filters.expiry_to, "expiry_to", "Expiry to #{filters.expiry_to}")
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp status_label("low_stock"), do: "Low Stock"
  defp status_label("in_stock"), do: "In Stock"
  defp status_label(other), do: other

  defp stock_status(0), do: {"Out of Stock", "bg-red-100 text-red-700"}
  defp stock_status(qty) when qty < 10, do: {"Low Stock", "bg-amber-100 text-amber-700"}
  defp stock_status(_), do: {"In Stock", "bg-emerald-100 text-emerald-700"}

  defp safe_parse_date(nil), do: :error
  defp safe_parse_date(""), do: :error
  defp safe_parse_date(%Date{} = d), do: {:ok, d}
  defp safe_parse_date(str) when is_binary(str), do: Date.from_iso8601(str)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.page_header
        icon_path="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
        title="In Store"
        subtitle="Current inventory with remaining stock per item."
      >
        <:actions>
          <span class="inline-flex items-center rounded-full bg-emerald-50 px-3 py-1 text-sm font-medium text-emerald-700">
            {@total_count} item{if @total_count != 1, do: "s", else: ""}
          </span>
        </:actions>
      </.page_header>

      <div class="flex flex-wrap items-center gap-3 mb-4">
        <form phx-change="search" class="flex-1">
          <.search_input
            name="search"
            value={@search}
            placeholder="Search by brand name, generic name, GTIN or category"
          />
        </form>

        <.filter_drawer
          id="in-store-filters"
          title="Filter in-store items"
          apply_event="filter"
          clear_event="clear_all"
          active_count={count_active_filters(@filters)}
        >
          <:group label="Status">
            <select
              name="filters[status]"
              class="col-span-2 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
            >
              <option value="" selected={@filters.status == ""}>All</option>
              <option value="low_stock" selected={@filters.status == "low_stock"}>
                Low Stock
              </option>
              <option value="in_stock" selected={@filters.status == "in_stock"}>In Stock</option>
            </select>
          </:group>

          <:group label="Category">
            <select
              name="filters[category]"
              class="col-span-2 block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-[#6667ab] focus:ring-[#6667ab]"
            >
              <option value="" selected={@filters.category == ""}>All</option>
              <option :for={cat <- @categories} value={cat} selected={@filters.category == cat}>
                {cat}
              </option>
            </select>
          </:group>

          <:group label="Expiry">
            <.expiry_filter_fields
              status_value={@filters.expiry_status}
              status_label="Expiry (earliest batch)"
              from_value={@filters.expiry_from}
              to_value={@filters.expiry_to}
            />
          </:group>

          <:chip
            :for={chip <- filter_chips(@filters)}
            label={chip.label}
            clear={JS.push("clear_chip", value: %{"field" => chip.field})}
          />
        </.filter_drawer>
      </div>

      <.blank_state
        :if={Enum.empty?(@items)}
        icon_path="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
        title="No items in store"
      >
        <:description_slot>
          <%= if @search != "" do %>
            No results for "{@search}".
          <% else %>
            Receive inventory to see items here.
          <% end %>
        </:description_slot>
        <:actions :if={@search != "" or count_active_filters(@filters) > 0}>
          <button phx-click="clear_all" class="text-xs text-[#6667ab] hover:underline">
            Clear filters
          </button>
        </:actions>
      </.blank_state>

      <%= if @items != [] do %>
        <div class="overflow-x-auto -mx-4">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Item
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  GTIN
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Category
                </th>
                <th class="px-6 py-3 text-center text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Batches
                </th>
                <th class="px-6 py-3 text-center text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Remaining Qty
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Earliest Expiry
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-500">
                  Status
                </th>
                <th class="px-6 py-3"></th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 bg-white">
              <%= for %{ir: ir, total_remaining: remaining, batch_count: batches, earliest_expiry: expiry} <- @items do %>
                <% {status_label, status_class} = stock_status(remaining) %>
                <tr
                  class="hover:bg-gray-50 transition-colors cursor-pointer"
                  phx-click={JS.navigate("/inventory_manager/in_store/#{ir.id}")}
                >
                  <td class="px-6 py-4">
                    <p class="font-semibold text-gray-900 text-sm">{ir.brand_name}</p>
                    <%= if ir.generic_name do %>
                      <p class="text-xs text-gray-500 italic mt-0.5">{ir.generic_name}</p>
                    <% end %>
                    <%= if ir.strength do %>
                      <p class="text-xs text-gray-400 mt-0.5">{ir.strength}</p>
                    <% end %>
                  </td>
                  <td class="px-6 py-4">
                    <span class="font-mono text-xs text-gray-600">{ir.gtin || "—"}</span>
                  </td>
                  <td class="px-6 py-4">
                    <span class="inline-flex items-center rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-700">
                      {ir.category || ir.type || "—"}
                    </span>
                  </td>
                  <td class="px-6 py-4 text-center">
                    <span class="inline-flex items-center rounded-full bg-blue-50 px-2.5 py-0.5 text-xs font-semibold text-blue-700">
                      {batches}
                    </span>
                  </td>
                  <td class="px-6 py-4 text-center">
                    <span class={"text-lg font-bold tabular-nums #{if remaining <= 0, do: "text-red-600", else: if(remaining < 10, do: "text-amber-600", else: "text-emerald-700")}"}>
                      {remaining}
                    </span>
                    <%= if ir.uom do %>
                      <span class="ml-1 text-xs text-gray-400">{ir.uom}</span>
                    <% end %>
                  </td>
                  <td class="px-6 py-4 text-sm text-gray-600">
                    <%= case safe_parse_date(expiry) do %>
                      <% {:ok, exp_date} -> %>
                        <span class={
                          if Date.compare(exp_date, Date.utc_today()) == :lt,
                            do: "text-red-600 font-medium",
                            else: ""
                        }>
                          {Calendar.strftime(exp_date, "%d %b %Y")}
                        </span>
                      <% _ -> %>
                        <span class="text-gray-400">{expiry || "—"}</span>
                    <% end %>
                  </td>
                  <td class="px-6 py-4">
                    <span class={"inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-semibold #{status_class}"}>
                      {status_label}
                    </span>
                  </td>
                  <td class="px-6 py-4 text-right">
                    <.link
                      navigate={"/inventory_manager/in_store/#{ir.id}"}
                      class="inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1.5 text-sm font-medium text-emerald-600 hover:bg-emerald-50 transition-colors"
                    >
                      <Heroicons.icon name="eye" type="outline" class="h-4 w-4" /> Batches
                    </.link>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
          class="px-6 pb-4"
        />
      <% end %>
    </div>
    """
  end
end
