defmodule MedcampWeb.Procurement.PoListLive do
  use MedcampWeb, :procurement_live_view

  import MedcampWeb.ProcurementComponents, only: [status_badge: 1]

  alias Medcamp.Procurement.{PurchaseOrder, PurchaseOrders}
  alias MedcampWeb.Procurement.LiveHelpers

  @refresh_events ~w(po_pending_approval po_approved po_sent po_acknowledged invoice_approved)a
  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    filters = %{"search" => "", "status" => ""}

    {:ok,
     socket
     |> assign(:page_title, "Purchase Orders")
     |> assign(:filters, filters)
     |> assign(:statuses, PurchaseOrder.statuses())
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign_purchase_orders(filters, 1)}
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
     |> assign_purchase_orders(filters, 1)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    filters = %{"search" => "", "status" => ""}

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_purchase_orders(filters, 1)}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    filters = Map.put(socket.assigns.filters, field, "")

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_purchase_orders(filters, 1)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_purchase_orders(socket, socket.assigns.filters, page)}
  end

  @impl true
  def handle_info({event, _payload}, socket) when event in @refresh_events do
    {:noreply, assign_purchase_orders(socket, socket.assigns.filters, socket.assigns.page)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp assign_purchase_orders(socket, filters, page) do
    page = normalize_page(page)
    query_filters = po_filters(filters)
    total_count = PurchaseOrders.count_purchase_orders(query_filters)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    purchase_orders =
      PurchaseOrders.list_purchase_orders_paginated(query_filters, page, @per_page)

    socket
    |> assign(:filters, filters)
    |> assign(:page, page)
    |> assign(:per_page, @per_page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:purchase_orders, purchase_orders)
  end

  defp po_filters(filters) do
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
        icon_path="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
        title="Purchase Orders"
        subtitle="See every PO, track approval and sending progress, and open each order for the checklist and line-item view."
      >
        <:actions>
          <.link
            navigate={~p"/procurement/purchase-orders/new"}
            class="inline-flex rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
          >
            Create PO
          </.link>
        </:actions>
      </.page_header>

      <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
        <div class="mb-6 rounded-2xl border border-emerald-200 bg-emerald-50 px-4 py-4 text-sm text-emerald-800">
          Purchase orders sit after quote review. If a user is looking for the sourcing stage, start in requests for quotation, not in the PO register.
        </div>

        <div class="flex flex-wrap items-center gap-3">
          <form phx-change="filter" class="flex-1">
            <.search_input
              name="filters[search]"
              value={@filters["search"]}
              placeholder="Search by reference, supplier, or request for quotation"
            />
          </form>

          <.filter_drawer
            id="purchase-orders-filters"
            title="Filter purchase orders"
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
                <th class="pb-3 pr-4 font-semibold">PO date</th>
                <th class="pb-3 pr-4 font-semibold">Expected delivery</th>
                <th class="pb-3 pr-4 font-semibold">Total</th>
                <th class="pb-3 pr-4 font-semibold">Status</th>
                <th class="pb-3 font-semibold text-right">Action</th>
              </tr>
            </thead>
            <tbody :if={@purchase_orders == []} class="divide-y divide-slate-100">
              <tr>
                <td class="py-4 pr-4">
                  <p class="font-medium text-slate-900">
                    {if (@filters["search"] || "") != "" or count_active_filters(@filters) > 0,
                      do: "No purchase orders match the current filters",
                      else: "No purchase orders available"}
                  </p>
                  <p class="mt-1 text-xs text-slate-400">—</p>
                </td>
                <td class="py-4 pr-4 text-slate-400">—</td>
                <td class="py-4 pr-4 text-slate-400">—</td>
                <td class="py-4 pr-4 text-slate-400">—</td>
                <td class="py-4 pr-4 text-slate-400">—</td>
                <td class="py-4 pr-4">
                  <span class="inline-flex rounded-full bg-[#f0f0ff] px-2 py-1 text-xs font-medium text-gray-400">
                    —
                  </span>
                </td>
                <td class="py-4 text-right text-slate-400">—</td>
              </tr>
            </tbody>
            <tbody :if={@purchase_orders != []} class="divide-y divide-slate-100">
              <tr :for={purchase_order <- @purchase_orders}>
                <td class="py-4 pr-4">
                  <p class="font-medium text-slate-900">{purchase_order.reference}</p>
                  <p class="mt-1 text-xs text-slate-500">
                    {if purchase_order.rfq, do: purchase_order.rfq.reference, else: "Manual PO"}
                  </p>
                </td>
                <td class="py-4 pr-4 text-slate-600">
                  {purchase_order.supplier &&
                    (purchase_order.supplier.legal_name || purchase_order.supplier.name)}
                </td>
                <td class="py-4 pr-4 text-slate-600">
                  {LiveHelpers.format_date(purchase_order.po_date)}
                </td>
                <td class="py-4 pr-4 text-slate-600">
                  {LiveHelpers.format_date(purchase_order.expected_delivery_date)}
                </td>
                <td class="py-4 pr-4 text-slate-600">{LiveHelpers.money(purchase_order.total)}</td>
                <td class="py-4 pr-4"><.status_badge status={purchase_order.status} /></td>
                <td class="py-4 text-right">
                  <.link
                    navigate={~p"/procurement/purchase-orders/#{purchase_order.id}"}
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
