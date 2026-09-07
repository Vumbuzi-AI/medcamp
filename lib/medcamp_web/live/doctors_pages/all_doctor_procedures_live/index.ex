defmodule MedcampWeb.DoctorsPagePatientLive.AllDoctorProcedureIndex do
  use MedcampWeb, :doctor_live_view

  alias Medcamp.DoctorProcedures

  @per_page 10
  @default_filters %{
    "status" => "",
    "payment_type" => "",
    "min_price" => "",
    "max_price" => "",
    "date_from" => "",
    "date_to" => ""
  }

  @impl true
  def mount(_, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :doctor_procedures)
     |> assign(:search, "")
     |> assign(:filters, @default_filters)
     |> assign(:payment_types, DoctorProcedures.list_distinct_payment_types())
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign(:doctor_procedures, [])
     |> assign(:procedure_types, [])}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action)}
  end

  defp apply_action(socket, :index) do
    socket
    |> assign(:page_title, "Doctor procedures")
    |> assign(:view, :performed)
    |> assign_results(1)
  end

  defp apply_action(socket, :types) do
    socket
    |> assign(:page_title, "Procedure types")
    |> assign(:view, :types)
    |> assign_results(1)
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_results(socket, page)}
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    {:noreply, socket |> assign(:search, term) |> assign_results(1)}
  end

  @impl true
  def handle_event("apply_filters", %{"filters" => filters}, socket) do
    filters = Map.merge(@default_filters, filters)
    {:noreply, socket |> assign(:filters, filters) |> assign_results(1)}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, @default_filters)
     |> assign(:search, "")
     |> assign_results(1)}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    filters = Map.put(socket.assigns.filters, field, "")
    {:noreply, socket |> assign(:filters, filters) |> assign_results(1)}
  end

  defp assign_results(socket, page) do
    case socket.assigns.view do
      :types -> assign_types(socket, page)
      :performed -> assign_performed(socket, page)
    end
  end

  defp assign_performed(socket, page) do
    page = normalize_page(page)
    filters = query_filters(socket)

    total_count =
      DoctorProcedures.count_doctor_procedures_for_doctor(
        socket.assigns.current_user.id,
        filters
      )

    {page, total_pages} = page_details(page, total_count)

    procedures =
      DoctorProcedures.list_doctor_procedures_for_doctor_paginated(
        socket.assigns.current_user.id,
        filters,
        page,
        @per_page
      )

    assign_page(socket, page, total_pages, total_count)
    |> assign(:doctor_procedures, procedures)
  end

  defp assign_types(socket, page) do
    page = normalize_page(page)
    filters = query_filters(socket)
    total_count = DoctorProcedures.count_procedure_types(filters)
    {page, total_pages} = page_details(page, total_count)

    types =
      DoctorProcedures.list_procedure_types_for_doctor_paginated(
        socket.assigns.current_user.id,
        filters,
        page,
        @per_page
      )

    assign_page(socket, page, total_pages, total_count)
    |> assign(:procedure_types, types)
  end

  defp query_filters(socket) do
    %{
      search: socket.assigns.search,
      status: socket.assigns.filters["status"],
      payment_type: socket.assigns.filters["payment_type"],
      min_price: socket.assigns.filters["min_price"],
      max_price: socket.assigns.filters["max_price"],
      date_from: socket.assigns.filters["date_from"],
      date_to: socket.assigns.filters["date_to"]
    }
  end

  defp assign_page(socket, page, total_pages, total_count) do
    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
  end

  defp page_details(page, total_count) do
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    {min(page, total_pages), total_pages}
  end

  defp normalize_page(page) when is_binary(page) do
    case Integer.parse(page) do
      {value, ""} when value > 0 -> value
      _ -> 1
    end
  end

  defp normalize_page(page) when is_integer(page) and page > 0, do: page
  defp normalize_page(_), do: 1

  defp active_filter_count(filters, :types) do
    filters
    |> Map.take(["min_price", "max_price", "date_from", "date_to"])
    |> count_active_filters()
  end

  defp active_filter_count(filters, :performed), do: count_active_filters(filters)

  defp count_active_filters(filters) do
    filters |> Map.values() |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters, view) do
    date_chips = [
      build_filter_chip(filters["date_from"], "date_from", "From #{filters["date_from"]}"),
      build_filter_chip(filters["date_to"], "date_to", "To #{filters["date_to"]}")
    ]

    price_chips = [
      build_filter_chip(filters["min_price"], "min_price", "From KES #{filters["min_price"]}"),
      build_filter_chip(filters["max_price"], "max_price", "Up to KES #{filters["max_price"]}")
    ]

    performed_chips = [
      build_filter_chip(filters["status"], "status", status_chip_label(filters["status"])),
      build_filter_chip(filters["payment_type"], "payment_type", filters["payment_type"])
    ]

    (date_chips ++ price_chips ++ if(view == :performed, do: performed_chips, else: []))
    |> Enum.reject(&is_nil/1)
  end

  defp build_filter_chip(value, _field, _label) when value in [nil, ""], do: nil
  defp build_filter_chip(_value, field, label), do: %{field: field, label: label}

  defp status_chip_label("paid"), do: "Paid"
  defp status_chip_label("not_paid"), do: "Not paid"
  defp status_chip_label(other), do: other

  defp procedure_name(%{procedure: %{name: name}}), do: name
  defp procedure_name(%{subsidized_procedure: %{name: name}}), do: name
  defp procedure_name(_), do: "Unknown procedure"

  defp procedure_price(%{procedure: %{price: price}}), do: price
  defp procedure_price(%{subsidized_procedure: %{price: price}}), do: price
  defp procedure_price(_), do: nil

  defp patient_name(patient) do
    [patient.first_name, patient.middle_name, patient.last_name]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" ")
  end

  defp money(nil), do: "—"
  defp money(amount), do: "KES #{amount}"

  defp format_datetime(nil), do: "Never"
  defp format_datetime(datetime), do: Calendar.strftime(datetime, "%d %b %Y, %H:%M")

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-5">
      <div class="rounded-lg border border-gray-100 bg-white p-4 shadow-sm">
        <.page_header
          icon_path="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
          title="Doctor Procedures"
          subtitle="Review procedures you have performed and their frequency by type."
        />

        <nav class="mb-5 flex gap-1 border-b border-slate-200" aria-label="Procedure views">
          <.link
            navigate={~p"/doctor/doctor_procedures"}
            class={[
              "border-b-2 px-4 py-3 text-sm font-medium transition",
              @view == :performed && "border-[#373896] text-[#373896]",
              @view != :performed && "border-transparent text-slate-500 hover:text-slate-700"
            ]}
          >
            Procedures done
          </.link>
          <.link
            navigate={~p"/doctor/doctor_procedures/types"}
            class={[
              "border-b-2 px-4 py-3 text-sm font-medium transition",
              @view == :types && "border-[#373896] text-[#373896]",
              @view != :types && "border-transparent text-slate-500 hover:text-slate-700"
            ]}
          >
            Procedure types & frequency
          </.link>
        </nav>

        <div class="mb-4 flex flex-wrap items-center gap-3">
          <form phx-change="search" class="min-w-64 flex-1">
            <.search_input
              name="search"
              value={@search}
              placeholder={
                if @view == :types,
                  do: "Search procedure type by name",
                  else: "Search patient or procedure name"
              }
            />
          </form>

          <.filter_drawer
            id="doctor-procedures-filters"
            title="Filter procedures"
            apply_event="apply_filters"
            active_count={active_filter_count(@filters, @view)}
          >
            <:group label="Procedure date">
              <div class="grid grid-cols-2 gap-3">
                <label class="block">
                  <span class="mb-1 block text-xs font-medium text-gray-600">From</span>
                  <input
                    id="doctor-procedures-date-from"
                    type="date"
                    name="filters[date_from]"
                    value={@filters["date_from"]}
                    class="h-9 w-full rounded-md border border-gray-300 px-2 text-sm"
                  />
                </label>
                <label class="block">
                  <span class="mb-1 block text-xs font-medium text-gray-600">To</span>
                  <input
                    id="doctor-procedures-date-to"
                    type="date"
                    name="filters[date_to]"
                    value={@filters["date_to"]}
                    class="h-9 w-full rounded-md border border-gray-300 px-2 text-sm"
                  />
                </label>
              </div>
            </:group>

            <:group :if={@view == :performed} label="Payment status">
              <select
                name="filters[status]"
                class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm"
              >
                <option value="" selected={@filters["status"] == ""}>All statuses</option>
                <option value="paid" selected={@filters["status"] == "paid"}>Paid</option>
                <option value="not_paid" selected={@filters["status"] == "not_paid"}>Not paid</option>
              </select>
            </:group>

            <:group :if={@view == :performed} label="Payment type">
              <select
                name="filters[payment_type]"
                class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm"
              >
                <option value="" selected={@filters["payment_type"] == ""}>All payment types</option>
                <option
                  :for={type <- @payment_types}
                  value={type}
                  selected={@filters["payment_type"] == type}
                >
                  {type}
                </option>
              </select>
            </:group>

            <:group label="Procedure price (KES)">
              <div class="grid grid-cols-2 gap-3">
                <input
                  type="number"
                  min="0"
                  name="filters[min_price]"
                  value={@filters["min_price"]}
                  placeholder="Minimum"
                  class="h-9 w-full rounded-md border border-gray-300 px-2 text-sm"
                />
                <input
                  type="number"
                  min="0"
                  name="filters[max_price]"
                  value={@filters["max_price"]}
                  placeholder="Maximum"
                  class="h-9 w-full rounded-md border border-gray-300 px-2 text-sm"
                />
              </div>
            </:group>

            <:chip
              :for={chip <- filter_chips(@filters, @view)}
              label={chip.label}
              clear={JS.push("clear_chip", value: %{"field" => chip.field})}
            />
          </.filter_drawer>
        </div>

        <%= if @view == :performed do %>
          <.performed_table procedures={@doctor_procedures} search={@search} filters={@filters} />
        <% else %>
          <.types_table types={@procedure_types} search={@search} filters={@filters} />
        <% end %>

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

  attr :procedures, :list, required: true
  attr :search, :string, required: true
  attr :filters, :map, required: true

  defp performed_table(assigns) do
    ~H"""
    <.table id="doctor_procedures" rows={@procedures}>
      <:empty_state>
        <.empty_row colspan={7} filtered={@search != "" or count_active_filters(@filters) > 0} />
      </:empty_state>
      <:col :let={record} label="Patient">
        <span class="font-medium text-slate-900">{patient_name(record.patient)}</span>
      </:col>
      <:col :let={record} label="Procedure">{procedure_name(record)}</:col>
      <:col :let={record} label="Price">
        <span class="font-medium text-slate-900">{money(procedure_price(record))}</span>
      </:col>
      <:col :let={record} label="Date done">{format_datetime(record.inserted_at)}</:col>
      <:col :let={record} label="Payment type">
        <span class="rounded-full bg-[#f0f0ff] px-2 py-1 text-xs font-medium text-[#373896]">
          {record.payment_type || "—"}
        </span>
      </:col>
      <:col :let={record} label="Status">
        <span class={[
          "rounded-full px-2 py-1 text-xs font-medium",
          record.has_paid && "bg-green-100 text-green-800",
          !record.has_paid && "bg-red-100 text-red-800"
        ]}>
          {if record.has_paid, do: "Paid", else: "Not paid"}
        </span>
      </:col>
      <:col :let={record} label="Amount paid">
        <span class="font-medium text-slate-900">{money(record.total_amount_paid)}</span>
      </:col>
    </.table>
    """
  end

  attr :types, :list, required: true
  attr :search, :string, required: true
  attr :filters, :map, required: true

  defp types_table(assigns) do
    ~H"""
    <.table id="procedure_types" rows={@types}>
      <:empty_state>
        <.empty_row colspan={5} filtered={@search != "" or active_filter_count(@filters, :types) > 0} />
      </:empty_state>
      <:col :let={type} label="Procedure type">
        <.link
          navigate={~p"/doctor/doctor_procedures/types/#{type.id}"}
          class="font-semibold text-[#373896] hover:underline"
        >
          {type.name}
        </.link>
        <p class="mt-1 max-w-md truncate text-xs text-slate-500">{type.description}</p>
      </:col>
      <:col :let={type} label="Price">
        <span class="font-medium text-slate-900">{money(type.price)}</span>
      </:col>
      <:col :let={type} label="Times done">
        <span class="inline-flex min-w-8 justify-center rounded-full bg-[#e7e7ff] px-2 py-1 text-xs font-semibold text-[#373896]">
          {type.performed_count}
        </span>
      </:col>
      <:col :let={type} label="People treated">{type.patient_count}</:col>
      <:col :let={type} label="Last done">{format_datetime(type.last_performed_at)}</:col>
    </.table>
    """
  end

  attr :colspan, :integer, required: true
  attr :filtered, :boolean, required: true

  defp empty_row(assigns) do
    ~H"""
    <tr>
      <td colspan={@colspan} class="px-6 py-12 text-center">
        <p class="font-semibold text-slate-900">
          {if @filtered, do: "No procedures match these filters", else: "No procedures available"}
        </p>
        <p class="mt-1 text-sm text-slate-500">Try changing your search or filters.</p>
      </td>
    </tr>
    """
  end
end
