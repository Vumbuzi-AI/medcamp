defmodule MedcampWeb.InventoryReceivedLive.Index do
  use MedcampWeb, :inventory_manager_live_view

  alias Medcamp.ExpiryFilter
  alias Medcamp.InventoriesReceived
  alias Medcamp.InventoriesReceived.InventoryReceived
  alias Medcamp.Rooms

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :inventories_received)
     |> assign(:filters, default_filters())
     |> assign(:rooms_for_select, Rooms.list_rooms_for_select())
     |> assign(:categories, InventoriesReceived.list_categories_for_selection())
     |> assign(:types, InventoriesReceived.list_types_for_selection())
     |> assign(:suppliers, InventoriesReceived.list_suppliers_for_selection())
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign(:inventories_received, [])}
  end

  defp default_filters do
    %{
      item_search: "",
      category: "",
      supplier: "",
      type: "",
      room_id: "",
      expiry_status: "",
      expiry_from: "",
      expiry_to: ""
    }
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Inventory received")
    |> assign(:inventory_received, InventoriesReceived.get_inventory_received!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Inventory received")
    |> assign(:inventory_received, %InventoryReceived{})
  end

  defp apply_action(socket, :index, params) do
    filters = filters_from_params(params)
    page = parse_page(params["page"])

    filter_params = %{
      "item_search" => filters.item_search,
      "category" => filters.category,
      "supplier" => filters.supplier,
      "type" => filters.type,
      "room_id" => filters.room_id,
      "expiry_status" => filters.expiry_status,
      "expiry_from" => filters.expiry_from,
      "expiry_to" => filters.expiry_to
    }

    total_count = InventoriesReceived.count_inventories_received(filter_params)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(max(1, page), total_pages)

    inventories_received =
      InventoriesReceived.list_inventories_received_paginated(filter_params, page, @per_page)

    socket
    |> assign(:page_title, "Inventories Received")
    |> assign(:inventory_received, nil)
    |> assign(:filters, filters)
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:inventories_received, inventories_received)
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

  defp filters_from_params(params) do
    %{
      item_search: params["item_search"] || "",
      category: params["category"] || "",
      supplier: params["supplier"] || "",
      type: params["type"] || "",
      room_id: params["room_id"] || "",
      expiry_status: ExpiryFilter.normalize(params["expiry_status"]),
      expiry_from: params["expiry_from"] || "",
      expiry_to: params["expiry_to"] || ""
    }
  end

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

    {:noreply,
     push_patch(socket, to: "/inventory_manager/inventories_received?" <> URI.encode_query(q))}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply, push_patch(socket, to: "/inventory_manager/inventories_received?page=1")}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    handle_event("filter", %{"filters" => %{field => ""}}, socket)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    inventory_received = InventoriesReceived.get_inventory_received!(id)
    {:ok, _} = InventoriesReceived.delete_inventory_received(inventory_received)

    q =
      filters_to_query(socket.assigns.filters) |> Map.put("page", to_string(socket.assigns.page))

    {:noreply,
     push_patch(socket, to: "/inventory_manager/inventories_received?" <> URI.encode_query(q))}
  end

  defp filters_to_query(filters) when is_map(filters) do
    %{}
    |> maybe_put("item_search", filters[:item_search] || filters["item_search"])
    |> maybe_put("category", filters[:category] || filters["category"])
    |> maybe_put("supplier", filters[:supplier] || filters["supplier"])
    |> maybe_put("type", filters[:type] || filters["type"])
    |> maybe_put("room_id", filters[:room_id] || filters["room_id"])
    |> maybe_put("expiry_status", filters[:expiry_status] || filters["expiry_status"])
    |> maybe_put("expiry_from", filters[:expiry_from] || filters["expiry_from"])
    |> maybe_put("expiry_to", filters[:expiry_to] || filters["expiry_to"])
  end

  defp filters_to_query(_), do: %{}

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, val), do: Map.put(map, key, to_string(val))

  defp pagination_path(filters, page) do
    filters_to_query(filters)
    |> Map.put("page", to_string(page))
    |> then(&("/inventory_manager/inventories_received?" <> URI.encode_query(&1)))
  end

  defp count_active_filters(filters) do
    filters
    |> Map.drop([:item_search])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters, rooms) do
    [
      filter_chip(filters[:category], "category", filters[:category]),
      filter_chip(filters[:supplier], "supplier", filters[:supplier]),
      filter_chip(filters[:type], "type", filters[:type]),
      filter_chip(filters[:room_id], "room_id", room_name(filters[:room_id], rooms)),
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

  defp room_name(id, rooms) do
    case Enum.find(rooms, fn {_name, rid} -> to_string(rid) == to_string(id) end) do
      {name, _id} -> name
      nil -> id
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.page_header
        icon_path="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"
        title="Inventories Received"
        subtitle="Search, filter and manage received inventory."
      >
        <:actions>
          <.link patch={~p"/inventory_manager/inventories_received/new"}>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">
              <div class="flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-2"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4v16m8-8H4"
                  />
                </svg>
                Receive Inventory
              </div>
            </.button>
          </.link>
        </:actions>
      </.page_header>

      <div class="flex flex-wrap items-center gap-3 mb-4">
        <form phx-change="filter" class="flex-1">
          <.search_input
            name="filters[item_search]"
            value={@filters[:item_search]}
            placeholder="Search by brand, generic name, or GTIN"
          />
        </form>

        <.filter_drawer
          id="inventories-received-filters"
          title="Filter inventories received"
          apply_event="filter"
          clear_event="clear_filters"
          active_count={count_active_filters(@filters)}
        >
          <:group label="Category and Supplier">
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Category</label>
              <select
                name="filters[category]"
                class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
              >
                <option value="" selected={@filters[:category] in [nil, ""]}>All</option>
                <option
                  :for={category <- @categories}
                  value={category}
                  selected={@filters[:category] == category}
                >
                  {category}
                </option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Supplier</label>
              <select
                name="filters[supplier]"
                class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
              >
                <option value="" selected={@filters[:supplier] in [nil, ""]}>All</option>
                <option
                  :for={supplier <- @suppliers}
                  value={supplier}
                  selected={@filters[:supplier] == supplier}
                >
                  {supplier}
                </option>
              </select>
            </div>
          </:group>

          <:group label="Type and Room">
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Type</label>
              <select
                name="filters[type]"
                class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
              >
                <option value="" selected={@filters[:type] in [nil, ""]}>All</option>
                <option :for={type <- @types} value={type} selected={@filters[:type] == type}>
                  {type}
                </option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Room</label>
              <select
                name="filters[room_id]"
                class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
              >
                <option value="">All rooms</option>
                <%= for {name, id} <- @rooms_for_select do %>
                  <option value={id} selected={@filters[:room_id] == to_string(id)}>{name}</option>
                <% end %>
              </select>
            </div>
          </:group>

          <:group label="Expiry">
            <.expiry_filter_fields
              status_value={@filters[:expiry_status]}
              status_label="Batch expiry"
              from_value={@filters[:expiry_from]}
              to_value={@filters[:expiry_to]}
            />
          </:group>

          <:chip
            :for={chip <- filter_chips(@filters, @rooms_for_select)}
            label={chip.label}
            clear={JS.push("clear_chip", value: %{"field" => chip.field})}
          />
        </.filter_drawer>
      </div>

      <%= if Enum.empty?(@inventories_received) do %>
        <.blank_state
          icon_path="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"
          title="No inventories received"
          description={
            if @filters[:item_search] != "" or count_active_filters(@filters) > 0,
              do: "No inventory items match the current filters.",
              else: "Get started by adding received inventory items."
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
          id="inventories_received"
          rows={@inventories_received}
          row_id={fn ir -> "inventory-received-#{ir.id}" end}
          row_item={fn ir -> {ir.id, ir} end}
          row_click={
            fn inventory_received ->
              JS.navigate(~p"/inventory_manager/inventories_received/#{inventory_received}")
            end
          }
        >
          <:col :let={{_id, inventory_received}} label="Brand Name">
            <div class="flex flex-col items-start py-3">
              <span class="font-medium  bg-[#6667ab] text-white p-2 rounded-xl">
                {inventory_received.gtin || "N/A"}
              </span>
              <span class="font-medium text-gray-900">
                {inventory_received.brand_name}
              </span>
            </div>
          </:col>

          <:col :let={{_id, inventory_received}} label="Generic Name">
            <div class="flex items-center py-3">
              <span class="text-gray-700">
                {inventory_received.generic_name}
              </span>
            </div>
          </:col>

          <:col :let={{_id, inventory_received}} label="Category">
            <div class="flex items-center py-3">
              <span class="text-gray-700">
                {inventory_received.category}
              </span>
            </div>
          </:col>

          <:action :let={{_id, inventory_received}}>
            <div class="flex items-center justify-center">
              <.link
                navigate={~p"/inventory_manager/inventories_received/#{inventory_received}"}
                class="flex items-center text-[#6667ab] hover:text-[#373896]"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-1"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"
                  />
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z"
                  />
                </svg>
                View Details
              </.link>
            </div>
          </:action>

          <:action :let={{_id, inventory_received}}>
            <div class="flex items-center justify-center">
              <.link
                patch={~p"/inventory_manager/inventories_received/#{inventory_received}/edit"}
                class="flex items-center text-[#6667ab] hover:text-[#373896]"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-1"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                  />
                </svg>
                Edit
              </.link>
            </div>
          </:action>

          <:action :let={{_id, inventory_received}}>
            <div class="flex items-center justify-center">
              <.link
                phx-click={
                  JS.push("delete", value: %{id: inventory_received.id})
                  |> hide("#inventory-received-#{inventory_received.id}")
                }
                data-confirm="Are you sure?"
                class="flex items-center text-red-600 hover:text-red-800"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-1"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                  />
                </svg>
                Delete
              </.link>
            </div>
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

      <.modal
        :if={@live_action in [:new, :edit]}
        id="inventory_received-modal"
        show
        on_cancel={JS.patch(~p"/inventory_manager/inventories_received")}
      >
        <.live_component
          module={MedcampWeb.InventoryReceivedLive.FormComponent}
          id={@inventory_received.id || :new}
          title={@page_title}
          action={@live_action}
          current_user={@current_user}
          inventory_received={@inventory_received}
          patch={~p"/inventory_manager/inventories_received"}
        />
      </.modal>
    </div>
    """
  end
end
