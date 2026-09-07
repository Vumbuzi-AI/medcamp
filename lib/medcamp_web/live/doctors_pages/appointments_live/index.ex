defmodule MedcampWeb.DoctorsPagePatientLive.AppointmentIndex do
  use MedcampWeb, :each_patient_live_view

  alias Medcamp.Patients
  alias Medcamp.Appointments
  alias Medcamp.Appointments.Appointment

  @per_page 10

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :appointments)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign_appointments(id, 1)}
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    patient = Patients.get_patient!(id)

    {:noreply,
     socket
     |> assign(:patient, patient)
     |> apply_action(socket.assigns.live_action, params)}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing  Appointments")
    |> assign(:appointment, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Listing  Appointments")
    |> assign(:appointment, %Appointment{})
  end

  defp apply_action(socket, :edit, %{"appointment_id" => id}) do
    socket
    |> assign(:page_title, "Listing  Appointments")
    |> assign(:appointment, Appointments.get_appointment!(id))
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_appointments(socket, socket.assigns.patient.id, page)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    appointment = Appointments.get_appointment!(id)
    {:ok, _} = Appointments.delete_appointment(appointment)

    {:noreply, assign_appointments(socket, socket.assigns.patient.id, socket.assigns.page)}
  end

  defp assign_appointments(socket, patient_id, page) do
    page = normalize_page(page)
    total_count = Appointments.count_appointments_by_patient(patient_id)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    appointments =
      Appointments.list_appointments_by_patient_paginated(patient_id, page, @per_page)

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
          Listing Appointments for {[@patient.first_name, @patient.middle_name, @patient.last_name]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}
        </div>
        <:actions>
          <.link patch={~p"/doctor/patients/#{@patient.id}/appointments/new"}>
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
    </div>

    <.blank_state
      :if={@appointments == []}
      icon_path="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
      title="No appointments found"
      description="This patient has no appointments recorded yet."
    />

    <.table :if={@appointments != []} id="appointments" rows={@appointments}>
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
    />

    <.modal
      :if={@live_action in [:new, :edit]}
      id="appointment-modal"
      show
      on_cancel={JS.patch(~p"/doctor/patients/#{@patient.id}/appointments")}
    >
      <.live_component
        module={MedcampWeb.AppointmentLive.FormComponent}
        id={@appointment.id || :new}
        title={@page_title}
        action={@live_action}
        appointment={@appointment}
        selected_patient={@patient}
        patch={~p"/doctor/patients/#{@patient.id}/appointments"}
      />
    </.modal>
    """
  end
end
