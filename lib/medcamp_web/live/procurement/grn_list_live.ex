defmodule MedcampWeb.Procurement.GrnListLive do
  use MedcampWeb, :procurement_live_view

  import MedcampWeb.ProcurementComponents, only: [status_badge: 1]

  alias Medcamp.Procurement.{GoodsReceived, GoodsReceivedNote}
  alias MedcampWeb.Procurement.LiveHelpers

  @refresh_events ~w(grn_flagged grn_finalised invoice_grn_confirmed)a
  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    filters = %{"search" => "", "status" => ""}

    {:ok,
     socket
     |> assign(:page_title, "GRN Register")
     |> assign(:filters, filters)
     |> assign(:statuses, GoodsReceivedNote.statuses())
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign_grns(filters, 1)}
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto the current filters means a key absent from this submission
  # is left unchanged rather than reset.
  @impl true
  def handle_event("filter", %{"filters" => filters}, socket) do
    filters = Map.merge(socket.assigns.filters, filters)

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_grns(filters, 1)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    filters = %{"search" => "", "status" => ""}

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_grns(filters, 1)}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    filters = Map.put(socket.assigns.filters, field, "")

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_grns(filters, 1)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_grns(socket, socket.assigns.filters, page)}
  end

  @impl true
  def handle_info({event, _payload}, socket) when event in @refresh_events do
    {:noreply, assign_grns(socket, socket.assigns.filters, socket.assigns.page)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp assign_grns(socket, filters, page) do
    page = normalize_page(page)
    query_filters = grn_filters(filters)
    total_count = GoodsReceived.count_grns(query_filters)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    grns = GoodsReceived.list_grns_paginated(query_filters, page, @per_page)

    socket
    |> assign(:filters, filters)
    |> assign(:page, page)
    |> assign(:per_page, @per_page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:grns, grns)
  end

  defp grn_filters(filters) do
    %{}
    |> maybe_put_filter(:status, filters["status"])
    |> maybe_put_filter(:search, filters["search"])
  end

  defp maybe_put_filter(map, _key, nil), do: map
  defp maybe_put_filter(map, _key, ""), do: map
  defp maybe_put_filter(map, key, value), do: Map.put(map, key, value)

  defp count_active_filters(filters) do
    filters
    |> Map.drop(["search"])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp status_label(status), do: status |> String.replace("_", " ") |> String.capitalize()

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.page_header
        icon_path="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
        title="Goods Received Notes"
        subtitle="View every GRN raised in procurement, filter by status, and open any note for the full receipt detail."
      />

      <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex flex-wrap items-center gap-3">
          <form phx-change="filter" class="flex-1">
            <.search_input
              name="filters[search]"
              value={@filters["search"]}
              placeholder="Search by GRN, supplier, invoice, or staff name"
            />
          </form>

          <.filter_drawer
            id="grn-filters"
            title="Filter GRNs"
            apply_event="filter"
            active_count={count_active_filters(@filters)}
          >
            <:group label="Status">
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Status</label>
                <select
                  name="filters[status]"
                  class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
                >
                  <option value="">All statuses</option>
                  <option
                    :for={status <- @statuses}
                    value={status}
                    selected={@filters["status"] == status}
                  >
                    {status |> String.replace("_", " ") |> String.capitalize()}
                  </option>
                </select>
              </div>
            </:group>

            <:chip
              :if={@filters["status"] not in [nil, ""]}
              label={status_label(@filters["status"])}
              clear={JS.push("clear_chip", value: %{"field" => "status"})}
            />
          </.filter_drawer>
        </div>

        <div class="mt-6 overflow-x-auto">
          <table class="min-w-full text-left text-sm">
            <thead class="border-b border-slate-200 text-slate-500">
              <tr>
                <th class="pb-3 pr-4 font-semibold">Reference</th>
                <th class="pb-3 pr-4 font-semibold">Supplier</th>
                <th class="pb-3 pr-4 font-semibold">Invoice</th>
                <th class="pb-3 pr-4 font-semibold">Received date</th>
                <th class="pb-3 pr-4 font-semibold">Status</th>
                <th class="pb-3 pr-4 font-semibold">Finalised</th>
                <th class="pb-3 font-semibold text-right">Action</th>
              </tr>
            </thead>
            <tbody :if={@grns == []} class="divide-y divide-slate-100">
              <tr>
                <td class="py-4 pr-4">
                  <p class="font-medium text-slate-900">
                    {if (@filters["search"] || "") != "" or count_active_filters(@filters) > 0,
                      do: "No GRNs match the current filters",
                      else: "No GRNs available"}
                  </p>
                  <p class="mt-1 text-xs text-slate-400">—</p>
                </td>
                <td class="py-4 pr-4 text-slate-400">—</td>
                <td class="py-4 pr-4 text-slate-400">—</td>
                <td class="py-4 pr-4 text-slate-400">—</td>
                <td class="py-4 pr-4">
                  <span class="inline-flex rounded-full bg-[#f0f0ff] px-2 py-1 text-xs font-medium text-gray-400">
                    —
                  </span>
                </td>
                <td class="py-4 pr-4 text-slate-400">—</td>
                <td class="py-4 text-right text-slate-400">—</td>
              </tr>
            </tbody>
            <tbody :if={@grns != []} class="divide-y divide-slate-100">
              <tr :for={grn <- @grns}>
                <td class="py-4 pr-4">
                  <p class="font-medium text-slate-900">{grn.reference}</p>
                  <p class="mt-1 text-xs text-slate-500">
                    Received by {(grn.received_by && grn.received_by.name) || "Unassigned"}
                  </p>
                </td>
                <td class="py-4 pr-4 text-slate-600">
                  {grn.supplier && (grn.supplier.legal_name || grn.supplier.name)}
                </td>
                <td class="py-4 pr-4 text-slate-600">
                  {(grn.invoice && grn.invoice.reference) || "N/A"}
                </td>
                <td class="py-4 pr-4 text-slate-600">
                  {LiveHelpers.format_date(grn.received_date)}
                </td>
                <td class="py-4 pr-4"><.status_badge status={grn.status} /></td>
                <td class="py-4 pr-4 text-slate-600">
                  {if grn.finalised_at,
                    do: LiveHelpers.format_datetime(grn.finalised_at),
                    else: "Pending"}
                </td>
                <td class="py-4 text-right">
                  <.link
                    navigate={~p"/procurement/grn/#{grn.id}"}
                    class="text-sm font-semibold text-[#373896] hover:text-[#2d2d7a]"
                  >
                    Open
                  </.link>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
          show_when_empty={true}
        />
      </div>
    </div>
    """
  end

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, _} when value > 0 -> value
      _ -> 1
    end
  end

  defp normalize_page(page) when is_integer(page) and page > 0, do: page
  defp normalize_page(_), do: 1
end
