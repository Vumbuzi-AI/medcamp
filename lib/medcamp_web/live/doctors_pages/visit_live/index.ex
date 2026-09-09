defmodule MedcampWeb.DoctorsPagePatientLive.PatientVisitIndex do
  use MedcampWeb, :each_patient_live_view

  alias Medcamp.PatientVisits
  alias Medcamp.PatientVisits.PatientVisit
  alias Medcamp.Patients

  @per_page 10

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    patient = Patients.get_patient!(id)

    {:ok,
     socket
     |> assign(:active_tab, :visits)
     |> assign(:patient, patient)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> assign(:total_count, 0)
     |> assign(:total_pages, 0)
     |> assign_visits(id, 1)}
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
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, assign_visits(socket, socket.assigns.patient.id, page)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    patient_visit = PatientVisits.get_patient_visit!(id)
    {:ok, _} = PatientVisits.delete_patient_visit(patient_visit)

    {:noreply, assign_visits(socket, socket.assigns.patient.id, socket.assigns.page)}
  end

  defp assign_visits(socket, patient_id, page) do
    page = normalize_page(page)
    total_count = PatientVisits.count_patient_visits_by_patient_id(patient_id)
    total_pages = max(1, div(total_count + @per_page - 1, @per_page))
    page = min(page, total_pages)

    patient_visits =
      PatientVisits.list_patient_visits_by_patient_id_paginated(patient_id, page, @per_page)

    socket
    |> assign(:page, page)
    |> assign(:per_page, @per_page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:patient_visits, patient_visits)
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
    <div class="bg-white rounded-lg shadow-sm border border-slate-100 p-4">
      <.header class="text-brand-primary border-b border-slate-100 pb-4 mb-4">
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
              d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
            />
          </svg>
          Listing {[
            @patient.first_name,
            @patient.middle_name,
            @patient.last_name
          ]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}'s visits
        </div>
      </.header>

      <.blank_state
        :if={@patient_visits == []}
        icon_path="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
        title="No visits found"
        description="This patient has no recorded visits yet."
      />

      <.data_table :if={@patient_visits != []} id="patient_visits" rows={@patient_visits}>
        <:col :let={patient_visit} label="Patient">
          <div class="flex items-center py-3">
            <div class="h-8 w-8 rounded-full bg-brand-100 flex items-center justify-center text-brand-primary font-medium mr-2 text-sm">
              {String.first(patient_visit.patient.first_name || "")}
            </div>
            <span class="font-medium text-slate-900">
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
            <span class="text-slate-700">{patient_visit.date}</span>
          </div>
        </:col>

        <:col :let={patient_visit} label="Reason">
          <div class="max-w-xs py-3">
            <span class="text-slate-700 line-clamp-2">{patient_visit.reason}</span>
          </div>
        </:col>

        <:col :let={patient_visit} label="Receptionist/ Nurse">
          <div class="flex items-center py-3">
            <span class="text-slate-700">{patient_visit.creator.name}</span>
          </div>
        </:col>

        <:col :let={patient_visit} label="Doctor">
          <div class="flex items-center py-3">
            <%= if patient_visit.doctor && patient_visit.doctor.name do %>
              <span class="px-2 py-1 text-xs rounded-full bg-brand-100 text-brand-primary">
                Dr. {patient_visit.doctor.name}
              </span>
            <% else %>
              <span class="px-2 py-1 text-xs rounded-full bg-slate-100 text-slate-500">
                Not Assigned
              </span>
            <% end %>
          </div>
        </:col>
      </.data_table>

      <.pagination
        page={@page}
        total_pages={@total_pages}
        total_count={@total_count}
        per_page={@per_page}
      />
    </div>
    """
  end
end
