defmodule MedcampWeb.AdminDrugsLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.Drugs
  alias Medcamp.ExpiryFilter
  alias Medcamp.StockAlerts

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :admin_drugs)
     |> assign(:drug_filters, default_drug_filters())
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:categories, Drugs.list_drug_categories_for_selection())
     |> assign(:types, Drugs.list_drug_types_for_selection())
     |> assign(:suppliers, Drugs.list_drug_suppliers_for_selection())
     |> load_drugs()}
  end

  defp default_drug_filters do
    %{
      item_search: "",
      category: "",
      supplier: "",
      type: "",
      expiry_status: "",
      expiry_from: "",
      expiry_to: "",
      otc_filter: "all"
    }
  end

  # The item-search box and the filter drawer submit independently (two
  # separate <form>s), so a submission from either one only carries its own
  # fields. Merging onto the current filters means a key absent from this
  # submission is left unchanged rather than reset.
  defp stringify_filters(filters), do: Map.new(filters, fn {k, v} -> {Atom.to_string(k), v} end)

  defp count_active_filters(filters) do
    filters
    |> Map.drop([:item_search])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, "", "all"]))
  end

  defp filter_chips(filters) do
    [
      filter_chip(filters.category, "category", filters.category),
      filter_chip(filters.supplier, "supplier", filters.supplier),
      filter_chip(filters.type, "type", filters.type),
      filter_chip(
        filters.expiry_status,
        "expiry_status",
        "Expiry: #{ExpiryFilter.label(filters.expiry_status)}"
      ),
      filter_chip(filters.expiry_from, "expiry_from", "Expiry from #{filters.expiry_from}"),
      filter_chip(filters.expiry_to, "expiry_to", "Expiry to #{filters.expiry_to}"),
      filter_chip(filters.otc_filter, "otc_filter", otc_label(filters.otc_filter), ["all"])
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp otc_label("otc"), do: "OTC"
  defp otc_label("non_otc"), do: "Non-OTC"
  defp otc_label(other), do: other

  @impl true
  def handle_event("filter_drugs", %{"filters" => filters}, socket) do
    filters = Map.merge(stringify_filters(socket.assigns.drug_filters), filters)

    params = %{
      "item_search" => filters["item_search"] || "",
      "category" => filters["category"] || "",
      "supplier" => filters["supplier"] || "",
      "type" => filters["type"] || "",
      "expiry_status" => ExpiryFilter.normalize(filters["expiry_status"]),
      "expiry_from" => filters["expiry_from"] || "",
      "expiry_to" => filters["expiry_to"] || "",
      "otc_filter" => filters["otc_filter"] || "all"
    }

    {:noreply,
     socket
     |> assign(:drug_filters, %{
       item_search: params["item_search"],
       category: params["category"],
       supplier: params["supplier"],
       type: params["type"],
       expiry_status: params["expiry_status"],
       expiry_from: params["expiry_from"],
       expiry_to: params["expiry_to"],
       otc_filter: params["otc_filter"]
     })
     |> assign(:page, 1)
     |> load_drugs(params)}
  end

  def handle_event("clear_filters_drugs", _, socket) do
    {:noreply,
     socket
     |> assign(:drug_filters, default_drug_filters())
     |> assign(:page, 1)
     |> load_drugs()}
  end

  def handle_event("clear_chip", %{"field" => field}, socket) do
    default = if field == "otc_filter", do: "all", else: ""
    handle_event("filter_drugs", %{"filters" => %{field => default}}, socket)
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, socket |> assign(:page, max(1, String.to_integer(page))) |> load_drugs()}
  end

  @low_stock_threshold 20

  defp total_remaining(drug) do
    batches = drug.drug_batches || []

    if batches == [] do
      "—"
    else
      Enum.reduce(batches, 0, fn db, acc -> acc + (db.remaining_quantity || 0) end)
    end
  end

  defp total_remaining_int(drug) do
    case total_remaining(drug) do
      "—" -> 0
      n when is_integer(n) -> n
    end
  end

  defp low_stock?(drug),
    do: total_remaining_int(drug) < @low_stock_threshold and total_remaining_int(drug) >= 0

  defp load_drugs(socket, filters \\ nil) do
    filters = filters || socket.assigns.drug_filters
    page = socket.assigns.page
    per_page = socket.assigns.per_page

    query_filters = %{
      "item_search" => filters[:item_search] || filters["item_search"] || "",
      "category" => filters[:category] || filters["category"] || "",
      "supplier" => filters[:supplier] || filters["supplier"] || "",
      "type" => filters[:type] || filters["type"] || "",
      "expiry_status" => filters[:expiry_status] || filters["expiry_status"] || "",
      "expiry_from" => filters[:expiry_from] || filters["expiry_from"] || "",
      "expiry_to" => filters[:expiry_to] || filters["expiry_to"] || "",
      "otc_filter" => filters[:otc_filter] || filters["otc_filter"] || "all",
      "dda_filter" => "all"
    }

    total_count = Drugs.count_drugs(query_filters)
    total_pages = Medcamp.Pagination.total_pages(total_count, per_page)
    page = min(max(1, page), total_pages)
    drugs = Drugs.filter_drugs_paginated(query_filters, page, per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:drugs, drugs)
  end

  attr :drug, :any, required: true

  defp batches_cell(assigns) do
    batches = assigns.drug.drug_batches || []
    assigns = assign(assigns, :batches, batches)

    ~H"""
    <%= if @batches == [] do %>
      <span class="text-slate-400">—</span>
    <% else %>
      <div class="flex flex-col gap-0.5 text-sm">
        <%= for db <- @batches do %>
          <% expiry_str = db.batch && db.batch.expiry %>
          <% near_exp = expiry_str && StockAlerts.near_expiry?(expiry_str) %>
          <% rem_qty = db.remaining_quantity || 0 %>
          <div class="flex items-baseline gap-2 flex-wrap">
            <span class="font-medium text-slate-700">{batch_label(db)}</span>
            <span class={if rem_qty == 0, do: "text-red-600 font-medium", else: "text-slate-600"}>
              → {rem_qty} remaining
            </span>
            <%= if near_exp do %>
              <span class="text-red-600 font-medium text-xs">(expiring soon)</span>
            <% end %>
          </div>
        <% end %>
      </div>
    <% end %>
    """
  end

  defp batch_label(drug_batch) do
    b = drug_batch.batch

    if b do
      [b.batch, b.serial, b.expiry]
      |> Enum.reject(&is_nil/1)
      |> Enum.map(&to_string/1)
      |> Enum.join(" · ")
      |> then(fn s -> if s == "", do: "Batch ##{drug_batch.id}", else: s end)
    else
      "Batch ##{drug_batch.id}"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <div class="space-y-4">
        <div class="bg-white rounded-lg shadow-sm border border-slate-100 p-4">
          <.page_header
            icon_path="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
            title="Drugs"
            subtitle="Search, filter and manage the drug inventory."
          />

          <div class="flex flex-wrap items-center gap-3">
            <form phx-change="filter_drugs" class="flex-1">
              <.search_input
                name="filters[item_search]"
                value={@drug_filters[:item_search]}
                placeholder="Search by name or GTIN"
              />
            </form>

            <.filter_drawer
              id="drugs-filters"
              title="Filter drugs"
              apply_event="filter_drugs"
              clear_event="clear_filters_drugs"
              active_count={count_active_filters(@drug_filters)}
            >
              <:group label="Item Details">
                <div>
                  <label class="block text-xs font-medium text-slate-600 mb-1">Category</label>
                  <select
                    name="filters[category]"
                    class="w-full h-9 border border-slate-300 rounded-md px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
                  >
                    <option value="" selected={@drug_filters[:category] in [nil, ""]}>All</option>
                    <option
                      :for={category <- @categories}
                      value={category}
                      selected={@drug_filters[:category] == category}
                    >
                      {category}
                    </option>
                  </select>
                </div>
                <div>
                  <label class="block text-xs font-medium text-slate-600 mb-1">Supplier</label>
                  <select
                    name="filters[supplier]"
                    class="w-full h-9 border border-slate-300 rounded-md px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
                  >
                    <option value="" selected={@drug_filters[:supplier] in [nil, ""]}>All</option>
                    <option
                      :for={supplier <- @suppliers}
                      value={supplier}
                      selected={@drug_filters[:supplier] == supplier}
                    >
                      {supplier}
                    </option>
                  </select>
                </div>
              </:group>

              <:group label="Type and OTC">
                <div>
                  <label class="block text-xs font-medium text-slate-600 mb-1">Type</label>
                  <select
                    name="filters[type]"
                    class="w-full h-9 border border-slate-300 rounded-md px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
                  >
                    <option value="" selected={@drug_filters[:type] in [nil, ""]}>All</option>
                    <option :for={type <- @types} value={type} selected={@drug_filters[:type] == type}>
                      {type}
                    </option>
                  </select>
                </div>
                <div>
                  <label class="block text-xs font-medium text-slate-600 mb-1">OTC</label>
                  <select
                    name="filters[otc_filter]"
                    class="w-full h-9 border border-slate-300 rounded-md px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
                  >
                    <option value="all" selected={@drug_filters[:otc_filter] == "all"}>All</option>
                    <option value="otc" selected={@drug_filters[:otc_filter] == "otc"}>
                      OTC only
                    </option>
                    <option value="non_otc" selected={@drug_filters[:otc_filter] == "non_otc"}>
                      Non-OTC only
                    </option>
                  </select>
                </div>
              </:group>

              <:group label="Expiry">
                <.expiry_filter_fields
                  status_value={@drug_filters[:expiry_status]}
                  from_value={@drug_filters[:expiry_from]}
                  to_value={@drug_filters[:expiry_to]}
                />
              </:group>

              <:chip
                :for={chip <- filter_chips(@drug_filters)}
                label={chip.label}
                clear={JS.push("clear_chip", value: %{"field" => chip.field})}
              />
            </.filter_drawer>
          </div>
        </div>
        <div class="bg-white rounded-lg shadow-sm border border-slate-100 overflow-x-auto">
          <.blank_state
            :if={@total_count == 0}
            icon_path="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
            title="No drugs found"
            description={
              if @drug_filters[:item_search] != "" or count_active_filters(@drug_filters) > 0,
                do: "No drugs match the current filters.",
                else: "No drugs have been added to the inventory yet."
            }
          >
            <:actions :if={
              @drug_filters[:item_search] != "" or count_active_filters(@drug_filters) > 0
            }>
              <button
                phx-click="clear_filters_drugs"
                class="text-xs text-brand-accent hover:underline"
              >
                Clear filters
              </button>
            </:actions>
          </.blank_state>
          <.data_table :if={@total_count > 0} id="drugs" rows={@drugs} row_id={&"drugs-#{&1.id}"}>
            <:col :let={drug} label="Brand name">{drug.brand_name || "—"}</:col>
            <:col :let={drug} label="Generic name">{drug.generic_name || "—"}</:col>
            <:col :let={drug} label="GTIN">
              {(drug.inventory_received && drug.inventory_received.gtin) || "—"}
            </:col>
            <:col :let={drug} label="Category">
              {(drug.inventory_received && drug.inventory_received.category) || "—"}
            </:col>
            <:col :let={drug} label="OTC">{if drug.is_otc, do: "Yes", else: "No"}</:col>
            <:col :let={drug} label="Total remaining">
              <span class={if low_stock?(drug), do: "text-red-600 font-semibold", else: ""}>
                {total_remaining(drug)}
              </span>
              <%= if low_stock?(drug) do %>
                <span class="text-red-600 text-xs ml-1">(low stock)</span>
              <% end %>
            </:col>
            <:col :let={drug} label="Batches">
              <.batches_cell drug={drug} />
            </:col>
          </.data_table>
          <.pagination
            page={@page}
            total_pages={@total_pages}
            total_count={@total_count}
            per_page={@per_page}
          />
        </div>
      </div>
    </div>
    """
  end
end
