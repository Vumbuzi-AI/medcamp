defmodule MedcampWeb.ReceptionsPagePatientLive.EachPatientAppointmentIndex do
  use MedcampWeb, :reception_each_patient_live_view

  alias Medcamp.Appointments
  alias Medcamp.Appointments.Appointment
  alias Medcamp.Patients

  @per_page 10

  @impl true
  def mount(%{"patient_id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :appointments)
     |> assign(:patient_id, id)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_appointments()}
  end

  defp load_appointments(socket) do
    patient_id = socket.assigns.patient_id
    total_count = Appointments.count_appointments_by_patient(patient_id)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    appointments =
      Appointments.list_appointments_by_patient_paginated(
        patient_id,
        page,
        socket.assigns.per_page
      )

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:appointments, appointments)
  end

  @impl true
  def handle_params(%{"patient_id" => id} = params, _url, socket) do
    patient = Patients.get_patient!(id)

    {:noreply,
     socket
     |> assign(:page_title, "Patient Appointments")
     |> assign(:patient, patient)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Appointment")
    |> assign(:appointment, Appointments.get_appointment!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Appointment")
    |> assign(:appointment, %Appointment{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Appointments")
    |> assign(:appointment, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    appointment = Appointments.get_appointment!(id)
    {:ok, _} = Appointments.delete_appointment(appointment)

    {:noreply, load_appointments(socket)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_appointments()}
  end

  @impl true

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-4">
        <div class="flex items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-[#6667ab]"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
            />
          </svg>
          Listing Appointments
        </div>
        <:actions>
          <.link patch={~p"/reception/#{@patient.id}/appointments/new"}>
            <.button class="bg-[#6667ab] hover:bg-[#5556a0]">
              <div class="flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-2"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4v16m8-8H4"
                  />
                </svg>
                New Appointment
              </div>
            </.button>
          </.link>
        </:actions>
      </.header>

      <.table id="appointments" rows={@appointments}
        row_id={&"appointments-#{&1.id}"}
      >
        <:col :let={appointment} label="Date">
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
                d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
              />
            </svg>
            <span class="text-gray-700">{appointment.date}</span>
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

        <:col :let={appointment} label="Doctor">
          <div class="flex items-center py-3">
            <%= if appointment.doctor && appointment.doctor.name do %>
              <span class="px-2 py-1 text-xs rounded-full bg-[#e7e7ff] text-[#373896]">
                Dr. {appointment.doctor.name}
              </span>
            <% else %>
              <span class="px-2 py-1 text-xs rounded-full bg-gray-100 text-gray-500">
                Not Assigned
              </span>
            <% end %>
          </div>
        </:col>

        <:col :let={appointment} label="Reason">
          <div class="max-w-xs py-3">
            <span class="text-gray-700 line-clamp-2">{appointment.reason}</span>
          </div>
        </:col>

        <:action :let={appointment}>
          <div class="flex items-center justify-center">
            <.link
              patch={~p"/reception/appointments/#{appointment}/edit"}
              class="flex items-center text-[#6667ab] hover:text-[#373896]"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                />
              </svg>
              Edit
            </.link>
          </div>
        </:action>

        <:action :let={appointment}>
          <div class="flex items-center justify-center">
            <.link
              phx-click={JS.push("delete", value: %{id: appointment.id}) |> hide("#appointments-#{appointment.id}")}
              data-confirm="Are you sure?"
              class="flex items-center text-red-600 hover:text-red-800"
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                />
              </svg>
              Delete
            </.link>
          </div>
        </:action>
      </.table>
      <.pagination
        page={@page}
        total_pages={@total_pages}
        total_count={@total_count}
        per_page={@per_page}
      />
    </div>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="appointment-modal"
      show
      on_cancel={JS.patch(~p"/reception/#{@patient.id}/appointments")}
    >
      <.live_component
        module={MedcampWeb.AppointmentLive.FormComponent}
        id={@appointment.id || :new}
        title={@page_title}
        action={@live_action}
        appointment={@appointment}
        selected_patient={@patient}
        patch={~p"/reception/#{@patient.id}/appointments"}
      />
    </.modal>
    """
  end
end
