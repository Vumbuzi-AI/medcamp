defmodule MedcampWeb.AdminLabAllocationsLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.LabAllocations
  alias Medcamp.Accounts
  alias Medcamp.ExpiryFilter
  alias Medcamp.Postal
  alias Medcamp.StockAlerts

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    users = Accounts.list_users_for_selection()

    {:ok,
     socket
     |> assign(:active_tab, :admin_lab_allocations)
     |> assign(:users, users)
     |> assign(:lab_filters, default_lab_filters())
     |> assign(:lab_query_filters, %{})
     |> assign(:search, "")
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_lab_allocations()
     |> assign(:quote_request_modal, nil)}
  end

  defp default_lab_filters do
    %{
      "date_from" => "",
      "date_to" => "",
      "allocated_by_id" => "",
      "allocated_to_id" => "",
      "expiry_status" => "",
      "expiry_from" => "",
      "expiry_to" => ""
    }
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields —
  # preserving the current search here keeps a drawer-only submit from
  # wiping it out.
  @impl true
  def handle_event("filter_lab", %{"filters" => filters}, socket) do
    filters = Map.put(filters, "expiry_status", ExpiryFilter.normalize(filters["expiry_status"]))

    params = %{
      search: socket.assigns.search,
      date_from: filters["date_from"] || "",
      date_to: filters["date_to"] || "",
      allocated_by_id: parse_id(filters["allocated_by_id"]),
      allocated_to_id: parse_id(filters["allocated_to_id"]),
      expiry_status: filters["expiry_status"],
      expiry_from: filters["expiry_from"] || "",
      expiry_to: filters["expiry_to"] || ""
    }

    {:noreply,
     socket
     |> assign(:lab_filters, filters)
     |> assign(:lab_query_filters, params)
     |> assign(:page, 1)
     |> load_lab_allocations()}
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    query_filters = Map.put(socket.assigns.lab_query_filters, :search, term)

    {:noreply,
     socket
     |> assign(:search, term)
     |> assign(:lab_query_filters, query_filters)
     |> assign(:page, 1)
     |> load_lab_allocations()}
  end

  def handle_event("clear_filters_lab", _, socket) do
    {:noreply,
     socket
     |> assign(:lab_filters, default_lab_filters())
     |> assign(:lab_query_filters, %{})
     |> assign(:search, "")
     |> assign(:page, 1)
     |> load_lab_allocations()}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    filters = Map.put(socket.assigns.lab_filters, field, "")
    handle_event("filter_lab", %{"filters" => filters}, socket)
  end

  def handle_event("open_quote_modal_lab", %{"id" => id}, socket) do
    la = LabAllocations.get_lab_allocation!(id)
    {item_name, supplier} = item_and_supplier_for_lab_allocation(la)

    {:noreply,
     socket
     |> assign(:quote_request_modal, %{item_name: item_name, supplier: supplier})}
  end

  def handle_event("cancel_quote_request", _, socket) do
    {:noreply, assign(socket, :quote_request_modal, nil)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, socket |> assign(:page, max(1, String.to_integer(page))) |> load_lab_allocations()}
  end

  @impl true
  def handle_info({:submit_quote_request, %{quantity: qty, notes: notes}}, socket) do
    modal = socket.assigns.quote_request_modal

    result =
      Postal.send_supplier_quote_request_email(
        modal.supplier.email,
        modal.supplier.name,
        modal.item_name,
        String.to_integer(qty),
        notes
      )

    socket =
      case result do
        {:ok, _, _response} ->
          put_flash(socket, :info, "Quote request sent to #{modal.supplier.name}.")

        {:error, _} ->
          put_flash(socket, :error, "Failed to send email.")
      end

    {:noreply, assign(socket, :quote_request_modal, nil)}
  end

  def handle_info(
        {:submit_quote_request_no_supplier,
         %{recipient_email: email, subject: subject, body: body}},
        socket
      ) do
    result = Postal.deliver(email, subject, body)

    socket =
      case result do
        {:ok, _, _response} ->
          put_flash(socket, :info, "Quote request email sent to #{email}.")

        {:error, _} ->
          put_flash(socket, :error, "Failed to send email.")
      end

    {:noreply, assign(socket, :quote_request_modal, nil)}
  end

  def handle_info(:cancel_quote_request, socket) do
    {:noreply, assign(socket, :quote_request_modal, nil)}
  end

  defp item_and_supplier_for_lab_allocation(la) do
    item =
      if la.inventory_issued && la.inventory_issued.inventory_received do
        la.inventory_issued.inventory_received.brand_name ||
          la.inventory_issued.inventory_received.generic_name || "Item"
      else
        "Lab allocation ##{la.id}"
      end

    supplier =
      if la.inventory_issued && la.inventory_issued.batch && la.inventory_issued.batch.supplier do
        s = la.inventory_issued.batch.supplier
        %{email: s.email, name: s.name}
      else
        nil
      end

    {item, supplier}
  end

  defp parse_id(""), do: nil
  defp parse_id(nil), do: nil

  defp parse_id(id) when is_binary(id) do
    case Integer.parse(id) do
      {n, _} -> n
      _ -> nil
    end
  end

  defp parse_id(_), do: nil

  defp count_active_filters(filters) do
    filters
    |> Map.drop(["search"])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters, users) do
    [
      filter_chip(filters["date_from"], "date_from", "From #{filters["date_from"]}"),
      filter_chip(filters["date_to"], "date_to", "To #{filters["date_to"]}"),
      filter_chip(
        filters["allocated_by_id"],
        "allocated_by_id",
        "Allocated by #{user_email(filters["allocated_by_id"], users)}"
      ),
      filter_chip(
        filters["allocated_to_id"],
        "allocated_to_id",
        "Allocated to #{user_email(filters["allocated_to_id"], users)}"
      ),
      filter_chip(
        filters["expiry_status"],
        "expiry_status",
        "Expiry: #{ExpiryFilter.label(filters["expiry_status"])}"
      ),
      filter_chip(filters["expiry_from"], "expiry_from", "Expiry from #{filters["expiry_from"]}"),
      filter_chip(filters["expiry_to"], "expiry_to", "Expiry to #{filters["expiry_to"]}")
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp user_email(id, users) do
    case Enum.find(users, fn {_email, user_id} -> to_string(user_id) == to_string(id) end) do
      {email, _id} -> email
      nil -> id
    end
  end

  defp load_lab_allocations(socket) do
    filters = socket.assigns.lab_query_filters
    per_page = socket.assigns.per_page
    page = socket.assigns.page

    total_count = LabAllocations.count_lab_allocations(filters)
    total_pages = Medcamp.Pagination.total_pages(total_count, per_page)
    page = min(max(1, page), total_pages)
    lab_allocations = LabAllocations.filter_lab_allocations_paginated(filters, page, per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:lab_allocations, lab_allocations)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <div class="space-y-4">
        <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
          <.page_header
            icon_path="M9 12h3.75M9 15h3.75M9 18h3.75m3 .75H18a2.25 2.25 0 002.25-2.25V6.108c0-1.135-.845-2.098-1.976-2.192a48.424 48.424 0 00-1.123-.08m-5.801 0c-.065.21-.1.433-.1.664 0 .414.336.75.75.75h4.5a.75.75 0 00.75-.75 2.25 2.25 0 00-.1-.664m-5.8 0A2.251 2.251 0 0113.5 2.25H15c1.012 0 1.867.668 2.15 1.586m-5.8 0c-.376.023-.75.05-1.124.08C9.095 4.01 8.25 4.973 8.25 6.108V8.25m0 0H4.875c-.621 0-1.125.504-1.125 1.125v11.25c0 .621.504 1.125 1.125 1.125h9.75c.621 0 1.125-.504 1.125-1.125V9.375c0-.621-.504-1.125-1.125-1.125H8.25zM6.75 12h.008v.008H6.75V12zm0 3h.008v.008H6.75V15zm0 3h.008v.008H6.75V18z"
            title="Lab Allocations"
            subtitle="Filter and manage lab allocations."
          />

          <div class="flex flex-wrap items-center gap-3">
            <form phx-change="search" class="flex-1">
              <.search_input name="search" value={@search} placeholder="Search by item name" />
            </form>

            <.filter_drawer
              id="lab-allocations-filters"
              title="Filter lab allocations"
              apply_event="filter_lab"
              clear_event="clear_filters_lab"
              active_count={count_active_filters(@lab_filters)}
            >
              <:group label="Date Range">
                <.date_range_fields
                  from_name="filters[date_from]"
                  to_name="filters[date_to]"
                  from_value={@lab_filters["date_from"]}
                  to_value={@lab_filters["date_to"]}
                />
              </:group>

              <:group label="Allocated By / To">
                <div>
                  <label class="block text-xs font-medium text-gray-600 mb-1">Allocated by</label>
                  <select
                    name="filters[allocated_by_id]"
                    class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
                  >
                    <option value="">All</option>
                    <%= for {email, id} <- @users do %>
                      <option value={id} selected={@lab_filters["allocated_by_id"] == to_string(id)}>
                        {email}
                      </option>
                    <% end %>
                  </select>
                </div>
                <div>
                  <label class="block text-xs font-medium text-gray-600 mb-1">Allocated to</label>
                  <select
                    name="filters[allocated_to_id]"
                    class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
                  >
                    <option value="">All</option>
                    <%= for {email, id} <- @users do %>
                      <option value={id} selected={@lab_filters["allocated_to_id"] == to_string(id)}>
                        {email}
                      </option>
                    <% end %>
                  </select>
                </div>
              </:group>

              <:group label="Expiry">
                <.expiry_filter_fields
                  status_value={@lab_filters["expiry_status"]}
                  from_value={@lab_filters["expiry_from"]}
                  to_value={@lab_filters["expiry_to"]}
                />
              </:group>

              <:chip
                :for={chip <- filter_chips(@lab_filters, @users)}
                label={chip.label}
                clear={JS.push("clear_chip", value: %{"field" => chip.field})}
              />
            </.filter_drawer>
          </div>
        </div>
        <div class="bg-white rounded-lg shadow-sm border border-gray-100 overflow-x-auto">
          <.table id="lab_allocations" rows={@lab_allocations}
            row_id={&"lab_allocations-#{&1.id}"}
          >
            <:empty_state>
              <tr>
                <td class="px-6 py-4 text-sm">
                  <p class="font-semibold text-gray-900">
                    {if @search != "" or count_active_filters(@lab_filters) > 0,
                      do: "No lab allocations match the current filters",
                      else: "No lab allocations available"}
                  </p>
                  <p class="mt-1 text-sm text-gray-400">—</p>
                </td>
                <td class="px-6 py-4 text-sm text-gray-400">—</td>
                <td class="px-6 py-4 text-sm text-gray-400">—</td>
                <td class="px-6 py-4 text-sm text-gray-400">—</td>
                <td class="px-6 py-4 text-sm text-gray-400">—</td>
                <td class="px-6 py-4 text-sm text-gray-400">—</td>
                <td class="px-6 py-4 text-sm text-gray-400">—</td>
                <td class="px-6 py-4 text-sm text-gray-400">—</td>
                <td class="px-6 py-4 text-right text-sm">
                  <button type="button" disabled class="cursor-not-allowed text-gray-300">
                    Request quote
                  </button>
                </td>
              </tr>
            </:empty_state>

            <:col :let={la} label="Item">
              <%= if la.inventory_issued && la.inventory_issued.inventory_received do %>
                {la.inventory_issued.inventory_received.brand_name ||
                  la.inventory_issued.inventory_received.generic_name || "—"}
              <% else %>
                —
              <% end %>
            </:col>
            <:col :let={la} label="Allocated qty">{la.allocated_quantity}</:col>
            <:col :let={la} label="Remaining">
              <span class={
                if (la.remaining_quantity || 0) <= 20, do: "text-red-600 font-semibold", else: ""
              }>
                {la.remaining_quantity}
              </span>
              <%= if (la.remaining_quantity || 0) == 0 do %>
                <span class="text-red-600 text-xs ml-1">(out)</span>
              <% else %>
                <%= if (la.remaining_quantity || 0) <= 20 do %>
                  <span class="text-red-600 text-xs ml-1">(low)</span>
                <% end %>
              <% end %>
            </:col>
            <:col :let={la} label="UOM">{la.uom || "—"}</:col>
            <:col :let={la} label="Expiry">
              <%= if la.expiry_date && StockAlerts.near_expiry?(la.expiry_date) do %>
                <span class="text-red-600 font-semibold" title="Expiring within 90 days">
                  {format_expiry(la.expiry_date)}
                </span>
                <span class="text-red-600 text-xs ml-1">(soon)</span>
              <% else %>
                {format_expiry(la.expiry_date)}
              <% end %>
            </:col>
            <:col :let={la} label="Allocated by">
              {(la.allocated_by_user && la.allocated_by_user.name) || "—"}
            </:col>
            <:col :let={la} label="Allocated to">
              {(la.allocated_to_user && la.allocated_to_user.name) || "—"}
            </:col>
            <:col :let={la} label="Date">{format_date(la.inserted_at)}</:col>
            <:action :let={la}>
              <button
                type="button"
                phx-click="open_quote_modal_lab"
                phx-value-id={la.id}
                class="text-sm text-[#6667ab] hover:text-[#373896] font-medium"
              >
                Request quote
              </button>
            </:action>
          </.table>
        </div>

        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
          show_when_empty={true}
        />
      </div>

      <.modal
        :if={@quote_request_modal}
        id="quote-request-modal"
        show
        on_cancel={JS.push("cancel_quote_request")}
      >
        <.live_component
          module={MedcampWeb.AdminQuoteRequestModalComponent}
          id="quote-request"
          item_name={@quote_request_modal.item_name}
          supplier={@quote_request_modal[:supplier]}
        />
      </.modal>
    </div>
    """
  end

  defp format_expiry(nil), do: "—"
  defp format_expiry(%Date{} = d), do: Calendar.strftime(d, "%d %b %Y")

  defp format_date(nil), do: "—"

  defp format_date(dt) when not is_nil(dt) do
    dt
    |> DateTime.shift_zone!("Africa/Nairobi")
    |> Calendar.strftime("%d %b %Y %H:%M")
  end
end
