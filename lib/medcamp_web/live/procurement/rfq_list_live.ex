defmodule MedcampWeb.Procurement.RfqListLive do
  use MedcampWeb, :procurement_live_view

  import MedcampWeb.ProcurementComponents, only: [status_badge: 1]

  alias Medcamp.Procurement.{Rfq, Rfqs}

  @refresh_events ~w(rfq_sent rfq_closed)a
  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    filters = %{"search" => "", "status" => ""}

    {:ok,
     socket
     |> assign(:page_title, "Requests for quotation")
     |> assign(:filters, filters)
     |> assign(:statuses, Rfq.statuses())
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign_rfqs(filters, 1)}
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
     |> assign_rfqs(filters, 1)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    filters = %{"search" => "", "status" => ""}

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_rfqs(filters, 1)}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    filters = Map.put(socket.assigns.filters, field, "")

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_rfqs(filters, 1)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_rfqs(socket, socket.assigns.filters, page)}
  end

  @impl true
  def handle_info({event, _payload}, socket) when event in @refresh_events do
    {:noreply, assign_rfqs(socket, socket.assigns.filters, socket.assigns.page)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp assign_rfqs(socket, filters, page) do
    page = normalize_page(page)
    query_filters = rfq_filters(filters)
    total_count = Rfqs.count_rfqs(query_filters)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    rfqs = Rfqs.list_rfqs_paginated(query_filters, page, @per_page)

    socket
    |> assign(:filters, filters)
    |> assign(:page, page)
    |> assign(:per_page, @per_page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:rfqs, rfqs)
  end

  defp rfq_filters(filters) do
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
        icon_path="M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 002.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 00-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25zM6.75 12h.008v.008H6.75V12zm0 3h.008v.008H6.75V15zm0 3h.008v.008H6.75V18z"
        title="Requests for Quotation"
        subtitle="Review every request for quotation in one place, check deadlines, and open each record for the full supplier and line-item detail."
      >
        <:actions>
          <.link
            navigate={~p"/procurement/rfqs/new"}
            class="inline-flex rounded-xl bg-[#373896] px-4 py-2.5 text-sm font-semibold text-white transition hover:bg-[#2d2d7a]"
          >
            Create request for quotation
          </.link>
        </:actions>
      </.page_header>

      <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
        <div class="mb-6 rounded-2xl border border-sky-200 bg-sky-50 px-4 py-4 text-sm text-sky-800">
          A request for quotation is the sourcing step. After suppliers submit quotes, open that request for quotation, compare the quotes, accept one, and only then create the PO.
        </div>

        <div class="flex flex-wrap items-center gap-3">
          <form phx-change="filter" class="flex-1">
            <.search_input
              name="filters[search]"
              value={@filters["search"]}
              placeholder="Search by reference, title, or department"
            />
          </form>

          <.filter_drawer
            id="rfqs-filters"
            title="Filter requests for quotation"
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
                <th class="pb-3 pr-4 font-semibold">Department</th>
                <th class="pb-3 pr-4 font-semibold">Deadline</th>
                <th class="pb-3 pr-4 font-semibold">Items</th>
                <th class="pb-3 pr-4 font-semibold">Suppliers</th>
                <th class="pb-3 pr-4 font-semibold">Status</th>
                <th class="pb-3 font-semibold text-right">Action</th>
              </tr>
            </thead>
            <tbody :if={@rfqs == []} class="divide-y divide-slate-100">
              <tr>
                <td class="py-4 pr-4">
                  <p class="font-medium text-slate-900">
                    {if (@filters["search"] || "") != "" or count_active_filters(@filters) > 0,
                      do: "No requests for quotation match the current filters",
                      else: "No requests for quotation available"}
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
            <tbody :if={@rfqs != []} class="divide-y divide-slate-100">
              <tr :for={rfq <- @rfqs}>
                <td class="py-4 pr-4">
                  <p class="font-medium text-slate-900">{rfq.reference}</p>
                  <p class="mt-1 text-xs text-slate-500">{rfq.title}</p>
                </td>
                <td class="py-4 pr-4 text-slate-600">{rfq.department || "General"}</td>
                <td class="py-4 pr-4 text-slate-600">
                  {MedcampWeb.Procurement.LiveHelpers.format_date(rfq.quote_deadline)}
                </td>
                <td class="py-4 pr-4 text-slate-600">{length(rfq.items)}</td>
                <td class="py-4 pr-4 text-slate-600">{length(rfq.invitations)}</td>
                <td class="py-4 pr-4"><.status_badge status={rfq.status} /></td>
                <td class="py-4 text-right">
                  <.link
                    navigate={~p"/procurement/rfqs/#{rfq.id}"}
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
