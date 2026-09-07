defmodule MedcampWeb.PharmacistsLive.DrugsIndex do
  use MedcampWeb, :pharmacist_live_view

  alias Medcamp.Drugs
  alias Medcamp.Drugs.Drug
  alias Medcamp.ExpiryFilter

  @per_page 10

  @impl true
  def mount(params, _session, socket) do
    socket =
      socket
      |> assign(:active_tab, :drugs)
      |> assign(:page_title, "Listing Drugs")
      |> assign(:drug, nil)
      |> assign(:page, 1)
      |> assign(:per_page, @per_page)
      |> assign(:categories, Drugs.list_drug_categories_for_selection())
      |> assign(:types, Drugs.list_drug_types_for_selection())
      |> assign(:suppliers, Drugs.list_drug_suppliers_for_selection())
      |> assign_filters_from_params(params)
      |> load_drugs()

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Drug")
    |> assign(:drug, Drugs.get_drug!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Drug")
    |> assign(:drug, %Drug{})
  end

  defp apply_action(socket, :index, params) do
    socket
    |> assign(:page_title, "Listing Drugs")
    |> assign(:drug, nil)
    |> assign_filters_from_params(params)
    |> load_drugs()
  end

  defp default_filters do
    %{
      item_search: "",
      category: "",
      supplier: "",
      type: "",
      expiry_status: "",
      expiry_from: "",
      expiry_to: "",
      otc_filter: :all,
      dda_filter: :all,
      stock_filter: :all
    }
  end

  defp assign_filters_from_params(socket, params) do
    params = params || %{}

    stock_filter =
      parse_filter_param(
        params["stock_filter"],
        [:all, :in_stock, :low_stock, :out_of_stock],
        :all
      )

    otc_filter = parse_filter_param(params["otc_filter"], [:all, :otc, :non_otc], :all)
    dda_filter = parse_filter_param(params["dda_filter"], [:all, :dda, :non_dda], :all)

    filters = %{
      item_search: params["item_search"] || params["search"] || "",
      category: params["category"] || "",
      supplier: params["supplier"] || "",
      type: params["type"] || "",
      expiry_status: ExpiryFilter.normalize(params["expiry_status"]),
      expiry_from: params["expiry_from"] || "",
      expiry_to: params["expiry_to"] || "",
      otc_filter: otc_filter,
      dda_filter: dda_filter,
      stock_filter: stock_filter
    }

    socket
    |> assign(:filters, filters)
    |> assign(:stock_filter, stock_filter)
    |> assign(:otc_filter, otc_filter)
    |> assign(:dda_filter, dda_filter)
    |> assign(:search_query, filters.item_search)
  end

  defp parse_filter_param(nil, _allowed, default), do: default

  defp parse_filter_param(value, allowed, default) when is_binary(value) do
    atom = String.to_existing_atom(value)
    if atom in allowed, do: atom, else: default
  rescue
    ArgumentError -> default
  end

  defp load_drugs(socket) do
    query_filters = filters_to_query(socket.assigns)
    total_count = Drugs.count_drugs(query_filters)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)
    drugs = Drugs.filter_drugs_paginated(query_filters, page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:drugs, drugs)
  end

  defp filters_to_query(assigns) do
    filters = assigns[:filters] || default_filters()

    %{
      "item_search" => filters[:item_search],
      "category" => filters[:category],
      "supplier" => filters[:supplier],
      "type" => filters[:type],
      "expiry_status" => filters[:expiry_status],
      "expiry_from" => filters[:expiry_from],
      "expiry_to" => filters[:expiry_to],
      "otc_filter" => filters[:otc_filter],
      "dda_filter" => filters[:dda_filter]
    }
  end

  defp filters_to_params(filters) do
    %{}
    |> maybe_put("item_search", filters[:item_search], "")
    |> maybe_put("category", filters[:category], "")
    |> maybe_put("supplier", filters[:supplier], "")
    |> maybe_put("type", filters[:type], "")
    |> maybe_put("expiry_status", filters[:expiry_status], "")
    |> maybe_put("expiry_from", filters[:expiry_from], "")
    |> maybe_put("expiry_to", filters[:expiry_to], "")
    |> maybe_put("otc_filter", filters[:otc_filter], :all)
    |> maybe_put("dda_filter", filters[:dda_filter], :all)
    |> maybe_put("stock_filter", filters[:stock_filter], :all)
  end

  defp maybe_put(map, _key, value, default) when value == default, do: map
  defp maybe_put(map, _key, "", _default), do: map
  defp maybe_put(map, key, value, _default), do: Map.put(map, key, to_string(value))

  defp filters_path(filters) do
    params = filters_to_params(filters)
    path = ~p"/pharmacist/drugs"
    if params == %{}, do: path, else: path <> "?" <> URI.encode_query(params)
  end

  # The item-search box and the filter drawer submit independently (two
  # separate <form>s), so a submission from either one only carries its own
  # fields. Merging onto the stringified current filters means a key absent
  # from this submission is left unchanged rather than reset — this also
  # keeps the push_patch URL below reflecting the complete filter set, not
  # just whichever field just changed.
  defp stringify_filters(filters) do
    Map.new(filters, fn {key, value} -> {Atom.to_string(key), stringify_value(value)} end)
  end

  defp stringify_value(nil), do: ""
  defp stringify_value(value) when is_atom(value), do: Atom.to_string(value)
  defp stringify_value(value), do: value

  defp count_active_filters(filters) do
    filters
    |> Map.drop([:item_search])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, "", :all]))
  end

  defp filter_chips(filters) do
    [
      filter_chip(filters[:category], "category", filters[:category]),
      filter_chip(filters[:supplier], "supplier", filters[:supplier]),
      filter_chip(filters[:type], "type", filters[:type]),
      filter_chip(
        filters[:expiry_status],
        "expiry_status",
        "Expiry: #{ExpiryFilter.label(filters[:expiry_status])}"
      ),
      filter_chip(filters[:expiry_from], "expiry_from", "Expiry from #{filters[:expiry_from]}"),
      filter_chip(filters[:expiry_to], "expiry_to", "Expiry to #{filters[:expiry_to]}"),
      filter_chip(filters[:otc_filter], "otc_filter", otc_label(filters[:otc_filter]), [:all]),
      filter_chip(filters[:dda_filter], "dda_filter", dda_label(filters[:dda_filter]), [:all]),
      filter_chip(
        filters[:stock_filter],
        "stock_filter",
        stock_label(filters[:stock_filter]),
        [:all]
      )
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp otc_label(:otc), do: "OTC"
  defp otc_label(:non_otc), do: "Non-OTC"
  defp otc_label(other), do: to_string(other)

  defp dda_label(:dda), do: "DDA"
  defp dda_label(:non_dda), do: "Non-DDA"
  defp dda_label(other), do: to_string(other)

  defp stock_label(:in_stock), do: "In Stock"
  defp stock_label(:low_stock), do: "Low Stock"
  defp stock_label(:out_of_stock), do: "Out of Stock"
  defp stock_label(other), do: to_string(other)

  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    filters = Map.merge(stringify_filters(socket.assigns.filters), filters)

    new_filters = %{
      item_search: filters["item_search"] || "",
      category: filters["category"] || "",
      supplier: filters["supplier"] || "",
      type: filters["type"] || "",
      expiry_status: ExpiryFilter.normalize(filters["expiry_status"]),
      expiry_from: filters["expiry_from"] || "",
      expiry_to: filters["expiry_to"] || "",
      otc_filter: parse_filter_param(filters["otc_filter"], [:all, :otc, :non_otc], :all),
      dda_filter: parse_filter_param(filters["dda_filter"], [:all, :dda, :non_dda], :all),
      stock_filter:
        parse_filter_param(
          filters["stock_filter"],
          [:all, :in_stock, :low_stock, :out_of_stock],
          :all
        )
    }

    {:noreply,
     socket
     |> assign(:filters, new_filters)
     |> assign(:stock_filter, new_filters.stock_filter)
     |> assign(:otc_filter, new_filters.otc_filter)
     |> assign(:dda_filter, new_filters.dda_filter)
     |> assign(:search_query, new_filters.item_search)
     |> assign(:page, 1)
     |> load_drugs()
     |> push_patch(to: filters_path(new_filters))}
  end

  # Either form (search box or filter drawer) can submit without a "filters"
  # map — e.g. an apply with no changed fields. Treat it as an empty set so
  # the merge onto the current filters preserves them rather than crashing.
  def handle_event("filter", params, socket) when is_map(params) do
    handle_event("filter", %{"filters" => %{}}, socket)
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    default = default_filters()

    {:noreply,
     socket
     |> assign(:filters, default)
     |> assign(:stock_filter, :all)
     |> assign(:otc_filter, :all)
     |> assign(:dda_filter, :all)
     |> assign(:search_query, "")
     |> assign(:page, 1)
     |> load_drugs()
     |> push_patch(to: ~p"/pharmacist/drugs")}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    default = %{
      "category" => "",
      "supplier" => "",
      "type" => "",
      "expiry_status" => "",
      "expiry_from" => "",
      "expiry_to" => "",
      "otc_filter" => "all",
      "dda_filter" => "all",
      "stock_filter" => "all"
    }

    handle_event("filter", %{"filters" => Map.take(default, [field])}, socket)
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, socket |> assign(:page, max(1, String.to_integer(page))) |> load_drugs()}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    drug = Drugs.get_drug!(id)
    {:ok, _} = Drugs.delete_drug(drug)

    {:noreply, load_drugs(socket)}
  end

  defp batch_expired?(nil), do: false

  defp batch_expired?(expiry_string) when is_binary(expiry_string) do
    case Date.from_iso8601(expiry_string) do
      {:ok, expiry_date} -> Date.compare(expiry_date, Date.utc_today()) == :lt
      _ -> false
    end
  end

  defp batch_expired?(_), do: false

  defp count_expired_batches(drug) do
    drug.drug_batches
    |> List.wrap()
    |> Enum.count(fn db ->
      batch = db.batch || db[:batch]
      batch && batch_expired?(batch.expiry)
    end)
  end

  defp calculate_total_stock(drug) do
    Enum.sum(Enum.map(drug.drug_batches || [], & &1.remaining_quantity))
  end

  # `drug.drug_batches` is preloaded newest-first, so the first entry with a
  # batch is the drug's current price.
  defp latest_batch_price(drug) do
    drug.drug_batches
    |> List.wrap()
    |> Enum.find_value(fn db ->
      batch = db.batch || db[:batch]
      batch && batch.price_per_unit
    end)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.page_header
        icon_path="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
        title="Drugs"
        subtitle="Search, filter and manage the drug inventory."
      />

      <div class="flex flex-wrap items-center gap-3 mb-4">
        <form phx-change="filter" class="flex-1">
          <.search_input
            name="filters[item_search]"
            value={@filters[:item_search]}
            placeholder="Search by brand, generic name, or GTIN"
          />
        </form>

        <.filter_drawer
          id="drugs-filters"
          title="Filter drugs"
          apply_event="filter"
          active_count={count_active_filters(@filters)}
        >
          <:group label="Item Details">
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
          </:group>

          <:group label="Expiry">
            <.expiry_filter_fields
              status_value={@filters[:expiry_status]}
              from_value={@filters[:expiry_from]}
              to_value={@filters[:expiry_to]}
            />
          </:group>

          <:group label="Stock & Registers">
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Stock Status</label>
              <select
                name="filters[stock_filter]"
                class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
              >
                <option value="all" selected={@stock_filter == :all}>All</option>
                <option value="in_stock" selected={@stock_filter == :in_stock}>In Stock</option>
                <option value="low_stock" selected={@stock_filter == :low_stock}>Low Stock</option>
                <option value="out_of_stock" selected={@stock_filter == :out_of_stock}>
                  Out of Stock
                </option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">DDA Register</label>
              <select
                name="filters[dda_filter]"
                class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
              >
                <option value="all" selected={@filters[:dda_filter] == :all}>All Drugs</option>
                <option value="dda" selected={@filters[:dda_filter] == :dda}>DDA Only</option>
                <option value="non_dda" selected={@filters[:dda_filter] == :non_dda}>
                  Not in DDA
                </option>
              </select>
            </div>
          </:group>

          <:chip
            :for={chip <- filter_chips(@filters)}
            label={chip.label}
            clear={JS.push("clear_chip", value: %{"field" => chip.field})}
          />
        </.filter_drawer>
      </div>

      <%= if @total_count == 0 do %>
        <.blank_state
          icon_path="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
          title="No drugs found"
        >
          <:description_slot>
            <%= cond do %>
              <% @otc_filter == :otc -> %>
                No OTC drugs found.
              <% @otc_filter == :non_otc -> %>
                No non-OTC drugs found.
              <% @dda_filter == :dda -> %>
                No drugs are currently marked for DDA.
              <% @dda_filter == :non_dda -> %>
                All matching drugs are already marked for DDA.
              <% @filters[:expiry_status] != "" or @filters[:expiry_from] != "" or
                   @filters[:expiry_to] != "" -> %>
                No drugs have batches in the selected expiry window.
              <% @stock_filter == :in_stock -> %>
                No drugs with sufficient stock found.
              <% @stock_filter == :low_stock -> %>
                No drugs with low stock found.
              <% @stock_filter == :out_of_stock -> %>
                No drugs are out of stock.
              <% true -> %>
                No drugs have been added to the inventory yet.
            <% end %>
          </:description_slot>
          <:actions :if={@search_query != "" or count_active_filters(@filters) > 0}>
            <button phx-click="clear_filters" class="text-xs text-[#6667ab] hover:underline">
              Clear filters
            </button>
          </:actions>
        </.blank_state>
      <% else %>
        <.table
          id="drugs"
          rows={@drugs}
          row_click={fn drug -> JS.navigate(~p"/pharmacist/drugs/#{drug}") end}
          row_id={&"drugs-#{&1.id}"}
        >
          <:col :let={drug} label="Generic Name">
            <div class="flex min-w-0 items-center py-3">
              <span class="font-medium text-gray-900 break-words">
                {drug.generic_name || drug.inventory_received.generic_name}
              </span>
            </div>
          </:col>

          <:col :let={drug} label="Brand Name">
            <div class="flex min-w-0 items-center py-3">
              <span class="text-gray-700 break-words">
                {drug.inventory_received.strength} {drug.brand_name ||
                  drug.inventory_received.brand_name}
              </span>
            </div>
          </:col>

          <:col :let={drug} label="Price">
            <div class="flex items-center py-3">
              <% price = latest_batch_price(drug) %>
              <span :if={price} class="font-medium text-gray-900">
                KSh {Number.Delimit.number_to_delimited(price, delimiter: ",")}
              </span>
              <span :if={!price} class="text-gray-400">—</span>
            </div>
          </:col>

          <:col :let={drug} label="Stock Remaining">
            <div class="flex items-center py-3">
              <% total_stock = calculate_total_stock(drug) %>
              <%= cond do %>
                <% total_stock == 0 -> %>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 text-red-800">
                    <svg class="w-2 h-2 mr-1" fill="currentColor" viewBox="0 0 8 8">
                      <circle cx="4" cy="4" r="3" />
                    </svg>
                    Out of Stock
                  </span>
                <% total_stock < 20 -> %>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-orange-100 text-orange-800">
                    <svg class="w-2 h-2 mr-1" fill="currentColor" viewBox="0 0 8 8">
                      <circle cx="4" cy="4" r="3" />
                    </svg>
                    {total_stock} units (Low Stock)
                  </span>
                <% true -> %>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                    <svg class="w-2 h-2 mr-1" fill="currentColor" viewBox="0 0 8 8">
                      <circle cx="4" cy="4" r="3" />
                    </svg>
                    {total_stock} units
                  </span>
              <% end %>
            </div>
          </:col>

          <:col :let={drug} label="OTC">
            <div class="flex items-center py-3">
              <%= if drug.is_otc do %>
                <span class="px-2 py-1 text-xs rounded-full bg-green-100 text-green-800 font-medium">
                  OTC
                </span>
              <% else %>
                <span class="px-2 py-1 text-xs rounded-full bg-gray-100 text-gray-600 font-medium">
                  Non-OTC
                </span>
              <% end %>
            </div>
          </:col>

          <:col :let={drug} label="DDA">
            <div class="flex items-center py-3">
              <%= if drug.is_dangerous_drug do %>
                <span class="px-2 py-1 text-xs rounded-full bg-orange-100 text-orange-800 font-medium">
                  In DDA
                </span>
              <% else %>
                <span class="px-2 py-1 text-xs rounded-full bg-gray-100 text-gray-600 font-medium">
                  Not in DDA
                </span>
              <% end %>
            </div>
          </:col>

          <:col :let={drug} label="Expired Batches">
            <div class="flex items-center py-3">
              <% expired_count = count_expired_batches(drug) %>
              <%= if expired_count > 0 do %>
                <span class="px-2 py-1 text-xs rounded-full bg-amber-100 text-amber-800 font-medium">
                  {expired_count} expired
                </span>
              <% else %>
                <span class="px-2 py-1 text-xs rounded-full bg-gray-100 text-gray-500 font-medium">
                  None
                </span>
              <% end %>
            </div>
          </:col>

          <:col :let={drug} label="Batches">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-[#f0f0ff] text-[#373896] font-medium">
                {length(drug.drug_batches)} batches
              </span>
            </div>
          </:col>

          <:action :let={drug}>
            <div class="flex items-center justify-center">
              <.link
                navigate={~p"/pharmacist/drugs/#{drug}"}
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
                    d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
                  />
                </svg>
                View Batches
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
        id="drug-modal"
        show
        on_cancel={JS.patch(filters_path(@filters))}
      >
        <.live_component
          module={MedcampWeb.PharmacistsLive.DrugFormComponent}
          id={@drug.id || :new}
          title={@page_title}
          action={@live_action}
          drug={@drug}
          current_user={@current_user}
          patch={~p"/pharmacist/drugs"}
        />
      </.modal>
    </div>
    """
  end
end
