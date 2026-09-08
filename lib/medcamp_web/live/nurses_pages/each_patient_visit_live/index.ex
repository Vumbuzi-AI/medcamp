defmodule MedcampWeb.NursesPages.EachPatientVisitIndex do
  use MedcampWeb, :nurse_each_patient_live_view

  alias Medcamp.PatientVisits
  alias Medcamp.PatientVisits.PatientVisit
  alias Medcamp.Accounts
  alias Medcamp.Patients
  @per_page 10

  @impl true
  def mount(%{"patient_id" => id}, _session, socket) do
    doctors = Accounts.list_all_doctors_for_selection()

    {:ok,
     socket
     |> assign(:doctors, doctors)
     |> assign(:active_tab, :visits)
     |> assign(:patient, Patients.get_patient!(id))
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_patient_visits()}
  end

  defp load_patient_visits(socket) do
    patient_id = socket.assigns.patient.id
    total_count = PatientVisits.count_patient_visits_by_patient_id(patient_id)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    patient_visits =
      PatientVisits.list_patient_visits_by_patient_id_paginated(
        patient_id,
        page,
        socket.assigns.per_page
      )

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:patient_visits, patient_visits)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Patient visit")
    |> assign(:patient_visit, PatientVisits.get_patient_visit!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Patient visit")
    |> assign(:patient_visit, %PatientVisit{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Patient visits")
    |> assign(:patient_visit, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    patient_visit = PatientVisits.get_patient_visit!(id)
    {:ok, _} = PatientVisits.delete_patient_visit(patient_visit)

    {:noreply, load_patient_visits(socket)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_patient_visits()}
  end

  @impl true

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.header class="text-brand-primary border-b border-gray-100 pb-4 mb-4">
        <div class="flex items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-brand-accent"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
            />
          </svg>
          Listing Patient visits for {[
            @patient.first_name,
            @patient.middle_name,
            @patient.last_name
          ]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}
        </div>
      </.header>

      <%= if @total_count == 0 do %>
        <div class="text-center py-8 bg-gray-50 rounded-lg border border-dashed border-gray-300">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No patient visits</h3>
          <p class="mt-1 text-sm text-gray-500">
            No patient visits have been recorded yet.
          </p>
        </div>
      <% else %>
        <.table id="patient_visits" rows={@patient_visits} row_id={&"patient_visits-#{&1.id}"}>
          <:col :let={patient_visit} label="Patient">
            <div class="flex items-center py-3">
              <div class="h-8 w-8 rounded-full bg-brand-100 flex items-center justify-center text-brand-primary font-medium mr-2 text-sm">
                {String.first(patient_visit.patient.first_name || "")}
              </div>
              <span class="font-medium text-gray-900">
                {[
                  patient_visit.patient.first_name,
                  patient_visit.patient.middle_name
                ]
                |> Enum.filter(&(&1 != nil))
                |> Enum.join(" ")}
              </span>
            </div>
          </:col>

          <:col :let={patient_visit} label="Date">
            <div class="flex items-center py-3">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1 text-brand-accent"
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
              <span class="text-gray-700">{patient_visit.date}</span>
            </div>
          </:col>

          <:col :let={patient_visit} label="Time">
            <div class="flex items-center py-3">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1 text-brand-accent"
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
              <span class="text-gray-700">{patient_visit.time}</span>
            </div>
          </:col>

          <:col :let={patient_visit} label="Reason">
            <div class="max-w-xs py-3">
              <span class="text-gray-700 line-clamp-2">{patient_visit.reason}</span>
            </div>
          </:col>

          <:col :let={patient_visit} label="Receptionist">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-brand-50 text-brand-primary">
                {patient_visit.creator.name}
              </span>
            </div>
          </:col>

          <:col :let={patient_visit} label="Doctor">
            <div class="flex items-center py-3">
              <%= if patient_visit.doctor && patient_visit.doctor.name do %>
                <span class="px-2 py-1 text-xs rounded-full bg-brand-100 text-brand-primary">
                  Dr. {patient_visit.doctor.name}
                </span>
              <% else %>
                <span class="px-2 py-1 text-xs rounded-full bg-gray-100 text-gray-500">
                  Not Assigned
                </span>
              <% end %>
            </div>
          </:col>
        </.table>
        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      <% end %>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="nurse-modal"
        show
        on_cancel={JS.patch(~p"/nurse/visits")}
      >
        <.live_component
          module={MedcampWeb.NursesPages.FormComponent}
          id={@patient_visit.id || :new}
          title={@page_title}
          doctors={@doctors}
          action={@live_action}
          current_user={@current_user}
          patient_visit={@patient_visit}
          patch={~p"/nurse/visits"}
        />
      </.modal>
    </div>
    """
  end
end
