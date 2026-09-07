defmodule MedcampWeb.AdminAppointmentLive.Index do
  use MedcampWeb, :admin_live_view
  alias Medcamp.Appointments
  alias Medcamp.Accounts

  @per_page 10

  @default_filters %{
    patient_search: "",
    doctor_id: "",
    date_from: "",
    date_to: ""
  }

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :appointments)
     |> assign(:filters, @default_filters)
     |> assign(:doctors, Accounts.list_all_doctors_for_selection())
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_appointments()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Appointments")
    |> assign(:appointment, nil)
  end

  # The patient-search box and the filter drawer submit independently (two
  # separate <form>s), so a submission from either one only carries its own
  # fields. Merging onto the current filters means a key absent from this
  # submission is left unchanged rather than reset.
  defp stringify_filters(filters), do: Map.new(filters, fn {k, v} -> {Atom.to_string(k), v} end)

  defp count_active_filters(filters) do
    filters
    |> Map.drop([:patient_search])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters, doctors) do
    [
      filter_chip(filters.doctor_id, "doctor_id", doctor_name(filters.doctor_id, doctors)),
      filter_chip(filters.date_from, "date_from", "From #{filters.date_from}"),
      filter_chip(filters.date_to, "date_to", "To #{filters.date_to}")
    ]
    |> Enum.reject(&is_nil/1)
  end

  defp doctor_name(id, doctors) do
    case Enum.find(doctors, fn {_name, doctor_id} -> to_string(doctor_id) == to_string(id) end) do
      {name, _id} -> name
      nil -> id
    end
  end

  @impl true
  def handle_event("apply_filters", %{"filters" => filters}, socket) do
    filters = Map.merge(stringify_filters(socket.assigns.filters), filters)

    normalized_filters = %{
      patient_search: filters["patient_search"] || "",
      doctor_id: filters["doctor_id"] || "",
      date_from: filters["date_from"] || "",
      date_to: filters["date_to"] || ""
    }

    {:noreply,
     socket
     |> assign(:filters, normalized_filters)
     |> assign(:page, 1)
     |> load_appointments()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, @default_filters)
     |> assign(:page, 1)
     |> load_appointments()}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    handle_event("apply_filters", %{"filters" => %{field => ""}}, socket)
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_appointments()}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    appointment = Appointments.get_appointment!(id)
    {:ok, _} = Appointments.delete_appointment(appointment)

    {:noreply, load_appointments(socket)}
  end

  @impl true

  def render(assigns) do
    ~H"""
    <div>
      <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
        <.page_header
          icon_path="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
          title="Appointments"
          subtitle="Search, filter and manage appointments."
        />

        <div class="flex flex-wrap items-center gap-3 mb-4">
          <form phx-change="apply_filters" class="flex-1">
            <.search_input
              name="filters[patient_search]"
              value={@filters.patient_search}
              placeholder="Search by patient name, phone, GSRN, or reason"
            />
          </form>

          <.filter_drawer
            id="appointments-filters"
            title="Filter appointments"
            apply_event="apply_filters"
            active_count={count_active_filters(@filters)}
          >
            <:group label="Date Range">
              <.date_range_fields
                from_name="filters[date_from]"
                to_name="filters[date_to]"
                from_value={@filters.date_from}
                to_value={@filters.date_to}
                disable_future={false}
              />
            </:group>

            <:group label="Appointment Details">
              <div>
                <label class="block text-xs font-medium text-gray-600 mb-1">Doctor</label>
                <select
                  name="filters[doctor_id]"
                  class="w-full h-9 border border-gray-300 rounded-md px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
                >
                  <option value="">All doctors</option>
                  <%= for {name, id} <- @doctors do %>
                    <option value={id} selected={@filters.doctor_id == to_string(id)}>{name}</option>
                  <% end %>
                </select>
              </div>
            </:group>

            <:chip
              :for={chip <- filter_chips(@filters, @doctors)}
              label={chip.label}
              clear={JS.push("clear_chip", value: %{"field" => chip.field})}
            />
          </.filter_drawer>
        </div>

        <.blank_state
          :if={@total_count == 0}
          icon_path="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
          title="No appointments"
          description={
            if @filters.patient_search != "" or count_active_filters(@filters) > 0,
              do: "No appointments match the current filters.",
              else: "No appointments have been scheduled yet."
          }
        >
          <:actions :if={@filters.patient_search != "" or count_active_filters(@filters) > 0}>
            <button phx-click="clear_filters" class="text-xs text-[#6667ab] hover:underline">
              Clear filters
            </button>
          </:actions>
        </.blank_state>

        <.table :if={@total_count > 0} id="appointments" rows={@streams.appointments}>
          <:col :let={{_id, appointment}} label="Date">
            <div class="flex items-center py-3">
              <div class="px-3 py-1 bg-[#e7e7ff] text-[#373896] rounded-md text-sm font-medium">
                {appointment.date}
              </div>
            </div>
          </:col>

          <:col :let={{_id, appointment}} label="Time">
            <div class="flex items-center py-3">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1 text-[#6667ab]"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              <span class="text-gray-700">{appointment.time}</span>
            </div>
          </:col>

          <:col :let={{_id, appointment}} label="Patient">
            <div class="flex items-center py-3">
              <div class="h-8 w-8 rounded-full bg-[#e7e7ff] flex items-center justify-center text-[#373896] font-medium mr-2 text-sm">
                {String.first(appointment.patient.first_name || "")}
              </div>
              <span class="font-medium text-gray-900">
                {[
                  appointment.patient.first_name,
                  appointment.patient.middle_name,
                  appointment.patient.last_name
                ]
                |> Enum.filter(&(&1 != nil))
                |> Enum.join(" ")}
              </span>
            </div>
          </:col>

          <:col :let={{_id, appointment}} label="Reason">
            <div class="py-3">
              <span class="px-3 py-1 rounded-full bg-gray-100 text-gray-700 text-sm">
                {appointment.reason}
              </span>
            </div>
          </:col>
        </.table>
        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      </div>
    </div>
    """
  end

  defp load_appointments(socket) do
    filters = socket.assigns.filters
    per_page = socket.assigns.per_page
    page = socket.assigns.page

    total_count = Appointments.count_appointments(filters)
    total_pages = Medcamp.Pagination.total_pages(total_count, per_page)
    page = min(max(1, page), total_pages)
    appointments = Appointments.list_appointments_paginated(filters, page, per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> stream(:appointments, appointments, reset: true)
  end
end
