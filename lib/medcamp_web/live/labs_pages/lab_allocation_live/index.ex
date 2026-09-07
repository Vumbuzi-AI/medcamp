defmodule MedcampWeb.LabAllocationLive.Index do
  use MedcampWeb, :lab_live_view

  alias Medcamp.Batches
  alias Medcamp.LabAllocations
  alias Medcamp.LabAllocations.LabAllocation
  alias Medcamp.LabConsumables

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    allocations_with_consumption = get_allocations_with_consumption()

    {:ok,
     socket
     |> assign(:active_tab, :lab_allocations)
     |> assign(:show_gtin_scanner, false)
     |> assign(:gtin_search_query, "")
     |> assign(:gtin_search_results, [])
     |> assign(:gtin_searching, false)
     |> assign(:search, "")
     |> assign(:filter_status, "all")
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:all_allocations, allocations_with_consumption)
     |> apply_filters()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Lab allocation")
    |> assign(:lab_allocation, LabAllocations.get_lab_allocation!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Lab allocation")
    |> assign(:lab_allocation, %LabAllocation{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Lab allocations")
    |> assign(:lab_allocation, nil)
  end

  @impl true
  def handle_info({MedcampWeb.LabAllocationLive.FormComponent, {:saved, _lab_allocation}}, socket) do
    all = get_allocations_with_consumption()

    {:noreply,
     socket
     |> assign(:all_allocations, all)
     |> apply_filters()}
  end

  def handle_event("search", %{"search" => query}, socket) do
    q = String.trim(query)

    {:noreply,
     socket
     |> assign(:search, q)
     |> assign(:page, 1)
     |> apply_filters()}
  end

  def handle_event("filter_status", %{"status" => status}, socket) do
    {:noreply,
     socket
     |> assign(:filter_status, normalize_status_filter(status))
     |> assign(:page, 1)
     |> apply_filters()}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> apply_filters()}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    lab_allocation = LabAllocations.get_lab_allocation!(id)
    {:ok, _} = LabAllocations.delete_lab_allocation(lab_allocation)
    all = get_allocations_with_consumption()

    {:noreply,
     socket
     |> assign(:all_allocations, all)
     |> apply_filters()}
  end

  # GTIN Scanner Events
  def handle_event("open-gtin-scanner", _, socket) do
    {:noreply,
     socket
     |> assign(:show_gtin_scanner, true)
     |> assign(:gtin_search_query, "")
     |> assign(:gtin_search_results, [])
     |> assign(:gtin_searching, false)}
  end

  def handle_event("close-gtin-scanner", _, socket) do
    {:noreply,
     socket
     |> assign(:show_gtin_scanner, false)
     |> assign(:gtin_search_query, "")
     |> assign(:gtin_search_results, [])}
  end

  def handle_event("gtin-search", %{"query" => query}, socket) do
    query = String.trim(query)

    if String.length(query) >= 2 do
      # Search allocations by GTIN
      results = search_allocations_by_gtin(query)

      {:noreply,
       socket
       |> assign(:gtin_search_query, query)
       |> assign(:gtin_search_results, results)
       |> assign(:gtin_searching, false)}
    else
      {:noreply,
       socket
       |> assign(:gtin_search_query, query)
       |> assign(:gtin_search_results, [])
       |> assign(:gtin_searching, false)}
    end
  end

  def handle_event("select-gtin-result", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(:show_gtin_scanner, false)
     |> push_navigate(to: ~p"/lab/lab_allocations/#{id}")}
  end

  # Search allocations by GTIN
  defp search_allocations_by_gtin(query) do
    LabAllocations.list_lab_allocations()
    |> Enum.filter(fn allocation ->
      gtin = allocation.inventory_issued.gtin || ""
      brand_name = allocation.inventory_issued.inventory_received.brand_name || ""
      generic_name = allocation.inventory_issued.inventory_received.generic_name || ""

      String.contains?(String.downcase(gtin), String.downcase(query)) ||
        String.contains?(String.downcase(brand_name), String.downcase(query)) ||
        String.contains?(String.downcase(generic_name), String.downcase(query))
    end)
    |> Enum.map(fn allocation ->
      %{
        id: allocation.id,
        gtin: allocation.inventory_issued.gtin,
        brand_name: allocation.inventory_issued.inventory_received.brand_name,
        generic_name: allocation.inventory_issued.inventory_received.generic_name,
        allocated_to: allocation.allocated_to_user.name,
        remaining_quantity: allocation.remaining_quantity,
        uom: allocation.uom,
        status: get_status_info(allocation)
      }
    end)
    |> Enum.take(10)
  end

  defp apply_filters(socket) do
    filtered =
      filter_allocations(
        socket.assigns.all_allocations,
        socket.assigns.search,
        socket.assigns.filter_status
      )

    total_count = length(filtered)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    page_entries =
      Enum.slice(filtered, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> stream(:lab_allocations, page_entries, reset: true)
  end

  defp filter_allocations(allocations, search, status) do
    allocations
    |> filter_by_search(search)
    |> filter_by_status_label(status)
  end

  defp filter_by_search(allocations, ""), do: allocations
  defp filter_by_search(allocations, nil), do: allocations

  defp filter_by_search(allocations, query) do
    q = String.downcase(query)

    Enum.filter(allocations, fn a ->
      ir = a.inventory_issued && a.inventory_issued.inventory_received
      brand = (ir && ir.brand_name) || ""
      generic = (ir && ir.generic_name) || ""
      gtin = (a.inventory_issued && a.inventory_issued.gtin) || ""
      name = (a.allocated_to_user && a.allocated_to_user.name) || ""

      String.contains?(String.downcase(brand), q) or
        String.contains?(String.downcase(generic), q) or
        String.contains?(String.downcase(gtin), q) or
        String.contains?(String.downcase(name), q)
    end)
  end

  defp filter_by_status_label(allocations, "all"), do: allocations
  defp filter_by_status_label(allocations, ""), do: allocations
  defp filter_by_status_label(allocations, nil), do: allocations

  defp filter_by_status_label(allocations, status) do
    normalized_status = String.downcase(String.trim(status))

    Enum.filter(allocations, fn allocation ->
      allocation
      |> get_status_info()
      |> Map.fetch!(:label)
      |> String.downcase()
      |> Kernel.==(normalized_status)
    end)
  end

  defp normalize_status_filter(nil), do: "all"

  defp normalize_status_filter(status) when is_binary(status) do
    case String.downcase(String.trim(status)) do
      "available" -> "available"
      "low stock" -> "low stock"
      "depleted" -> "depleted"
      _ -> "all"
    end
  end

  defp normalize_status_filter(_), do: "all"

  defp get_allocations_with_consumption do
    LabAllocations.list_lab_allocations()
    |> Enum.map(fn allocation ->
      total_consumed = calculate_total_consumed(allocation.id)

      allocation
      |> Map.put(:total_consumed, total_consumed)
      |> Map.put(:quantity_in_store, quantity_in_store_for(allocation))
    end)
  end

  defp quantity_in_store_for(allocation) do
    case allocation.inventory_issued && allocation.inventory_issued.inventory_received_id do
      nil ->
        nil

      inventory_received_id ->
        case Batches.get_inventory_by_received_id(inventory_received_id) do
          %{quantity_in_stock: total} -> total
          _ -> 0
        end
    end
  end

  defp calculate_total_consumed(allocation_id) do
    LabConsumables.list_lab_consumables_for_allocation(allocation_id)
    |> Enum.map(&String.to_integer(&1.consumed_quantity))
    |> Enum.sum()
  end

  defp get_status_info(allocation) do
    remaining = allocation.remaining_quantity
    allocated = allocation.allocated_quantity

    cond do
      !is_number(remaining) || !is_number(allocated) ->
        %{label: "Unknown", color: "bg-gray-100 text-gray-800", icon: "question"}

      remaining <= 0 ->
        %{label: "Depleted", color: "bg-red-100 text-red-800", icon: "exclamation"}

      remaining < allocated * 0.2 ->
        %{label: "Low Stock", color: "bg-yellow-100 text-yellow-800", icon: "warning"}

      true ->
        %{label: "Available", color: "bg-green-100 text-green-800", icon: "check"}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <style>
      /* Custom scrollbar */
      .custom-scrollbar::-webkit-scrollbar {
        width: 6px;
        height: 6px;
      }
      .custom-scrollbar::-webkit-scrollbar-track {
        background: #f1f5f9;
        border-radius: 3px;
      }
      .custom-scrollbar::-webkit-scrollbar-thumb {
        background: #cbd5e1;
        border-radius: 3px;
      }
      .custom-scrollbar::-webkit-scrollbar-thumb:hover {
        background: #94a3b8;
      }

      /* Scanner animation */
      @keyframes scan-line {
        0%, 100% { top: 0%; }
        50% { top: 100%; }
      }
      .scan-line {
        animation: scan-line 2s ease-in-out infinite;
      }

      /* Pulse animation */
      @keyframes pulse-ring {
        0% { transform: scale(0.8); opacity: 1; }
        100% { transform: scale(1.3); opacity: 0; }
      }
      .pulse-ring {
        animation: pulse-ring 1.5s ease-out infinite;
      }

      /* Card hover */
      .card-hover {
        transition: transform 0.2s ease, box-shadow 0.2s ease;
      }
      .card-hover:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 25px -5px rgba(0, 0, 0, 0.1);
      }

      /* Search result highlight */
      .search-result-item {
        transition: all 0.15s ease;
      }
      .search-result-item:hover {
        background: linear-gradient(135deg, #f8f9ff 0%, #f0f1ff 100%);
      }
    </style>

    <!-- GTIN Scanner Modal -->
    <%= if @show_gtin_scanner do %>
      <div class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-start justify-center p-4 pt-[10vh] overflow-y-auto">
        <div class="bg-white rounded-2xl shadow-2xl max-w-lg w-full border border-slate-200 overflow-hidden">
          <!-- Modal Header -->
          <div class="bg-gradient-to-r from-[#6667ab] to-[#8384c9] px-6 py-4">
            <div class="flex items-center justify-between">
              <div class="flex items-center space-x-3">
                <div class="w-10 h-10 rounded-xl bg-white/20 flex items-center justify-center">
                  <svg
                    class="w-5 h-5 text-white"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z"
                    />
                  </svg>
                </div>
                <div>
                  <h2 class="text-lg font-semibold text-white">GTIN Scanner</h2>
                  <p class="text-sm text-white/80">Search by GTIN, brand or generic name</p>
                </div>
              </div>
              <button
                phx-click="close-gtin-scanner"
                class="w-8 h-8 rounded-lg bg-white/20 hover:bg-white/30 flex items-center justify-center transition-colors"
              >
                <svg class="w-5 h-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>
          </div>
          
    <!-- Search Input -->
          <div class="p-4 border-b border-slate-100">
            <div class="relative">
              <div class="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none">
                <svg
                  class="w-5 h-5 text-slate-400"
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
              </div>
              <input
                type="text"
                placeholder="Enter GTIN, brand name, or generic name..."
                value={@gtin_search_query}
                phx-keyup="gtin-search"
                phx-value-query={@gtin_search_query}
                name="query"
                autofocus
                class="w-full pl-12 pr-4 py-3 border-2 border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#6667ab] focus:border-transparent transition-all text-slate-800 placeholder-slate-400"
              />
              <%= if @gtin_searching do %>
                <div class="absolute inset-y-0 right-0 pr-4 flex items-center">
                  <svg class="animate-spin h-5 w-5 text-[#6667ab]" fill="none" viewBox="0 0 24 24">
                    <circle
                      class="opacity-25"
                      cx="12"
                      cy="12"
                      r="10"
                      stroke="currentColor"
                      stroke-width="4"
                    >
                    </circle>
                    <path
                      class="opacity-75"
                      fill="currentColor"
                      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
                    >
                    </path>
                  </svg>
                </div>
              <% end %>
            </div>
            
    <!-- Scanner Visual Hint -->
            <%= if @gtin_search_query == "" do %>
              <div class="mt-4 bg-slate-50 rounded-xl p-4 border border-dashed border-slate-300">
                <div class="flex items-center justify-center space-x-3 text-slate-500">
                  <div class="relative w-12 h-12 border-2 border-slate-300 rounded-lg overflow-hidden">
                    <div class="absolute inset-x-0 h-0.5 bg-[#6667ab] scan-line"></div>
                    <div class="absolute inset-0 flex items-center justify-center">
                      <div class="w-6 h-6 border-2 border-slate-300 rounded"></div>
                    </div>
                  </div>
                  <div class="text-sm">
                    <p class="font-medium text-slate-600">Start typing to search</p>
                    <p class="text-slate-400">Minimum 2 characters required</p>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
          
    <!-- Search Results -->
          <div class="max-h-[50vh] overflow-y-auto custom-scrollbar">
            <%= if @gtin_search_query != "" && length(@gtin_search_results) == 0 do %>
              <div class="p-8 text-center">
                <div class="w-16 h-16 mx-auto mb-4 rounded-full bg-slate-100 flex items-center justify-center">
                  <svg
                    class="w-8 h-8 text-slate-400"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                </div>
                <h3 class="text-lg font-medium text-slate-800 mb-1">No results found</h3>
                <p class="text-slate-500">Try a different search term</p>
              </div>
            <% else %>
              <div class="divide-y divide-slate-100">
                <%= for result <- @gtin_search_results do %>
                  <button
                    phx-click="select-gtin-result"
                    phx-value-id={result.id}
                    class="w-full p-4 text-left search-result-item"
                  >
                    <div class="flex items-start space-x-3">
                      <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-[#e7e7ff] to-[#d4d5f7] flex items-center justify-center text-[#373896] font-semibold flex-shrink-0">
                        {String.first(result.brand_name || result.generic_name || "?")}
                      </div>
                      <div class="flex-1 min-w-0">
                        <div class="flex items-start justify-between gap-2">
                          <div class="min-w-0">
                            <h4 class="font-semibold text-slate-800 truncate">
                              {result.brand_name || result.generic_name || "Unknown Item"}
                            </h4>
                            <%= if result.brand_name && result.generic_name do %>
                              <p class="text-sm text-slate-500 truncate">{result.generic_name}</p>
                            <% end %>
                          </div>
                          <span class={"flex-shrink-0 px-2 py-1 text-xs rounded-full font-medium #{result.status.color}"}>
                            {result.status.label}
                          </span>
                        </div>
                        <div class="mt-2 flex flex-wrap items-center gap-2 text-xs">
                          <span class="inline-flex items-center px-2 py-1 rounded-md bg-slate-100 text-slate-600">
                            <svg
                              class="w-3 h-3 mr-1"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke="currentColor"
                            >
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"
                              />
                            </svg>
                            GTIN: {result.gtin}
                          </span>
                          <span class="inline-flex items-center px-2 py-1 rounded-md bg-[#e7e7ff] text-[#373896]">
                            <svg
                              class="w-3 h-3 mr-1"
                              fill="none"
                              viewBox="0 0 24 24"
                              stroke="currentColor"
                            >
                              <path
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                stroke-width="2"
                                d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                              />
                            </svg>
                            {result.allocated_to}
                          </span>
                          <span class="inline-flex items-center px-2 py-1 rounded-md bg-emerald-100 text-emerald-700">
                            <svg
                              class="w-3 h-3 mr-1"
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
                            {result.remaining_quantity} {result.uom}
                          </span>
                        </div>
                      </div>
                      <div class="flex-shrink-0 text-slate-400">
                        <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M9 5l7 7-7 7"
                          />
                        </svg>
                      </div>
                    </div>
                  </button>
                <% end %>
              </div>
            <% end %>
          </div>
          
    <!-- Footer Hint -->
          <div class="px-4 py-3 bg-slate-50 border-t border-slate-100">
            <p class="text-xs text-slate-500 text-center">
              Press
              <kbd class="px-1.5 py-0.5 bg-white rounded border border-slate-200 font-mono">Esc</kbd>
              to close
            </p>
          </div>
        </div>
      </div>
    <% end %>

    <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
      <!-- Header -->
      <div class="px-4 sm:px-6 py-4 border-b border-slate-100">
        <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
          <div class="flex items-center">
            <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-[#6667ab] to-[#8384c9] flex items-center justify-center mr-3">
              <svg class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"
                />
              </svg>
            </div>
            <div>
              <h1 class="text-lg font-semibold text-slate-800">Lab Allocations</h1>
              <p class="text-sm text-slate-500">Manage allocated lab inventory items</p>
            </div>
          </div>

          <div class="flex items-center gap-2">
            <button
              phx-click="open-gtin-scanner"
              class="inline-flex items-center justify-center px-4 py-2.5 bg-gradient-to-r from-[#6667ab] to-[#7a7bc4] text-white rounded-xl font-medium hover:from-[#5556a0] hover:to-[#6a6bb4] transition-all shadow-lg shadow-[#6667ab]/25 active:scale-[0.98] group"
            >
              <div class="relative mr-2">
                <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z"
                  />
                </svg>
                <span class="absolute -top-1 -right-1 w-2 h-2 bg-emerald-400 rounded-full group-hover:animate-ping">
                </span>
              </div>
              <span class="hidden sm:inline">Scan GTIN</span>
              <span class="sm:hidden">Scan</span>
            </button>
          </div>
        </div>
      </div>
      
    <!-- Search & Filter Bar -->
      <div class="px-4 sm:px-6 py-3 border-b border-slate-100 bg-slate-50">
        <div class="flex items-center gap-3 flex-wrap">
          <form phx-change="search" phx-submit="search" class="flex-1 min-w-[200px]">
            <.search_input
              name="search"
              value={@search}
              placeholder="Search by item, GTIN or lab tech"
            />
          </form>

          <form phx-change="filter_status" class="sm:w-48">
            <select
              name="status"
              class="block w-full h-[40px] rounded-md border border-gray-300 bg-white px-3 text-sm text-slate-700 focus:border-[#6667ab] focus:ring-[#6667ab]"
            >
              <option value="all" selected={@filter_status == "all"}>All statuses</option>
              <option value="available" selected={@filter_status == "available"}>Available</option>
              <option value="low stock" selected={@filter_status == "low stock"}>Low Stock</option>
              <option value="depleted" selected={@filter_status == "depleted"}>Depleted</option>
            </select>
          </form>
        </div>
      </div>

      <%= if @total_count == 0 do %>
        <!-- Empty State -->
        <div class="p-8 sm:p-12 text-center">
          <div class="w-20 h-20 mx-auto mb-4 rounded-2xl bg-slate-100 flex items-center justify-center">
            <svg
              class="w-10 h-10 text-slate-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"
              />
            </svg>
          </div>
          <%= if @search != "" do %>
            <h3 class="text-lg font-semibold text-slate-800 mb-1">No results for "{@search}"</h3>
            <p class="text-slate-500 max-w-sm mx-auto">
              Try a different name, GTIN or lab technologist.
            </p>
          <% else %>
            <h3 class="text-lg font-semibold text-slate-800 mb-1">No lab allocations</h3>
            <p class="text-slate-500 max-w-sm mx-auto">
              No lab allocations have been created yet. Start by allocating inventory items to lab technologists.
            </p>
          <% end %>
        </div>
      <% else %>
        <!-- Desktop Table View -->
        <div class="hidden lg:block overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-200">
            <thead class="bg-slate-50">
              <tr>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Item
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Source / Batch
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Allocated To
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Allocated
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Consumed
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Remaining
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Status
                </th>
                <th class="px-6 py-3 text-left text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Expiry
                </th>
                <th class="px-6 py-3 text-right text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody class="bg-white divide-y divide-slate-100" id="lab_allocations" phx-update="stream">
              <%= for {id, lab_allocation} <- @streams.lab_allocations do %>
                <% inventory_issued = lab_allocation.inventory_issued
                inventory_received = inventory_issued && inventory_issued.inventory_received
                brand_name = inventory_received && inventory_received.brand_name
                generic_name = inventory_received && inventory_received.generic_name
                description = inventory_received && inventory_received.description
                gtin = inventory_issued && inventory_issued.gtin %>
                <tr
                  id={id}
                  class="hover:bg-slate-50 transition-colors cursor-pointer"
                  phx-click={JS.navigate(~p"/lab/lab_allocations/#{lab_allocation}")}
                >
                  <td class="px-6 py-4">
                    <div class="flex items-center">
                      <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-[#e7e7ff] to-[#d4d5f7] flex items-center justify-center text-[#373896] font-semibold mr-3 flex-shrink-0">
                        {String.first(brand_name || generic_name || "L")}
                      </div>
                      <div class="min-w-0 flex-1">
                        <%= if brand_name do %>
                          <p class="font-medium text-slate-800">
                            {brand_name}
                          </p>
                        <% end %>
                        <%= if generic_name do %>
                          <p class="text-sm text-slate-600">
                            {generic_name}
                          </p>
                        <% end %>
                        <%= if description do %>
                          <p class="text-xs text-slate-500 mt-1 line-clamp-2">
                            {description}
                          </p>
                        <% end %>
                        <%= if gtin do %>
                          <p class="text-xs text-slate-400 mt-1">
                            GTIN: {gtin}
                          </p>
                        <% end %>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4">
                    <% batch =
                      lab_allocation.inventory_issued && lab_allocation.inventory_issued.batch %>
                    <%= if batch do %>
                      <div class="space-y-1 text-xs">
                        <div class="flex items-center gap-1.5">
                          <span class="text-slate-400 font-medium uppercase">Lot:</span>
                          <span class="font-semibold text-slate-700">{batch.batch || "-"}</span>
                        </div>
                        <%= if batch.manufacturer do %>
                          <div class="flex items-center gap-1.5">
                            <span class="text-slate-400 font-medium uppercase">Mfr:</span>
                            <span class="text-slate-600">{batch.manufacturer}</span>
                          </div>
                        <% end %>
                        <%= if batch.supplier && batch.supplier.name do %>
                          <div class="flex items-center gap-1.5">
                            <span class="text-slate-400 font-medium uppercase">Supplier:</span>
                            <span class="text-slate-600">{batch.supplier.name}</span>
                          </div>
                        <% end %>
                        <%= if batch.received_date do %>
                          <div class="flex items-center gap-1.5">
                            <span class="text-slate-400 font-medium uppercase">Received:</span>
                            <span class="text-slate-600">
                              {Calendar.strftime(batch.received_date, "%b %d, %Y")}
                            </span>
                          </div>
                        <% end %>
                      </div>
                    <% else %>
                      <span class="text-xs text-slate-400">No batch info</span>
                    <% end %>
                    <% qty_in_store = Map.get(lab_allocation, :quantity_in_store) %>
                    <%= if qty_in_store != nil do %>
                      <div class="mt-2 inline-flex items-center gap-1 px-2 py-1 rounded-md bg-indigo-50 text-indigo-700 text-xs font-medium border border-indigo-100">
                        <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"
                          />
                        </svg>
                        In store: {qty_in_store} {lab_allocation.uom}
                      </div>
                    <% end %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-[#e7e7ff] text-[#373896]">
                      {lab_allocation.allocated_to_user.name}
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class="font-semibold text-slate-800">
                      {lab_allocation.allocated_quantity}
                    </span>
                    <span class="text-xs text-slate-500 ml-1">{lab_allocation.uom}</span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class="font-semibold text-red-600">
                      {Map.get(lab_allocation, :total_consumed, 0)}
                    </span>
                    <span class="text-xs text-slate-500 ml-1">{lab_allocation.uom}</span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <% remaining = lab_allocation.remaining_quantity || 0 %>
                    <% allocated = lab_allocation.allocated_quantity || 0 %>
                    <span class={"font-semibold #{cond do remaining <= 0 -> "text-red-600"; allocated > 0 && remaining < allocated * 0.2 -> "text-amber-600"; true -> "text-emerald-600" end}"}>
                      {remaining}
                    </span>
                    <span class="text-xs text-slate-500 ml-1">{lab_allocation.uom}</span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <% status_info = get_status_info(lab_allocation) %>
                    <span class={"inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium #{status_info.color}"}>
                      {status_info.label}
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <%= if lab_allocation.expiry_date do %>
                      <%= if Date.compare(lab_allocation.expiry_date, Date.utc_today()) == :lt do %>
                        <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-red-100 text-red-800">
                          Expired
                        </span>
                      <% else %>
                        <span class="text-sm text-slate-600">
                          {Calendar.strftime(lab_allocation.expiry_date, "%b %d, %Y")}
                        </span>
                      <% end %>
                    <% else %>
                      <span class="text-sm text-slate-400">No expiry</span>
                    <% end %>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-right">
                    <div class="flex items-center justify-end space-x-2">
                      <.link
                        navigate={~p"/lab/lab_allocations/#{lab_allocation}"}
                        class="p-2 rounded-lg text-slate-500 hover:text-[#6667ab] hover:bg-[#e7e7ff] transition-colors"
                        title="View"
                      >
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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
                      </.link>
                      <.link
                        patch={~p"/lab/lab_allocations/#{lab_allocation}/edit"}
                        class="p-2 rounded-lg text-slate-500 hover:text-[#6667ab] hover:bg-[#e7e7ff] transition-colors"
                        title="Edit"
                      >
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                          />
                        </svg>
                      </.link>
                      <button
                        phx-click={
                          JS.push("delete", value: %{id: lab_allocation.id}) |> hide("##{id}")
                        }
                        data-confirm="Are you sure you want to delete this allocation?"
                        class="p-2 rounded-lg text-slate-500 hover:text-red-600 hover:bg-red-50 transition-colors"
                        title="Delete"
                      >
                        <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                          />
                        </svg>
                      </button>
                    </div>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
        
    <!-- Mobile/Tablet Card View -->
        <div
          class="lg:hidden divide-y divide-slate-100"
          id="lab_allocations_mobile"
          phx-update="stream"
        >
          <%= for {id, lab_allocation} <- @streams.lab_allocations do %>
            <% inventory_issued = lab_allocation.inventory_issued
            inventory_received = inventory_issued && inventory_issued.inventory_received
            brand_name = inventory_received && inventory_received.brand_name
            generic_name = inventory_received && inventory_received.generic_name
            description = inventory_received && inventory_received.description
            gtin = inventory_issued && inventory_issued.gtin %>
            <div id={"#{id}-mobile"} class="p-4">
              <div class="card-hover bg-white border border-slate-200 rounded-xl overflow-hidden">
                <!-- Card Header - Clickable -->
                <.link navigate={~p"/lab/lab_allocations/#{lab_allocation}"} class="block">
                  <div class="p-4 bg-gradient-to-r from-slate-50 to-white">
                    <div class="flex items-start justify-between">
                      <div class="flex items-center space-x-3 min-w-0 flex-1">
                        <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-[#e7e7ff] to-[#d4d5f7] flex items-center justify-center text-[#373896] font-semibold flex-shrink-0">
                          {String.first(brand_name || generic_name || "L")}
                        </div>
                        <div class="min-w-0 flex-1">
                          <%= if brand_name do %>
                            <h4 class="font-semibold text-slate-800 truncate">
                              {brand_name}
                            </h4>
                          <% end %>
                          <%= if generic_name do %>
                            <p class="text-sm text-slate-600 truncate">
                              {generic_name}
                            </p>
                          <% end %>
                          <%= if description do %>
                            <p class="text-xs text-slate-500 mt-1 line-clamp-2">
                              {description}
                            </p>
                          <% end %>
                          <%= if gtin do %>
                            <p class="text-xs text-slate-400 mt-1 truncate">
                              GTIN: {gtin}
                            </p>
                          <% end %>
                        </div>
                      </div>
                      <div class="flex flex-col items-end space-y-1 flex-shrink-0 ml-2">
                        <% status_info = get_status_info(lab_allocation) %>
                        <span class={"inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium #{status_info.color}"}>
                          {status_info.label}
                        </span>
                        <%= if lab_allocation.expiry_date && Date.compare(lab_allocation.expiry_date, Date.utc_today()) == :lt do %>
                          <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                            Expired
                          </span>
                        <% end %>
                      </div>
                    </div>
                  </div>
                  
    <!-- Source / Batch Info -->
                  <% mobile_batch =
                    lab_allocation.inventory_issued && lab_allocation.inventory_issued.batch %>
                  <%= if mobile_batch do %>
                    <div class="px-4 pb-3">
                      <div class="bg-slate-50 rounded-lg p-2.5 grid grid-cols-2 gap-x-3 gap-y-1 text-xs">
                        <div>
                          <span class="text-slate-400 uppercase">Lot</span>
                          <p class="font-semibold text-slate-700">{mobile_batch.batch || "-"}</p>
                        </div>
                        <%= if mobile_batch.manufacturer do %>
                          <div>
                            <span class="text-slate-400 uppercase">Mfr</span>
                            <p class="text-slate-600 truncate">{mobile_batch.manufacturer}</p>
                          </div>
                        <% end %>
                        <%= if mobile_batch.supplier && mobile_batch.supplier.name do %>
                          <div>
                            <span class="text-slate-400 uppercase">Supplier</span>
                            <p class="text-slate-600 truncate">{mobile_batch.supplier.name}</p>
                          </div>
                        <% end %>
                        <%= if mobile_batch.received_date do %>
                          <div>
                            <span class="text-slate-400 uppercase">Received</span>
                            <p class="text-slate-600">
                              {Calendar.strftime(mobile_batch.received_date, "%b %d, %Y")}
                            </p>
                          </div>
                        <% end %>
                      </div>
                      <% mobile_qty_in_store = Map.get(lab_allocation, :quantity_in_store) %>
                      <%= if mobile_qty_in_store != nil do %>
                        <div class="mt-2 inline-flex items-center gap-1 px-2 py-1 rounded-md bg-indigo-50 text-indigo-700 text-xs font-medium border border-indigo-100">
                          <svg class="w-3 h-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                            <path
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              stroke-width="2"
                              d="M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z"
                            />
                          </svg>
                          In store: {mobile_qty_in_store} {lab_allocation.uom}
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                  
    <!-- Card Stats -->
                  <div class="px-4 pb-3">
                    <div class="grid grid-cols-3 gap-2">
                      <div class="bg-slate-50 rounded-lg p-2 text-center">
                        <p class="text-xs text-slate-500 uppercase font-medium">Allocated</p>
                        <p class="text-sm font-semibold text-slate-800">
                          {lab_allocation.allocated_quantity}
                          <span class="text-xs font-normal text-slate-500">{lab_allocation.uom}</span>
                        </p>
                      </div>
                      <div class="bg-red-50 rounded-lg p-2 text-center">
                        <p class="text-xs text-red-500 uppercase font-medium">Consumed</p>
                        <p class="text-sm font-semibold text-red-600">
                          {Map.get(lab_allocation, :total_consumed, 0)}
                          <span class="text-xs font-normal text-red-400">{lab_allocation.uom}</span>
                        </p>
                      </div>
                      <% rem_q = lab_allocation.remaining_quantity || 0 %>
                      <% alloc_q = lab_allocation.allocated_quantity || 0 %>
                      <div class={"rounded-lg p-2 text-center #{cond do rem_q <= 0 -> "bg-red-50"; alloc_q > 0 && rem_q < alloc_q * 0.2 -> "bg-amber-50"; true -> "bg-emerald-50" end}"}>
                        <p class={"text-xs uppercase font-medium #{cond do rem_q <= 0 -> "text-red-500"; alloc_q > 0 && rem_q < alloc_q * 0.2 -> "text-amber-500"; true -> "text-emerald-500" end}"}>
                          Remaining
                        </p>
                        <p class={"text-sm font-semibold #{cond do rem_q <= 0 -> "text-red-600"; alloc_q > 0 && rem_q < alloc_q * 0.2 -> "text-amber-600"; true -> "text-emerald-600" end}"}>
                          {rem_q}
                          <span class="text-xs font-normal opacity-70">{lab_allocation.uom}</span>
                        </p>
                      </div>
                    </div>
                  </div>
                </.link>
                
    <!-- Card Footer -->
                <div class="px-4 py-3 bg-slate-50 border-t border-slate-100 flex items-center justify-between">
                  <div class="flex items-center space-x-2">
                    <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-[#e7e7ff] text-[#373896]">
                      <svg class="w-3 h-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                        />
                      </svg>
                      {lab_allocation.allocated_to_user.name}
                    </span>
                    <%= if lab_allocation.expiry_date && Date.compare(lab_allocation.expiry_date, Date.utc_today()) != :lt do %>
                      <span class="text-xs text-slate-500">
                        Exp: {Calendar.strftime(lab_allocation.expiry_date, "%b %d, %Y")}
                      </span>
                    <% end %>
                  </div>
                  <div class="flex items-center space-x-1">
                    <.link
                      navigate={~p"/lab/lab_allocations/#{lab_allocation}"}
                      class="p-2 rounded-lg text-slate-500 hover:text-[#6667ab] hover:bg-white transition-colors"
                    >
                      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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
                    </.link>
                    <.link
                      patch={~p"/lab/lab_allocations/#{lab_allocation}/edit"}
                      class="p-2 rounded-lg text-slate-500 hover:text-[#6667ab] hover:bg-white transition-colors"
                    >
                      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                        />
                      </svg>
                    </.link>
                    <button
                      phx-click={
                        JS.push("delete", value: %{id: lab_allocation.id}) |> hide("##{id}-mobile")
                      }
                      data-confirm="Are you sure you want to delete this allocation?"
                      class="p-2 rounded-lg text-slate-500 hover:text-red-600 hover:bg-white transition-colors"
                    >
                      <svg class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                        />
                      </svg>
                    </button>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      <% end %>
    </div>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="lab_allocation-modal"
      show
      on_cancel={JS.patch(~p"/lab/lab_allocations")}
    >
      <.live_component
        module={MedcampWeb.LabAllocationLive.FormComponent}
        id={@lab_allocation.id || :new}
        title={@page_title}
        action={@live_action}
        lab_allocation={@lab_allocation}
        patch={~p"/lab/lab_allocations"}
      />
    </.modal>
    """
  end
end
