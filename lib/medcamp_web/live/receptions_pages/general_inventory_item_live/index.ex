defmodule MedcampWeb.GeneralInventoryItemLive.Index do
  use MedcampWeb, :reception_live_view

  alias Medcamp.Inventories
  alias Medcamp.Inventories.GeneralInventoryItem

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :general_inventory)
     |> assign(:stock_filter, :all)
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> update_filtered_items()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit General Inventory Item")
    |> assign(:general_inventory_item, Inventories.get_general_inventory_item!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New General Inventory Item")
    |> assign(:general_inventory_item, %GeneralInventoryItem{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "General Inventory Items")
    |> assign(:general_inventory_item, nil)
  end

  @impl true
  def handle_info(
        {MedcampWeb.GeneralInventoryItemLive.FormComponent, {:saved, _general_inventory_item}},
        socket
      ) do
    {:noreply, update_filtered_items(socket)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    general_inventory_item = Inventories.get_general_inventory_item!(id)
    {:ok, _} = Inventories.delete_general_inventory_item(general_inventory_item)

    {:noreply, update_filtered_items(socket)}
  end

  def handle_event("search_general_inventory", %{"search" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search_query, query)
     |> assign(:page, 1)
     |> update_filtered_items()}
  end

  def handle_event("filter_stock_status", %{"filters" => %{"status" => status}}, socket) do
    filter = String.to_existing_atom(status)

    {:noreply,
     socket
     |> assign(:stock_filter, filter)
     |> assign(:page, 1)
     |> update_filtered_items()}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> update_filtered_items()}
  end

  def handle_event("clear_stock_filter", _params, socket) do
    {:noreply,
     socket
     |> assign(:stock_filter, :all)
     |> update_filtered_items()}
  end

  defp count_active_filters(assigns) do
    [assigns.stock_filter != :all] |> Enum.count(& &1)
  end

  defp stock_filter_label(:in_stock), do: "In Stock"
  defp stock_filter_label(:low_stock), do: "Low Stock"
  defp stock_filter_label(:out_of_stock), do: "Out of Stock"
  defp stock_filter_label(other), do: to_string(other)

  defp update_filtered_items(socket) do
    items =
      if socket.assigns.search_query != "" do
        Inventories.search_general_inventory_items(socket.assigns.search_query)
      else
        Inventories.list_general_inventory_items()
      end

    filtered_items = filter_by_stock_status(items, socket.assigns.stock_filter)

    total_count = length(filtered_items)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    page_items =
      Enum.slice(filtered_items, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:stock_counts, get_stock_counts(items))
    |> assign(:general_inventory_items, page_items)
  end

  defp filter_by_stock_status(items, :all), do: items

  defp filter_by_stock_status(items, filter) do
    Enum.filter(items, fn item ->
      {status, _label} = stock_status(item)
      status == filter
    end)
  end

  defp stock_status(item) do
    cond do
      Decimal.compare(item.current_quantity, Decimal.new(0)) == :lt or
          Decimal.compare(item.current_quantity, Decimal.new(0)) == :eq ->
        {:out_of_stock, "Out of Stock"}

      Decimal.compare(item.current_quantity, item.reorder_level) == :lt ->
        {:low_stock, "Low Stock"}

      true ->
        {:in_stock, "In Stock"}
    end
  end

  defp get_stock_counts(items) do
    Enum.reduce(items, %{all: 0, in_stock: 0, low_stock: 0, out_of_stock: 0}, fn item, acc ->
      {status, _label} = stock_status(item)

      acc
      |> Map.update!(:all, &(&1 + 1))
      |> Map.update!(status, &(&1 + 1))
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-4">
        <div class="flex items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-[#6667ab]"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
            />
          </svg>
          General Inventory Items
        </div>
        <:actions>
          <.link patch={~p"/reception/general_inventory/new"}>
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
                New Item
              </div>
            </.button>
          </.link>
        </:actions>
      </.header>
      
    <!-- Search Bar -->
      <form phx-change="search_general_inventory" class="mb-4">
        <input
          name="search"
          type="text"
          value={@search_query}
          class="mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6 border-gray-300"
          placeholder="Search by Name, Category, or Supplier"
        />
      </form>
      
    <!-- Stock Status Filter -->
      <div class="mb-6">
        <.filter_drawer
          id="general-inventory-filters"
          title="Filter inventory items"
          apply_event="filter_stock_status"
          clear_event="clear_stock_filter"
          active_count={count_active_filters(assigns)}
        >
          <:group label="Stock Status">
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Stock Status</label>
              <select
                name="filters[status]"
                class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
              >
                <option value="all" selected={@stock_filter == :all}>
                  All Items ({@stock_counts.all})
                </option>
                <option value="in_stock" selected={@stock_filter == :in_stock}>
                  In Stock ({@stock_counts.in_stock})
                </option>
                <option value="low_stock" selected={@stock_filter == :low_stock}>
                  Low Stock ({@stock_counts.low_stock})
                </option>
                <option value="out_of_stock" selected={@stock_filter == :out_of_stock}>
                  Out of Stock ({@stock_counts.out_of_stock})
                </option>
              </select>
            </div>
          </:group>

          <:chip
            :if={@stock_filter != :all}
            label={stock_filter_label(@stock_filter)}
            clear="clear_stock_filter"
          />
        </.filter_drawer>
      </div>

      <%= if @total_count == 0 do %>
        <div class="text-center py-8 bg-gray-50 rounded-lg border border-dashed border-gray-300 mt-4">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">
            <%= case @stock_filter do %>
              <% :all -> %>
                No inventory items
              <% :in_stock -> %>
                No items in stock
              <% :low_stock -> %>
                No items with low stock
              <% :out_of_stock -> %>
                No items out of stock
            <% end %>
          </h3>
          <p class="mt-1 text-sm text-gray-500">
            <%= if @stock_filter == :all do %>
              Get started by adding your first inventory item.
            <% else %>
              Try selecting a different filter or adjusting your search.
            <% end %>
          </p>
        </div>
      <% else %>
        <.table
          id="general_inventory_items"
          rows={@general_inventory_items}
          row_click={
            fn general_inventory_item ->
              JS.navigate(~p"/reception/general_inventory/#{general_inventory_item}")
            end
          }
          row_id={&"general_inventory_items-#{&1.id}"}
        >
          <:col :let={item} label="Item Details">
            <div class="flex flex-col items-start py-3">
              <span class="font-medium text-gray-900 text-base">
                {item.name}
              </span>
              <span class="text-sm text-gray-600">
                {item.category}
              </span>
              <span class="text-sm text-gray-600">
                {item.gtin || "N/A"}
              </span>
            </div>
          </:col>

          <:col :let={item} label="Current Stock">
            <div class="flex flex-col items-start py-3">
              <span class="font-semibold text-lg text-gray-900">
                {item.current_quantity} {item.unit_of_measure}
              </span>
              <span class="text-xs text-gray-500">
                Reorder at: {item.reorder_level} {item.unit_of_measure}
              </span>
            </div>
          </:col>

          <:col :let={item} label="Status">
            <div class="flex items-center py-3">
              <%= case stock_status(item) do %>
                <% {:out_of_stock, label} -> %>
                  <span class="px-3 py-1 text-xs font-medium rounded-full bg-red-100 text-red-800">
                    {label}
                  </span>
                <% {:low_stock, label} -> %>
                  <span class="px-3 py-1 text-xs font-medium rounded-full bg-yellow-100 text-yellow-800">
                    {label}
                  </span>
                <% {:in_stock, label} -> %>
                  <span class="px-3 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">
                    {label}
                  </span>
              <% end %>
            </div>
          </:col>

          <:col :let={item} label="Unit Cost">
            <div class="flex items-center py-3">
              <span class="text-gray-700 font-medium">
                KES {Number.Delimit.number_to_delimited(item.unit_cost, precision: 2)}
              </span>
            </div>
          </:col>

          <:col :let={item} label="Supplier">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-[#f0f0ff] text-[#373896]">
                {item.supplier || "N/A"}
              </span>
            </div>
          </:col>

          <:col :let={item} label="Date Received">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-[#f0f0ff] text-[#373896]">
                {item.date_received || "N/A"}
              </span>
            </div>
          </:col>

          <:action :let={item}>
            <div class="flex items-center justify-center">
              <.link
                navigate={~p"/reception/general_inventory/#{item}"}
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
                    d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
                  />
                </svg>
                Transactions
              </.link>
            </div>
          </:action>

          <:action :let={item}>
            <div class="flex items-center justify-center">
              <.link
                patch={~p"/reception/general_inventory/#{item}/edit"}
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

          <:action :let={item}>
            <div class="flex items-center justify-center">
              <.link
                phx-click={JS.push("delete", value: %{id: item.id}) |> hide("#general_inventory_items-#{item.id}")}
                data-confirm="Are you sure you want to delete this item and all its transactions?"
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
        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      <% end %>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="general_inventory_item-modal"
        show
        on_cancel={JS.patch(~p"/reception/general_inventory")}
      >
        <.live_component
          module={MedcampWeb.GeneralInventoryItemLive.FormComponent}
          id={@general_inventory_item.id || :new}
          title={@page_title}
          action={@live_action}
          current_user={@current_user}
          general_inventory_item={@general_inventory_item}
          patch={~p"/reception/general_inventory"}
        />
      </.modal>
    </div>
    """
  end
end
