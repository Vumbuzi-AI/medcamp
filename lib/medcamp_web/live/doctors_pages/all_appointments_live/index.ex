defmodule MedcampWeb.DoctorsPagePatientLive.AllAppointmentsLiveIndex do
  use MedcampWeb, :doctor_live_view

  alias Medcamp.Appointments

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :appointments)
     |> assign(:search, "")
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign_appointments(1)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing My Appointments")
    |> assign(:appointment, nil)
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_appointments(socket, page)}
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    {:noreply, socket |> assign(:search, term) |> assign_appointments(1)}
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply, socket |> assign(:search, "") |> assign_appointments(1)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    appointment = Appointments.get_appointment!(id)
    {:ok, _} = Appointments.delete_appointment(appointment)

    {:noreply, assign_appointments(socket, socket.assigns.page)}
  end

  defp assign_appointments(socket, page) do
    page = normalize_page(page)
    filters = %{search: socket.assigns.search}

    total_count =
      Appointments.count_appointments_by_doctor(socket.assigns.current_user.id, filters)

    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    appointments =
      Appointments.list_appointments_by_doctor_paginated(
        socket.assigns.current_user.id,
        filters,
        page,
        @per_page
      )

    socket
    |> assign(:page, page)
    |> assign(:per_page, @per_page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:appointments, appointments)
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
    <div>
      <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
        <.page_header
          icon_path="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
          title="My Appointments"
          subtitle="Search your scheduled appointments."
        />

        <form phx-change="search" class="mb-4">
          <.search_input name="search" value={@search} placeholder="Search by patient name or reason" />
        </form>

        <.table id="appointments" rows={@appointments}>
          <:empty_state>
            <tr>
              <td class="px-6 py-4 text-sm">
                <p class="font-semibold text-gray-900">
                  {if @search != "",
                    do: "No appointments match the current search",
                    else: "No appointments available"}
                </p>
                <p class="mt-1 text-sm text-gray-400">—</p>
              </td>
              <td class="px-6 py-4 text-sm text-gray-400">—</td>
              <td class="px-6 py-4 text-sm text-gray-400">—</td>
              <td class="px-6 py-4 text-sm">
                <span class="inline-flex rounded-full bg-gray-100 px-3 py-1 text-sm text-gray-400">
                  —
                </span>
              </td>
            </tr>
          </:empty_state>

          <:col :let={appointment} label="Date">
            <div class="flex items-center py-3">
              <div class="px-3 py-1 bg-[#e7e7ff] text-[#373896] rounded-md text-sm font-medium">
                {appointment.date}
              </div>
            </div>
          </:col>

          <:col :let={appointment} label="Time">
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

          <:col :let={appointment} label="Patient">
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

          <:col :let={appointment} label="Reason">
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
          show_when_empty={true}
        />
      </div>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="appointment-modal"
        show
        on_cancel={JS.patch(~p"/reception/appointments")}
      >
        <.live_component
          module={MedcampWeb.AppointmentLive.FormComponent}
          id={@appointment.id || :new}
          title={@page_title}
          action={@live_action}
          appointment={@appointment}
          selected_patient={nil}
          patch={~p"/reception/appointments"}
        />
      </.modal>
    </div>
    """
  end
end
