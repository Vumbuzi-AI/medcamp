defmodule MedcampWeb.AllBatchesLive.Index do
  use MedcampWeb, :inventory_manager_live_view

  alias Medcamp.Batches
  alias Medcamp.ExpiryFilter
  alias Medcamp.Suppliers

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :all_batches)
     |> assign(:filters, default_filters())
     |> assign(:suppliers, Suppliers.list_suppliers_for_selection())
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign(:batches, [])}
  end

  defp default_filters do
    %{
      item_search: "",
      supplier_id: "",
      expiry_status: "",
      expiry_from: "",
      expiry_to: ""
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, params) do
    filters = filters_from_params(params)
    page = parse_page(params["page"])

    filter_params = %{
      "item_search" => filters.item_search,
      "supplier_id" => filters.supplier_id,
      "expiry_status" => filters.expiry_status,
      "expiry_from" => filters.expiry_from,
      "expiry_to" => filters.expiry_to
    }

    total_count = Batches.count_batches(filter_params)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(max(1, page), total_pages)

    batches = Batches.list_batches_paginated(filter_params, page, @per_page)

    socket
    |> assign(:page_title, "All Batches")
    |> assign(:filters, filters)
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:batches, batches)
  end

  defp filters_from_params(params) do
    %{
      item_search: params["item_search"] || "",
      supplier_id: params["supplier_id"] || "",
      expiry_status: ExpiryFilter.normalize(params["expiry_status"]),
      expiry_from: params["expiry_from"] || "",
      expiry_to: params["expiry_to"] || ""
    }
  end

  defp parse_page(nil), do: 1
  defp parse_page(""), do: 1

  defp parse_page(s) when is_binary(s) do
    case Integer.parse(s) do
      {n, _} -> max(1, n)
      _ -> 1
    end
  end

  defp parse_page(n) when is_integer(n), do: max(1, n)
  defp parse_page(_), do: 1

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto a stringified version of the current filters means a key
  # absent from this submission is left unchanged rather than reset — this
  # also keeps the push_patch URL below reflecting the complete filter set.
  defp stringify_filters(filters) do
    Map.new(filters, fn {key, value} -> {Atom.to_string(key), value || ""} end)
  end

  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    filters = Map.merge(stringify_filters(socket.assigns.filters), filters)
    q = filters_to_query(filters) |> Map.put("page", "1")
    {:noreply, push_patch(socket, to: "/inventory_manager/batches?" <> URI.encode_query(q))}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: "/inventory_manager/batches?page=1")}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    handle_event("filter", %{"filters" => %{field => ""}}, socket)
  end

  defp filters_to_query(filters) when is_map(filters) do
    %{}
    |> maybe_put("item_search", filters[:item_search] || filters["item_search"])
    |> maybe_put("supplier_id", filters[:supplier_id] || filters["supplier_id"])
    |> maybe_put("expiry_status", filters[:expiry_status] || filters["expiry_status"])
    |> maybe_put("expiry_from", filters[:expiry_from] || filters["expiry_from"])
    |> maybe_put("expiry_to", filters[:expiry_to] || filters["expiry_to"])
  end

  defp filters_to_query(_), do: %{}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, val), do: Map.put(map, key, to_string(val))

  defp count_active_filters(filters) do
    filters
    |> Map.drop([:item_search])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters, suppliers) do
    [
      filter_chip(
        filters[:supplier_id],
        "supplier_id",
        supplier_name(filters[:supplier_id], suppliers)
      ),
      filter_chip(
        filters[:expiry_status],
        "expiry_status",
        "Expiry: #{ExpiryFilter.label(filters[:expiry_status])}"
      ),
      filter_chip(filters[:expiry_from], "expiry_from", "Expiry from #{filters[:expiry_from]}"),
      filter_chip(filters[:expiry_to], "expiry_to", "Expiry to #{filters[:expiry_to]}")
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp supplier_name(id, suppliers) do
    case Enum.find(suppliers, fn {_name, sid} -> to_string(sid) == to_string(id) end) do
      {name, _id} -> name
      nil -> id
    end
  end

  def pagination_path(filters, page) do
    filters_to_query(filters)
    |> Map.put("page", to_string(page))
    |> then(&("/inventory_manager/batches?" <> URI.encode_query(&1)))
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.page_header
        icon_path="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
        title="All Batches"
        subtitle="Search, filter and manage stock batches."
      />

      <div class="flex flex-wrap items-center gap-3 mb-4">
        <form phx-change="filter" class="flex-1">
          <.search_input
            name="filters[item_search]"
            value={@filters[:item_search]}
            placeholder="Search by GTIN, batch, or product"
          />
        </form>

        <.filter_drawer
          id="all-batches-filters"
          title="Filter batches"
          apply_event="filter"
          clear_event="clear_filters"
          active_count={count_active_filters(@filters)}
        >
          <:group label="Supplier">
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Supplier</label>
              <select
                name="filters[supplier_id]"
                class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
              >
                <option value="">All suppliers</option>
                <%= for {name, id} <- @suppliers do %>
                  <option value={id} selected={@filters[:supplier_id] == to_string(id)}>
                    {name}
                  </option>
                <% end %>
              </select>
            </div>
          </:group>

          <:group label="Expiry">
            <.expiry_filter_fields
              status_value={@filters[:expiry_status]}
              from_value={@filters[:expiry_from]}
              to_value={@filters[:expiry_to]}
            />
          </:group>

          <:chip
            :for={chip <- filter_chips(@filters, @suppliers)}
            label={chip.label}
            clear={JS.push("clear_chip", value: %{"field" => chip.field})}
          />
        </.filter_drawer>
      </div>

      <%= if Enum.empty?(@batches) do %>
        <.blank_state
          icon_path="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
          title="No batches found"
          description={
            if @filters[:item_search] != "" or count_active_filters(@filters) > 0,
              do: "No batches match the current filters.",
              else: "No batches have been added yet — add one from an inventory received item."
          }
        >
          <:actions :if={@filters[:item_search] != "" or count_active_filters(@filters) > 0}>
            <button phx-click="clear_filters" class="text-xs text-[#6667ab] hover:underline">
              Clear filters
            </button>
          </:actions>
        </.blank_state>
      <% else %>
        <.table
          id="all_batches"
          rows={@batches}
          row_id={fn b -> "batch-#{b.id}" end}
          row_item={fn b -> {b.id, b} end}
        >
          <:col :let={{_id, batch}} label="GTIN">
            <span class="font-mono text-sm">
              {batch.gtin || (batch.inventory_received && batch.inventory_received.gtin) || "—"}
            </span>
          </:col>
          <:col :let={{_id, batch}} label="Batch">
            <.link
              navigate={~p"/inventory_manager/batches/#{batch.id}"}
              class="px-2 py-1 text-xs font-semibold rounded-full bg-[#f0f0ff] text-[#373896] hover:bg-[#e0e0ff] transition-colors"
            >
              {batch.batch || "—"}
            </.link>
          </:col>
          <:col :let={{_id, batch}} label="Product">
            <%= if batch.inventory_received do %>
              <span class="text-gray-700">
                {batch.inventory_received.brand_name || batch.inventory_received.generic_name || "—"}
              </span>
            <% else %>
              —
            <% end %>
          </:col>
          <:col :let={{_id, batch}} label="Added At">
            <div class="flex items-center py-3">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1 text-[#6667ab]"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"
                />
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"
                />
              </svg>
              <span class="text-gray-700">
                {batch.inserted_at &&
                  Timex.format!(
                    Timex.shift(batch.inserted_at, hours: 3),
                    "%b %d, %Y %H:%M",
                    :strftime
                  )}
              </span>
            </div>
          </:col>
          <:col :let={{_id, batch}} label="Supplier">
            <%= if batch.supplier do %>
              <span class="text-gray-700">{batch.supplier.name}</span>
            <% else %>
              —
            <% end %>
          </:col>
          <:col :let={{_id, batch}} label="Expiry">{batch.expiry || "—"}</:col>
          <:col :let={{_id, batch}} label="Remaining">
            <span class="font-medium">{batch.remaining_quantity || 0}</span>
          </:col>
          <:col :let={{_id, batch}} label="Quantity">{batch.quantity || 0}</:col>
          <:action :let={{_id, batch}}>
            <.link
              navigate={~p"/inventory_manager/batches/#{batch.id}"}
              class="text-[#6667ab] hover:text-[#373896] text-sm font-semibold"
            >
              View details
            </.link>
          </:action>
        </.table>

        <%= if @total_pages > 1 do %>
          <div class="mt-4 flex items-center justify-between border-t border-gray-200 pt-4">
            <p class="text-sm text-gray-700">
              Showing {min((@page - 1) * @per_page + 1, @total_count)}–{min(
                @page * @per_page,
                @total_count
              )} of {@total_count}
            </p>
            <div class="flex gap-2">
              <.link
                :if={@page > 1}
                patch={pagination_path(@filters, @page - 1)}
                class="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Previous
              </.link>
              <span class="rounded-md border border-gray-200 bg-gray-50 px-3 py-1.5 text-sm text-gray-700">
                Page {@page} of {@total_pages}
              </span>
              <.link
                :if={@page < @total_pages}
                patch={pagination_path(@filters, @page + 1)}
                class="rounded-md border border-gray-300 bg-white px-3 py-1.5 text-sm font-medium text-gray-700 hover:bg-gray-50"
              >
                Next
              </.link>
            </div>
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end
end
