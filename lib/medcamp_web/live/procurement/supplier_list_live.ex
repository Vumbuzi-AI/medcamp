defmodule MedcampWeb.Procurement.SupplierListLive do
  use MedcampWeb, :procurement_live_view

  import MedcampWeb.ProcurementComponents, only: [status_badge: 1, score_bar: 1]

  alias Medcamp.Procurement.Suppliers
  alias MedcampWeb.Procurement.LiveHelpers

  @refresh_events ~w(
    registration_submitted supplier_approved supplier_rejected supplier_info_requested
  )a

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    filters = %{"search" => "", "status" => ""}

    {:ok,
     socket
     |> assign(:page_title, "Suppliers")
     |> assign(:filters, filters)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign_suppliers(filters)}
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
     |> assign_suppliers(filters)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    filters = %{"search" => "", "status" => ""}

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:page, 1)
     |> assign_suppliers(filters)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> assign_suppliers(socket.assigns.filters)}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    filters = Map.put(socket.assigns.filters, field, "")

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_suppliers(filters)}
  end

  @impl true
  def handle_info({event, _payload}, socket) when event in @refresh_events do
    {:noreply, assign_suppliers(socket, socket.assigns.filters)}
  end

  def handle_info(_message, socket), do: {:noreply, socket}

  defp assign_suppliers(socket, filters) do
    filtered =
      Suppliers.list_suppliers()
      |> Enum.map(&Suppliers.get_supplier!(&1.id))
      |> Enum.filter(fn supplier ->
        matches_status?(supplier, filters["status"]) and
          matches_search?(supplier, filters["search"])
      end)

    total_count = length(filtered)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    suppliers =
      Enum.slice(filtered, (page - 1) * socket.assigns.per_page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:suppliers, suppliers)
  end

  defp matches_status?(_supplier, nil), do: true
  defp matches_status?(_supplier, ""), do: true
  defp matches_status?(supplier, status), do: supplier.status == status

  defp matches_search?(_supplier, nil), do: true
  defp matches_search?(_supplier, ""), do: true

  defp matches_search?(supplier, term) do
    search = String.downcase(String.trim(term))

    [
      supplier.legal_name,
      supplier.name,
      supplier.reference,
      supplier.contact_email,
      supplier.email
    ]
    |> Enum.reject(&LiveHelpers.blank?/1)
    |> Enum.any?(fn value -> String.contains?(String.downcase(value), search) end)
  end

  defp count_active_filters(filters) do
    filters
    |> Map.drop(["search"])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp status_label("pending"), do: "Pending"
  defp status_label("under_review"), do: "Under review"
  defp status_label("approved"), do: "Approved"
  defp status_label("rejected"), do: "Rejected"
  defp status_label(other), do: other

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <.page_header
        icon_path="M17 20h5v-2a4 4 0 00-3-3.87M9 20H4v-2a4 4 0 013-3.87m6-5.13a4 4 0 100-8 4 4 0 000 8zm-9 4a4 4 0 100-8 4 4 0 000 8zm12 0a4 4 0 100-8 4 4 0 000 8z"
        title="Supplier Directory"
        subtitle="Search supplier records, review onboarding status, and open detailed procurement histories."
      />

      <div class="rounded-[2rem] border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex flex-wrap items-center gap-3">
          <form phx-change="filter" class="flex-1">
            <.search_input
              name="filters[search]"
              value={@filters["search"]}
              placeholder="Search by name, reference, or email"
            />
          </form>

          <.filter_drawer
            id="suppliers-filters"
            title="Filter suppliers"
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
                  <option value="pending" selected={@filters["status"] == "pending"}>Pending</option>
                  <option value="under_review" selected={@filters["status"] == "under_review"}>
                    Under review
                  </option>
                  <option value="approved" selected={@filters["status"] == "approved"}>
                    Approved
                  </option>
                  <option value="rejected" selected={@filters["status"] == "rejected"}>
                    Rejected
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
                <th class="pb-3 pr-4 font-semibold">Supplier</th>
                <th class="pb-3 pr-4 font-semibold">Reference</th>
                <th class="pb-3 pr-4 font-semibold">Categories</th>
                <th class="pb-3 pr-4 font-semibold">Compliance</th>
                <th class="pb-3 pr-4 font-semibold">Status</th>
                <th class="pb-3 font-semibold text-right">Action</th>
              </tr>
            </thead>
            <tbody :if={@suppliers == []} class="divide-y divide-slate-100">
              <tr>
                <td class="py-4 pr-4">
                  <p class="font-medium text-slate-900">
                    {if (@filters["search"] || "") != "" or count_active_filters(@filters) > 0,
                      do: "No suppliers match the current filters",
                      else: "No suppliers available"}
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
                <td class="py-4 text-right text-slate-400">—</td>
              </tr>
            </tbody>
            <tbody :if={@suppliers != []} class="divide-y divide-slate-100">
              <tr :for={supplier <- @suppliers}>
                <td class="py-4 pr-4">
                  <p class="font-medium text-slate-900">{supplier.legal_name || supplier.name}</p>
                  <p class="mt-1 text-xs text-slate-500">
                    {supplier.contact_email || supplier.email}
                  </p>
                </td>
                <td class="py-4 pr-4 text-slate-500">{supplier.reference || "Pending"}</td>
                <td class="py-4 pr-4 text-slate-500">
                  {LiveHelpers.maybe_join_list(supplier.product_categories)}
                </td>
                <td class="py-4 pr-4">
                  <.score_bar score={supplier.compliance_score || 0} />
                </td>
                <td class="py-4 pr-4"><.status_badge status={supplier.status} /></td>
                <td class="py-4 text-right">
                  <.link
                    navigate={~p"/procurement/suppliers/#{supplier.id}"}
                    class="text-sm font-semibold text-[#373896] hover:text-[#2d2d7a]"
                  >
                    Open
                  </.link>
                </td>
              </tr>
            </tbody>
          </table>

          <.pagination
            :if={@total_count > 0}
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
