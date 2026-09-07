defmodule MedcampWeb.NursingAllocationLive.Index do
  use MedcampWeb, :nurse_live_view
  alias Medcamp.Nursing
  alias Medcamp.NursingAllocations.NursingAllocation

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    allocations = get_allocations_with_consumption()
    allocation_groups = group_allocations_by_inventory_received(allocations)

    {:ok,
     socket
     |> assign(:show_gtin_scanner, false)
     |> assign(:gtin_search_query, "")
     |> assign(:gtin_search_results, [])
     |> assign(:gtin_searching, false)
     |> assign(:active_tab, :nursing_allocations)
     |> assign(:search, "")
     |> assign(:filter_status, "all")
     |> assign(:expiry_filters, default_expiry_filters())
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:all_allocations, allocations)
     |> assign(:all_allocation_groups, allocation_groups)
     |> assign(:selected_allocation_group, nil)
     |> paginate_allocation_groups()}
  end

  defp default_expiry_filters, do: %{expiry_status: "", expiry_from: "", expiry_to: ""}

  defp paginate_allocation_groups(socket) do
    filtered =
      filter_allocations(
        socket.assigns.all_allocation_groups,
        socket.assigns.search,
        socket.assigns.filter_status,
        socket.assigns.expiry_filters
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
    |> assign(:nursing_allocation_groups, page_entries)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params),
    do: socket |> assign(:page_title, "Nursing Allocations")

  defp apply_action(socket, :new, _params),
    do:
      socket
      |> assign(:page_title, "New Allocation")
      |> assign(:nursing_allocation, %NursingAllocation{})

  defp get_allocations_with_consumption do
    Nursing.list_nursing_allocations()
    |> Enum.map(fn a ->
      total =
        Nursing.list_consumables_for_allocation(a.id)
        |> Enum.map(& &1.consumed_quantity)
        |> Enum.sum()

      Map.put(a, :total_consumed, total)
    end)
  end

  # GTIN Scanner Events
  @impl true
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
      results = search_allocations_by_gtin(socket.assigns.all_allocation_groups, query)

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

  def handle_event("select-gtin-result", %{"id" => group_id}, socket) do
    selected_group = find_allocation_group(socket.assigns.all_allocation_groups, group_id)

    {:noreply,
     socket
     |> assign(:show_gtin_scanner, false)
     |> assign(:selected_allocation_group, selected_group)}
  end

  def handle_event("search", %{"search" => term}, socket) do
    {:noreply,
     socket
     |> assign(:search, term)
     |> assign(:page, 1)
     |> paginate_allocation_groups()}
  end

  def handle_event("filter_status", %{"filters" => filters}, socket) do
    {:noreply,
     socket
     |> assign(:filter_status, filters["status"] || socket.assigns.filter_status)
     |> assign(:expiry_filters, %{
       expiry_status: Medcamp.ExpiryFilter.normalize(filters["expiry_status"]),
       expiry_from: filters["expiry_from"] || "",
       expiry_to: filters["expiry_to"] || ""
     })
     |> assign(:page, 1)
     |> paginate_allocation_groups()}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> paginate_allocation_groups()}
  end

  def handle_event("clear_status_filter", _params, socket) do
    {:noreply,
     socket
     |> assign(:filter_status, "all")
     |> assign(:expiry_filters, default_expiry_filters())
     |> assign(:page, 1)
     |> paginate_allocation_groups()}
  end

  def handle_event("clear_chip", %{"field" => field}, socket) do
    case field do
      "status" ->
        handle_event("clear_status_filter", %{}, socket)

      "expiry_status" ->
        clear_expiry_field(socket, :expiry_status)

      "expiry_from" ->
        clear_expiry_field(socket, :expiry_from)

      "expiry_to" ->
        clear_expiry_field(socket, :expiry_to)

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("open-batch-selector", %{"group-id" => group_id}, socket) do
    {:noreply,
     assign(
       socket,
       :selected_allocation_group,
       find_allocation_group(socket.assigns.all_allocation_groups, group_id)
     )}
  end

  def handle_event("close-batch-selector", _params, socket) do
    {:noreply, assign(socket, :selected_allocation_group, nil)}
  end

  defp clear_expiry_field(socket, key) do
    {:noreply,
     socket
     |> assign(:expiry_filters, Map.put(socket.assigns.expiry_filters, key, ""))
     |> assign(:page, 1)
     |> paginate_allocation_groups()}
  end

  defp filter_allocations(allocations, search, status, expiry_filters) do
    allocations
    |> filter_by_search(search)
    |> filter_by_status_label(status)
    |> filter_by_expiry(expiry_filters)
  end

  # A group holds one allocation per batch, so it matches when any of its
  # batches expires in the requested window.
  defp filter_by_expiry(groups, filters) do
    status = filters[:expiry_status] || ""
    from = filters[:expiry_from] || ""
    to = filters[:expiry_to] || ""

    if status == "" and from == "" and to == "" do
      groups
    else
      Enum.filter(groups, fn group ->
        Enum.any?(group.allocations, fn allocation ->
          Medcamp.ExpiryFilter.matches?(allocation.expiry_date, status, from, to)
        end)
      end)
    end
  end

  defp filter_by_search(allocations, ""), do: allocations
  defp filter_by_search(allocations, nil), do: allocations

  defp filter_by_search(allocations, term) do
    term = String.downcase(String.trim(term))

    Enum.filter(allocations, fn group ->
      details = group.details
      nurse_names = String.downcase(Enum.join(group.nurse_names, " "))
      item_name = String.downcase(details.display_name || "")
      brand = String.downcase(details.brand_name || "")
      generic = String.downcase(details.generic_name || "")
      gtin = String.downcase(details.gtin || "")
      batch_numbers = String.downcase(Enum.join(group.batch_numbers, " "))

      String.contains?(nurse_names, term) ||
        String.contains?(item_name, term) ||
        String.contains?(brand, term) ||
        String.contains?(generic, term) ||
        String.contains?(gtin, term) ||
        String.contains?(batch_numbers, term)
    end)
  end

  defp filter_by_status_label(allocations, "all"), do: allocations

  defp filter_by_status_label(allocations, status) do
    Enum.filter(allocations, fn group ->
      info = get_status_info(group)
      String.downcase(info.label) == String.downcase(status)
    end)
  end

  defp search_allocations_by_gtin(groups, query) do
    groups
    |> Enum.filter(fn group ->
      details = group.details
      gtin = details.gtin || ""
      brand = details.brand_name || ""
      generic = details.generic_name || ""
      batches = Enum.join(group.batch_numbers, " ")

      String.contains?(String.downcase(gtin), String.downcase(query)) ||
        String.contains?(String.downcase(brand), String.downcase(query)) ||
        String.contains?(String.downcase(generic), String.downcase(query)) ||
        String.contains?(String.downcase(batches), String.downcase(query))
    end)
    |> Enum.map(fn group ->
      details = group.details

      %{
        id: group.id,
        gtin: details.gtin,
        brand_name: details.brand_name,
        generic_name: details.generic_name,
        batch_number: group.batch_label,
        batch_count: group.batch_count,
        size_gauge: details.size_gauge,
        allocated_to: group.nurse_label,
        remaining_quantity: group.remaining_quantity,
        uom: group.uom,
        status: get_status_info(group)
      }
    end)
    |> Enum.take(10)
  end

  defp group_allocations_by_inventory_received(allocations) do
    allocations
    |> Enum.group_by(&allocation_group_key/1)
    |> Enum.map(fn {key, grouped_allocations} ->
      build_allocation_group(key, grouped_allocations)
    end)
    |> Enum.sort_by(& &1.latest_inserted_at, {:desc, DateTime})
  end

  defp allocation_group_key(allocation) do
    (allocation.inventory_issued && allocation.inventory_issued.inventory_received_id) ||
      allocation.inventory_received_id ||
      {:allocation, allocation.id}
  end

  defp build_allocation_group({:allocation, allocation_id}, allocations),
    do: build_allocation_group("allocation-#{allocation_id}", allocations)

  defp build_allocation_group(inventory_received_id, allocations) do
    representative = hd(allocations)
    details = Nursing.allocation_item_details(representative)

    batch_numbers =
      allocations |> Enum.map(&Nursing.allocation_item_details(&1).batch_number) |> compact()

    nurse_names =
      allocations |> Enum.map(&(&1.allocated_to_user && &1.allocated_to_user.name)) |> compact()

    allocated_quantity = Enum.sum(Enum.map(allocations, &(&1.allocated_quantity || 0)))
    remaining_quantity = Enum.sum(Enum.map(allocations, &(&1.remaining_quantity || 0)))
    total_consumed = Enum.sum(Enum.map(allocations, &Map.get(&1, :total_consumed, 0)))

    %{
      id: "inventory-received-#{inventory_received_id}",
      inventory_received_id: inventory_received_id,
      details: details,
      allocations: Enum.sort_by(allocations, &batch_sort_value/1, {:asc, Date}),
      allocated_quantity: allocated_quantity,
      remaining_quantity: remaining_quantity,
      total_consumed: total_consumed,
      uom: representative.uom,
      batch_numbers: batch_numbers,
      batch_count: length(allocations),
      batch_label: batch_label(batch_numbers, allocations),
      nurse_names: nurse_names,
      nurse_label: nurse_label(nurse_names),
      latest_inserted_at: latest_inserted_at(allocations)
    }
  end

  defp compact(values) do
    values
    |> Enum.reject(fn value ->
      is_nil(value) || String.trim(to_string(value)) == ""
    end)
    |> Enum.uniq()
  end

  defp batch_label([], allocations), do: "#{length(allocations)} batch(es)"
  defp batch_label([batch_number], _allocations), do: batch_number
  defp batch_label(batch_numbers, _allocations), do: "#{length(batch_numbers)} batches"

  defp nurse_label([]), do: "Unassigned"
  defp nurse_label([name]), do: name
  defp nurse_label(names), do: "#{length(names)} nurses"

  defp latest_inserted_at(allocations) do
    fallback = DateTime.from_unix!(0)

    allocations
    |> Enum.map(& &1.inserted_at)
    |> Enum.reject(&is_nil/1)
    |> Enum.reduce(fallback, fn inserted_at, latest ->
      case DateTime.compare(inserted_at, latest) do
        :gt -> inserted_at
        _ -> latest
      end
    end)
  end

  defp batch_sort_value(allocation) do
    allocation.expiry_date || ~D[9999-12-31]
  end

  defp find_allocation_group(groups, group_id) do
    Enum.find(groups, fn group -> group.id == group_id end)
  end

  defp count_active_filters(assigns) do
    expiry = assigns.expiry_filters

    [
      assigns.filter_status != "all",
      expiry[:expiry_status] != "",
      expiry[:expiry_from] != "",
      expiry[:expiry_to] != ""
    ]
    |> Enum.count(& &1)
  end

  defp filter_chips(filter_status, expiry_filters) do
    [
      filter_chip(filter_status, "status", stock_status_label(filter_status), ["all"]),
      filter_chip(
        expiry_filters[:expiry_status],
        "expiry_status",
        "Expiry: #{Medcamp.ExpiryFilter.label(expiry_filters[:expiry_status])}"
      ),
      filter_chip(
        expiry_filters[:expiry_from],
        "expiry_from",
        "Expiry from #{expiry_filters[:expiry_from]}"
      ),
      filter_chip(
        expiry_filters[:expiry_to],
        "expiry_to",
        "Expiry to #{expiry_filters[:expiry_to]}"
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp stock_status_label("available"), do: "Available"
  defp stock_status_label("low stock"), do: "Low Stock"
  defp stock_status_label("depleted"), do: "Depleted"
  defp stock_status_label(other), do: other

  defp get_status_info(allocation_or_group) do
    remaining = allocation_or_group.remaining_quantity
    allocated = allocation_or_group.allocated_quantity

    cond do
      !is_number(remaining) || !is_number(allocated) ->
        %{label: "Unknown", color: "bg-gray-100 text-gray-800"}

      remaining <= 0 ->
        %{label: "Depleted", color: "bg-red-100 text-red-800"}

      remaining < allocated * 0.2 ->
        %{label: "Low Stock", color: "bg-amber-100 text-amber-800"}

      true ->
        %{label: "Available", color: "bg-emerald-100 text-emerald-800"}
    end
  end

  defp format_batch_expiry(allocation, batch) do
    cond do
      allocation.expiry_date ->
        Calendar.strftime(allocation.expiry_date, "%b %d, %Y")

      batch && batch.expiry ->
        to_string(batch.expiry)

      true ->
        "—"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <style>
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

      @keyframes scan-line {
        0%, 100% { top: 0%; }
        50% { top: 100%; }
      }
      .scan-line {
        animation: scan-line 2s ease-in-out infinite;
      }

      .card-hover {
        transition: transform 0.2s ease, box-shadow 0.2s ease;
      }
      .card-hover:hover {
        transform: translateY(-2px);
        box-shadow: 0 8px 25px -5px rgba(0, 0, 0, 0.1);
      }

      .search-result-item {
        transition: all 0.15s ease;
      }
      .search-result-item:hover {
        background: linear-gradient(135deg, #f0fdfa 0%, #ccfbf1 100%);
      }
    </style>

    <!-- GTIN Scanner Modal -->
    <%= if @show_gtin_scanner do %>
      <div class="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-start justify-center p-4 pt-[10vh] overflow-y-auto">
        <div class="bg-white rounded-2xl shadow-2xl max-w-lg w-full border border-slate-200 overflow-hidden">
          <!-- Modal Header -->
          <div class="bg-[#373896] px-6 py-4">
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
                class="w-full pl-12 pr-4 py-3 border-2 border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#373896]-500 focus:border-transparent transition-all text-slate-800 placeholder-slate-400"
              />
              <%= if @gtin_searching do %>
                <div class="absolute inset-y-0 right-0 pr-4 flex items-center">
                  <svg class="animate-spin h-5 w-5 text-[#373896]-600" fill="none" viewBox="0 0 24 24">
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
              <div class="mt-4 bg-[#373896]-50 rounded-xl p-4 border border-dashed border-[#373896]-300">
                <div class="flex items-center justify-center space-x-3 text-[#373896]-600">
                  <div class="relative w-12 h-12 border-2 border-[#373896]-400 rounded-lg overflow-hidden">
                    <div class="absolute inset-x-0 h-0.5 bg-[#373896]-500 scan-line"></div>
                    <div class="absolute inset-0 flex items-center justify-center">
                      <div class="w-6 h-6 border-2 border-[#373896]-400 rounded"></div>
                    </div>
                  </div>
                  <div class="text-sm">
                    <p class="font-medium text-[#373896]-700">Start typing to search</p>
                    <p class="text-[#373896]-500">Minimum 2 characters required</p>
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
                      <div class="w-12 h-12 rounded-xl bg-[#373896]-100  flex items-center justify-center text-[#373896]-700 font-semibold flex-shrink-0">
                        {String.first(result.brand_name || result.generic_name || "?")}
                      </div>
                      <div class="flex-1 min-w-0">
                        <div class="flex items-start justify-between gap-2">
                          <div class="min-w-0">
                            <h4 class="font-semibold text-slate-800 truncate">
                              {result.brand_name || result.generic_name || "Unknown Item"}
                            </h4>
                            <p class="text-sm text-slate-500 truncate">
                              Brand: {(result.brand_name && String.trim(result.brand_name || "") != "" &&
                                         result.brand_name) || "—"}
                            </p>
                            <p class="text-sm text-slate-500 truncate">
                              Generic: {(result.generic_name &&
                                           String.trim(result.generic_name || "") != "" &&
                                           result.generic_name) || "—"}
                            </p>
                            <div class="text-xs text-slate-500 mt-0.5">
                              <span>
                                Batches: {(result.batch_number &&
                                             String.trim(to_string(result.batch_number || "")) != "" &&
                                             result.batch_number) || "—"}
                              </span>
                              <%= if result.size_gauge do %>
                                <span class={if result.batch_number, do: "ml-2", else: ""}>
                                  Size: {result.size_gauge}
                                </span>
                              <% end %>
                            </div>
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
                          <span class="inline-flex items-center px-2 py-1 rounded-md bg-[#373896]-100 text-[#373896]-700">
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
            <div class="w-10 h-10 rounded-xl bg-[#373896] flex items-center justify-center mr-3">
              <svg class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
                />
              </svg>
            </div>
            <div>
              <h1 class="text-lg font-semibold text-slate-800">Nursing Allocations</h1>
              <p class="text-sm text-slate-500">Track medication and supply usage on wards</p>
            </div>
          </div>

          <div class="flex items-center gap-2">
            <!-- Scan GTIN Button -->
            <button
              phx-click="open-gtin-scanner"
              class="inline-flex items-center justify-center px-4 py-2.5 bg-[#373896]  text-white rounded-xl font-medium hover:from-[#373896]-700 hover:to-[#373896]-600 transition-all shadow-lg shadow-[#373896]-500/25 active:scale-[0.98] group"
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
            
    <!-- New Allocation Button -->
            <.link
              patch={~p"/nurse/allocations/new"}
              class="inline-flex items-center justify-center px-4 py-2.5 bg-slate-100 text-slate-700 rounded-xl font-medium hover:bg-slate-200 transition-all"
            >
              <svg class="w-5 h-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 4v16m8-8H4"
                />
              </svg>
              <span class="hidden sm:inline">New Allocation</span>
              <span class="sm:hidden">New</span>
            </.link>
          </div>
        </div>
      </div>
      
    <!-- Search & Filter Bar -->
      <div class="px-4 sm:px-6 py-3 border-b border-slate-100 bg-slate-50">
        <div class="flex items-center gap-3 flex-wrap">
          <form phx-change="search" class="flex-1 min-w-[200px]">
            <.search_input
              name="search"
              value={@search}
              placeholder="Search by nurse, item, brand, generic, GTIN, or batch..."
            />
          </form>

          <.filter_drawer
            id="nursing-allocations-filters"
            title="Filter nursing allocations"
            apply_event="filter_status"
            clear_event="clear_status_filter"
            active_count={count_active_filters(assigns)}
          >
            <:group label="Status">
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Status</label>
                <select
                  name="filters[status]"
                  class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
                >
                  <option value="all" selected={@filter_status == "all"}>All</option>
                  <option value="available" selected={@filter_status == "available"}>
                    Available
                  </option>
                  <option value="low stock" selected={@filter_status == "low stock"}>
                    Low Stock
                  </option>
                  <option value="depleted" selected={@filter_status == "depleted"}>
                    Depleted
                  </option>
                </select>
              </div>
            </:group>

            <:group label="Expiry">
              <.expiry_filter_fields
                status_value={@expiry_filters[:expiry_status]}
                from_value={@expiry_filters[:expiry_from]}
                to_value={@expiry_filters[:expiry_to]}
              />
            </:group>

            <:chip
              :for={chip <- filter_chips(@filter_status, @expiry_filters)}
              label={chip.label}
              clear={JS.push("clear_chip", value: %{"field" => chip.field})}
            />
          </.filter_drawer>
        </div>
      </div>

      <%= if Enum.empty?(@nursing_allocation_groups) do %>
        <!-- Empty State -->
        <div class="p-8 sm:p-12 text-center">
          <div class="w-20 h-20 mx-auto mb-4 rounded-2xl bg-[#373896]-50 flex items-center justify-center">
            <svg
              class="w-10 h-10 text-[#373896]-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
              />
            </svg>
          </div>
          <h3 class="text-lg font-semibold text-slate-800 mb-1">No nursing allocations</h3>
          <p class="text-slate-500 max-w-sm mx-auto">
            No allocations have been assigned yet. Start by creating a new allocation.
          </p>
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
                  Nurse
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
                <th class="px-6 py-3 text-right text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody id="nursing_allocations" class="bg-white divide-y divide-slate-100">
              <%= for group <- @nursing_allocation_groups do %>
                <tr
                  id={"nursing-allocation-group-#{group.id}"}
                  class="hover:bg-slate-50 transition-colors cursor-pointer"
                  phx-click="open-batch-selector"
                  phx-value-group-id={group.id}
                >
                  <td class="px-6 py-4">
                    <% details = group.details %>
                    <div class="flex items-center">
                      <div class="w-10 h-10 rounded-xl bg-[#373896] flex items-center justify-center text-white font-semibold mr-3 flex-shrink-0">
                        {String.first(details.display_name)}
                      </div>
                      <div class="min-w-0">
                        <p class="font-medium text-slate-800">{details.display_name}</p>
                        <div class="text-sm text-slate-600 space-y-0.5 mt-1">
                          <p>
                            <span class="text-slate-500">Brand:</span> {(details.brand_name &&
                                                                           String.trim(
                                                                             details.brand_name || ""
                                                                           ) != "" &&
                                                                           details.brand_name) || "—"}
                          </p>
                          <p>
                            <span class="text-slate-500">Generic:</span> {(details.generic_name &&
                                                                             String.trim(
                                                                               details.generic_name ||
                                                                                 ""
                                                                             ) != "" &&
                                                                             details.generic_name) ||
                              "—"}
                          </p>
                          <p>
                            <span class="text-slate-500">Batches:</span> {group.batch_label}
                          </p>
                          <%= if details.size_gauge do %>
                            <p><span class="text-slate-500">Size:</span> {details.size_gauge}</p>
                          <% end %>
                          <p><span class="text-slate-500">GTIN:</span> {details.gtin || "—"}</p>
                        </div>
                      </div>
                    </div>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium bg-[#373896]-100 text-[#373896]-700">
                      {group.nurse_label}
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class="font-semibold text-slate-800">{group.allocated_quantity}</span>
                    <span class="text-xs text-slate-500 ml-1">{group.uom}</span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <span class="font-semibold text-orange-600">
                      {group.total_consumed}
                    </span>
                    <span class="text-xs text-slate-500 ml-1">{group.uom}</span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <% remaining = group.remaining_quantity %>
                    <% allocated = group.allocated_quantity %>
                    <span class={"font-semibold #{cond do remaining <= 0 -> "text-red-600"; remaining < allocated * 0.2 -> "text-amber-600"; true -> "text-emerald-600" end}"}>
                      {remaining}
                    </span>
                    <span class="text-xs text-slate-500 ml-1">{group.uom}</span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap">
                    <% status = get_status_info(group) %>
                    <span class={"inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium #{status.color}"}>
                      {status.label}
                    </span>
                  </td>
                  <td class="px-6 py-4 whitespace-nowrap text-right">
                    <button
                      type="button"
                      phx-click="open-batch-selector"
                      phx-value-group-id={group.id}
                      class="inline-flex items-center px-3 py-1.5 text-sm font-medium text-[#373896]-600 hover:text-[#373896]-800 hover:bg-[#373896]-50 rounded-lg transition-colors"
                    >
                      <svg class="w-4 h-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
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
                      Select Batch
                    </button>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
        
    <!-- Mobile/Tablet Card View -->
        <div class="lg:hidden divide-y divide-slate-100" id="nursing_allocations_mobile">
          <%= for group <- @nursing_allocation_groups do %>
            <div id={"nursing-allocation-group-#{group.id}-mobile"} class="p-4">
              <div class="card-hover bg-white border border-slate-200 rounded-xl overflow-hidden">
                <button
                  type="button"
                  phx-click="open-batch-selector"
                  phx-value-group-id={group.id}
                  class="block w-full text-left"
                >
                  <% details = group.details %>
                  <div class="p-4 bg-[#373896]">
                    <div class="flex items-start justify-between">
                      <div class="flex items-center space-x-3 min-w-0 flex-1">
                        <div class="w-12 h-12 rounded-xl flex items-center justify-center text-white font-semibold flex-shrink-0">
                          {String.first(details.display_name)}
                        </div>
                        <div class="min-w-0 flex-1">
                          <h4 class="font-semibold text-slate-800 truncate">
                            {details.display_name}
                          </h4>
                          <div class="text-sm text-slate-500 space-y-0.5">
                            <p class="truncate">
                              Brand: {(details.brand_name &&
                                         String.trim(details.brand_name || "") != "" &&
                                         details.brand_name) || "—"}
                            </p>
                            <p class="truncate">
                              Generic: {(details.generic_name &&
                                           String.trim(details.generic_name || "") != "" &&
                                           details.generic_name) || "—"}
                            </p>
                            <p>
                              Batches: {group.batch_label}
                            </p>
                            <%= if details.size_gauge do %>
                              <p>Size: {details.size_gauge}</p>
                            <% end %>
                            <p>GTIN: {details.gtin || "—"}</p>
                          </div>
                        </div>
                      </div>
                      <% status = get_status_info(group) %>
                      <span class={"flex-shrink-0 ml-2 px-2 py-0.5 rounded-full text-xs font-medium #{status.color}"}>
                        {status.label}
                      </span>
                    </div>
                  </div>
                  
    <!-- Stats Grid -->
                  <div class="px-4 pb-3">
                    <div class="grid grid-cols-3 gap-2">
                      <div class="bg-slate-50 rounded-lg p-2 text-center">
                        <p class="text-xs text-slate-500 uppercase font-medium">Allocated</p>
                        <p class="text-sm font-semibold text-slate-800">
                          {group.allocated_quantity}
                          <span class="text-xs font-normal text-slate-500">{group.uom}</span>
                        </p>
                      </div>
                      <div class="bg-orange-50 rounded-lg p-2 text-center">
                        <p class="text-xs text-orange-500 uppercase font-medium">Consumed</p>
                        <p class="text-sm font-semibold text-orange-600">
                          {group.total_consumed}
                          <span class="text-xs font-normal text-orange-400">{group.uom}</span>
                        </p>
                      </div>
                      <% remaining = group.remaining_quantity %>
                      <% allocated = group.allocated_quantity %>
                      <div class={"rounded-lg p-2 text-center #{cond do remaining <= 0 -> "bg-red-50"; remaining < allocated * 0.2 -> "bg-amber-50"; true -> "bg-emerald-50" end}"}>
                        <p class={"text-xs uppercase font-medium #{cond do remaining <= 0 -> "text-red-500"; remaining < allocated * 0.2 -> "text-amber-500"; true -> "text-emerald-500" end}"}>
                          Remaining
                        </p>
                        <p class={"text-sm font-semibold #{cond do remaining <= 0 -> "text-red-600"; remaining < allocated * 0.2 -> "text-amber-600"; true -> "text-emerald-600" end}"}>
                          {remaining}
                          <span class="text-xs font-normal opacity-70">{group.uom}</span>
                        </p>
                      </div>
                    </div>
                  </div>
                </button>
                
    <!-- Footer -->
                <div class="px-4 py-3 bg-slate-50 border-t border-slate-100 flex items-center justify-between">
                  <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-[#373896]-100 text-[#373896]-700">
                    <svg class="w-3 h-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                      />
                    </svg>
                    {group.nurse_label}
                  </span>
                  <button
                    type="button"
                    phx-click="open-batch-selector"
                    phx-value-group-id={group.id}
                    class="inline-flex items-center text-sm font-medium text-[#373896]-600 hover:text-[#373896]-800"
                  >
                    Select Batch
                    <svg class="w-4 h-4 ml-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M9 5l7 7-7 7"
                      />
                    </svg>
                  </button>
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
          class="px-4 pb-4"
        />
      <% end %>
    </div>

    <.modal
      :if={@selected_allocation_group}
      id="batch-selector-modal"
      show
      on_cancel={JS.push("close-batch-selector")}
    >
      <% group = @selected_allocation_group %>
      <div class="space-y-5">
        <div>
          <p class="text-xs font-semibold uppercase tracking-wide text-slate-500">Select Batch</p>
          <h2 class="mt-1 text-xl font-semibold text-slate-900">{group.details.display_name}</h2>
          <p class="mt-1 text-sm text-slate-600">
            {group.batch_count} allocation batch(es), {group.remaining_quantity} {group.uom} remaining
          </p>
        </div>

        <div class="divide-y divide-slate-100 rounded-xl border border-slate-200 overflow-hidden">
          <%= for allocation <- group.allocations do %>
            <% details = Nursing.allocation_item_details(allocation) %>
            <% batch =
              (allocation.inventory_issued && allocation.inventory_issued.batch) || allocation.batch %>
            <% status = get_status_info(allocation) %>
            <.link
              navigate={~p"/nurse/allocations/#{allocation}"}
              class="block p-4 hover:bg-slate-50 transition-colors"
            >
              <div class="flex items-start justify-between gap-4">
                <div class="min-w-0">
                  <div class="flex flex-wrap items-center gap-2">
                    <h3 class="font-semibold text-slate-900">
                      Batch {details.batch_number || "—"}
                    </h3>
                    <span class={"px-2 py-0.5 rounded-full text-xs font-medium #{status.color}"}>
                      {status.label}
                    </span>
                  </div>
                  <div class="mt-2 grid grid-cols-1 gap-1 text-sm text-slate-600 sm:grid-cols-2">
                    <p>
                      Nurse: {(allocation.allocated_to_user && allocation.allocated_to_user.name) ||
                        "—"}
                    </p>
                    <p>GTIN: {details.gtin || "—"}</p>
                    <p>Allocated: {allocation.allocated_quantity} {allocation.uom}</p>
                    <p>Remaining: {allocation.remaining_quantity} {allocation.uom}</p>
                    <p>Consumed: {Map.get(allocation, :total_consumed, 0)} {allocation.uom}</p>
                    <p>Expiry: {format_batch_expiry(allocation, batch)}</p>
                  </div>
                </div>
                <div class="flex-shrink-0 text-[#373896]">
                  <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 5l7 7-7 7"
                    />
                  </svg>
                </div>
              </div>
            </.link>
          <% end %>
        </div>

        <div class="flex justify-end">
          <button
            type="button"
            phx-click="close-batch-selector"
            class="rounded-lg bg-slate-100 px-4 py-2 text-sm font-semibold text-slate-700 hover:bg-slate-200"
          >
            Cancel
          </button>
        </div>
      </div>
    </.modal>

    <.modal
      :if={@live_action == :new}
      id="nursing_allocation-modal"
      show
      on_cancel={JS.patch(~p"/nurse/allocations")}
    >
      <.live_component
        module={MedcampWeb.NursingAllocationLive.FormComponent}
        id={:new}
        title={@page_title}
        action={@live_action}
        nursing_allocation={@nursing_allocation}
        patch={~p"/nurse/allocations"}
      />
    </.modal>
    """
  end
end
