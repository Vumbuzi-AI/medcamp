defmodule MedcampWeb.DoctorsPagePatientLive.PendingIndex do
  use MedcampWeb, :doctor_live_view

  alias Medcamp.PatientVisits
  alias Medcamp.PatientVisits.PatientVisit

  @impl true
  def mount(_, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :pending)
     |> assign(:search, "")
     |> assign_pending_visits()}
  end

  defp assign_pending_visits(socket) do
    visits = PatientVisits.list_pending_visits(%{search: socket.assigns.search})

    socket
    |> assign(:pending_visits_count, length(visits))
    |> assign(:patient_visits, visits)
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

    {:noreply,
     socket
     |> update(:pending_visits_count, &max(&1 - 1, 0))
     |> assign(
       :patient_visits,
       Enum.reject(socket.assigns.patient_visits, &(&1.id == patient_visit.id))
     )}
  end

  @impl true
  def handle_event("search", %{"search" => term}, socket) do
    {:noreply, socket |> assign(:search, term) |> assign_pending_visits()}
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply, socket |> assign(:search, "") |> assign_pending_visits()}
  end

  def handle_event("see_patient", %{"id" => id}, socket) do
    patient_visit = PatientVisits.get_patient_visit!(id)

    {:ok, _} =
      PatientVisits.update_patient_visit(patient_visit, %{
        doctor_id: socket.assigns.current_user.id
      })

    {:noreply,
     socket
     |> put_flash(:info, "Patient Visit updated successfully")
     |> assign_pending_visits()}
  end

  @impl true

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
      <.page_header
        icon_path="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
        title="Pending Visits"
        subtitle="Search patient visits waiting for a doctor."
      />

      <form phx-change="search" class="mb-4">
        <.search_input name="search" value={@search} placeholder="Search by patient name or GSRN" />
      </form>

      <.blank_state
        :if={@pending_visits_count == 0}
        icon_path="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
        title="No pending visits"
        description={
          if @search != "",
            do: "No pending visits match the current search.",
            else: "There are no patient visits waiting for a doctor."
        }
      >
        <:actions :if={@search != ""}>
          <button phx-click="clear_search" class="text-xs text-brand-accent hover:underline">
            Clear search
          </button>
        </:actions>
      </.blank_state>

      <.table
        :if={@pending_visits_count > 0}
        id="patient_visits"
        rows={@patient_visits}
        row_id={&"patient_visits-#{&1.id}"}
      >
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

        <:col :let={patient_visit} label="Reason">
          <div class="max-w-xs py-3">
            <span class="text-gray-700 line-clamp-2">{patient_visit.reason}</span>
          </div>
        </:col>

        <:col :let={patient_visit} label="Receptionist/ Nurse">
          <div class="flex items-center py-3">
            <span class="text-gray-700">{patient_visit.creator.name}</span>
          </div>
        </:col>

        <:col :let={patient_visit} label="Actions">
          <div class="py-2">
            <.button
              data-confirm="Are you sure you want to see this patient?"
              phx-click="see_patient"
              phx-value-id={patient_visit.id}
              class="bg-brand-accent hover:bg-brand-accent-dark text-white font-medium py-2 px-4 rounded-md text-sm"
            >
              See Patient
            </.button>
          </div>
        </:col>
      </.table>
    </div>
    """
  end

  # The table is expandable, so it renders eagerly rather than under
  # `phx-update="stream"` and must be fed a plain list. Replace the row in place
  # when it is already listed, otherwise prepend it.
  defp upsert(rows, row) do
    if Enum.any?(rows, &(&1.id == row.id)) do
      Enum.map(rows, &if(&1.id == row.id, do: row, else: &1))
    else
      [row | rows]
    end
  end
end
