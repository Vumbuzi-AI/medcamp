defmodule MedcampWeb.PharmacistsLive.DrugAllocationsIndex do
  use MedcampWeb, :pharmacist_live_view

  alias Medcamp.DrugAllocations
  alias Medcamp.DrugAllocations.DrugAllocation
  alias Medcamp.Patients

  @per_page 10

  @default_filters %{"status" => "", "payment_type" => ""}

  @impl true
  def mount(_params, _session, socket) do
    patients = Patients.list_patients_for_selection()
    payment_types = DrugAllocations.list_distinct_payment_types()

    {:ok,
     socket
     |> assign(:patients, patients)
     |> assign(:payment_types, payment_types)
     |> assign(:active_tab, :drug_allocations)
     |> assign(:search, "")
     |> assign(:filters, @default_filters)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign(:drug_allocations, [])
     |> assign_drug_allocations("", @default_filters, 1)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Drug allocation")
    |> assign(:drug_allocation, DrugAllocations.get_drug_allocation!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Drug allocation")
    |> assign(:drug_allocation, %DrugAllocation{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Drug allocations")
    |> assign(:drug_allocation, nil)
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     assign_drug_allocations(socket, socket.assigns.search, socket.assigns.filters, page)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    drug_allocation = DrugAllocations.get_drug_allocation!(id)

    case DrugAllocations.delete_drug_allocation(drug_allocation) do
      {:ok, _} ->
        {:noreply,
         assign_drug_allocations(
           socket,
           socket.assigns.search,
           socket.assigns.filters,
           socket.assigns.page
         )}

      {:error, :dispensed_drugs} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "You cannot delete a prescription after any drug has been given"
         )}

      {:error, :paid_prescription} ->
        {:noreply, put_flash(socket, :error, "You cannot delete a paid prescription")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete prescription")}
    end
  end

  @impl true
  def handle_event("search", %{"search" => search}, socket) do
    {:noreply,
     socket
     |> assign(:search, search)
     |> assign_drug_allocations(search, socket.assigns.filters, 1)}
  end

  @impl true
  def handle_event("apply_filters", %{"filters" => filters}, socket) do
    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_drug_allocations(socket.assigns.search, filters, 1)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, @default_filters)
     |> assign(:search, "")
     |> assign_drug_allocations("", @default_filters, 1)}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    filters = Map.put(socket.assigns.filters, field, "")

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign_drug_allocations(socket.assigns.search, filters, 1)}
  end

  defp count_active_filters(filters) do
    filters
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters) do
    [
      filter_chip(filters["status"], "status", status_chip_label(filters["status"])),
      filter_chip(filters["payment_type"], "payment_type", filters["payment_type"])
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp status_chip_label("given"), do: "Given"
  defp status_chip_label("pending"), do: "Pending"
  defp status_chip_label(other), do: other

  defp assign_drug_allocations(socket, search, filters, page) do
    page = normalize_page(page)

    query_filters = %{
      search: search,
      status: filters["status"],
      payment_type: filters["payment_type"]
    }

    total_count = DrugAllocations.count_filtered_drug_allocations(query_filters)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    drug_allocations =
      DrugAllocations.filter_drug_allocations_paginated(query_filters, page, @per_page)

    socket
    |> assign(:search, search)
    |> assign(:filters, filters)
    |> assign(:page, page)
    |> assign(:per_page, @per_page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:drug_allocations, drug_allocations)
  end

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, _} when value > 0 -> value
      _ -> 1
    end
  end

  defp normalize_page(page) when is_integer(page) and page > 0, do: page
  defp normalize_page(_), do: 1

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.page_header
        icon_path="M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 002.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 00-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25zM6.75 12h.008v.008H6.75V12zm0 3h.008v.008H6.75V15zm0 3h.008v.008H6.75V18z"
        title="Drug Allocations"
        subtitle="Manage and track patient drug allocations."
      />

      <div class="flex flex-wrap items-center gap-3 mb-4">
        <form phx-change="search" class="flex-1">
          <.search_input
            name="search"
            value={@search}
            placeholder="Search by patient name, email, drug name or given batch number"
          />
        </form>

        <.filter_drawer
          id="drug-allocations-filters"
          title="Filter drug allocations"
          apply_event="apply_filters"
          active_count={count_active_filters(@filters)}
        >
          <:group label="Status">
            <select
              name="filters[status]"
              class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
            >
              <option value="" selected={@filters["status"] == ""}>All</option>
              <option value="given" selected={@filters["status"] == "given"}>Given</option>
              <option value="pending" selected={@filters["status"] == "pending"}>Pending</option>
            </select>
          </:group>

          <:group label="Payment Type">
            <select
              name="filters[payment_type]"
              class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-brand-accent focus:border-brand-accent"
            >
              <option value="" selected={@filters["payment_type"] == ""}>All</option>
              <option :for={pt <- @payment_types} value={pt} selected={@filters["payment_type"] == pt}>
                {pt}
              </option>
            </select>
          </:group>

          <:chip
            :for={chip <- filter_chips(@filters)}
            label={chip.label}
            clear={JS.push("clear_chip", value: %{"field" => chip.field})}
          />
        </.filter_drawer>
      </div>

      <div class="overflow-x-auto -mx-4">
        <.table
          id="drug_allocations"
          rows={@drug_allocations}
          row_click={fn da -> JS.navigate("/pharmacist/drug_allocations/#{da.id}") end}
        >
          <:empty_state>
            <tr>
              <td class="px-6 py-4 text-sm">
                <p class="font-semibold text-gray-900">
                  {if @search != "" or count_active_filters(@filters) > 0,
                    do: "No drug allocations match the current filters",
                    else: "No drug allocations available"}
                </p>
                <p class="mt-1 text-sm text-gray-400">—</p>
              </td>
              <td class="px-6 py-4 text-sm text-gray-400">—</td>
              <td class="px-6 py-4 text-sm text-gray-400">—</td>
              <td class="px-6 py-4 text-sm">
                <span class="inline-flex items-center rounded-md bg-brand-50 px-2.5 py-1 text-xs font-medium text-gray-400">
                  —
                </span>
              </td>
              <td class="px-6 py-4 text-sm">
                <span class="inline-flex items-center rounded-full bg-brand-50 px-2.5 py-1 text-xs font-medium text-gray-400">
                  —
                </span>
              </td>
              <td class="px-6 py-4 text-sm">
                <span class="inline-flex items-center rounded-md bg-brand-50 px-2.5 py-1 text-xs font-medium text-gray-400">
                  —
                </span>
              </td>
              <td class="px-6 py-4 text-sm text-gray-400">—</td>
              <td class="px-6 py-4 text-sm">
                <button
                  type="button"
                  disabled
                  aria-label="View (unavailable)"
                  class="inline-flex cursor-not-allowed items-center gap-1.5 text-sm font-medium text-gray-300"
                >
                  <Heroicons.icon name="eye" type="outline" class="h-4 w-4" /> View
                </button>
              </td>
            </tr>
          </:empty_state>

          <:col :let={drug_allocation} label="Patient">
            <div class="flex items-center gap-3">
              <div class="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-[#e8e8ff] text-brand-primary font-semibold text-sm">
                {String.first(drug_allocation.patient.first_name || "?")}
              </div>
              <span class="font-medium text-slate-800">
                {[
                  drug_allocation.patient.first_name,
                  drug_allocation.patient.middle_name,
                  drug_allocation.patient.last_name
                ]
                |> Enum.filter(&(&1 != nil))
                |> Enum.join(" ")}
              </span>
            </div>
          </:col>

          <:col :let={drug_allocation} label="Drugs Dispensed">
            <div class="flex flex-wrap gap-1 max-w-xs">
              <%= if Enum.empty?(drug_allocation.drugs_given) do %>
                <span class="text-xs text-slate-400 italic">None dispensed yet</span>
              <% else %>
                <%= for dg <- drug_allocation.drugs_given do %>
                  <span class="inline-flex items-center rounded-md bg-indigo-50 px-2 py-0.5 text-xs font-medium text-indigo-700">
                    {dg.drug.brand_name || dg.drug.generic_name} &times; {dg.quantity}
                  </span>
                <% end %>
              <% end %>
            </div>
          </:col>

          <:col :let={drug_allocation} label="Date">
            <span class="inline-flex items-center rounded-md bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-700">
              {format_datetime(drug_allocation.inserted_at)}
            </span>
          </:col>

          <:col :let={drug_allocation} label="Pharmacist">
            <%= if drug_allocation.pharmacist && drug_allocation.pharmacist.name do %>
              <span class="inline-flex items-center rounded-md bg-indigo-50 px-2.5 py-1 text-xs font-medium text-indigo-700">
                {drug_allocation.pharmacist.name}
              </span>
            <% else %>
              <span class="inline-flex items-center rounded-md bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-500">
                Not Assigned
              </span>
            <% end %>
          </:col>

          <:col :let={drug_allocation} label="Status">
            <%= if drug_allocation.has_been_assigned do %>
              <span class="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-medium text-emerald-700">
                <span class="h-1.5 w-1.5 rounded-full bg-emerald-500"></span> Given
              </span>
            <% else %>
              <span class="inline-flex items-center gap-1.5 rounded-full bg-amber-50 px-2.5 py-1 text-xs font-medium text-amber-700">
                <span class="h-1.5 w-1.5 rounded-full bg-amber-500"></span> Pending
              </span>
            <% end %>
          </:col>

          <:col :let={drug_allocation} label="Payment">
            <span class="inline-flex items-center rounded-md bg-slate-100 px-2.5 py-1 text-xs font-medium text-slate-700">
              {drug_allocation.payment_type}
            </span>
          </:col>

          <:col :let={drug_allocation} label="Amount">
            <span class="font-semibold text-slate-900 tabular-nums">
              KSh {drug_allocation.total_amount_paid}
            </span>
          </:col>

          <:col :let={drug_allocation} label="Actions">
            <.link
              navigate={"/pharmacist/drug_allocations/#{drug_allocation.id}"}
              class="inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1.5 text-sm font-medium text-brand-accent hover:bg-brand-accent/10 transition-colors"
            >
              <Heroicons.icon name="eye" type="outline" class="h-4 w-4" /> View
            </.link>
          </:col>
        </.table>
      </div>

      <.pagination
        page={@page}
        total_pages={@total_pages}
        total_count={@total_count}
        per_page={@per_page}
        show_when_empty={true}
      />

      <.modal
        :if={@live_action in [:new, :edit]}
        id="drug_allocation-modal"
        show
        on_cancel={JS.patch(~p"/pharmacist/drug_allocations")}
      >
        <.live_component
          module={MedcampWeb.PharmacistsLive.DrugAllocationFormComponent}
          id={@drug_allocation.id || :new}
          title={@page_title}
          action={@live_action}
          patients={@patients}
          current_user={@current_user}
          drug_allocation={@drug_allocation}
          patch={~p"/pharmacist/drug_allocations"}
        />
      </.modal>
    </div>
    """
  end

  def format_datetime(datetime) do
    datetime
    |> DateTime.shift_zone!("Africa/Nairobi")
    |> Timex.format!("{Mfull} {D}, {YYYY} at {h12}:{m} {AM}")
  end
end
