defmodule MedcampWeb.DoctorsPagePatientLive.DoctorNoteIndex do
  use MedcampWeb, :each_patient_live_view
  alias Medcamp.Patients
  alias Medcamp.DoctorNotes
  alias Medcamp.PatientVisits

  defp kenya_today do
    DateTime.utc_now()
    |> DateTime.add(3 * 60 * 60, :second)
    |> DateTime.to_date()
  end

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :doctor_notes)
     |> assign(:show_visit_modal, false)
     |> assign(:visit_modal_date, kenya_today())
     |> assign(:visits_for_modal, [])
     |> assign_doctor_notes(id)}
  end

  defp assign_doctor_notes(socket, patient_id) do
    doctor_notes = DoctorNotes.doctor_notes_for_patient(patient_id)

    socket
    |> assign(:doctor_notes_count, length(doctor_notes))
    |> assign(:doctor_notes, doctor_notes)
  end

  @impl true
  def handle_params(%{"id" => id} = params, _url, socket) do
    patient = Patients.get_patient!(id)

    {:noreply,
     socket
     |> assign(:patient, patient)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Doctor notes")
  end

  @impl true
  def handle_event("open_add_note_modal", _params, socket) do
    date = socket.assigns.visit_modal_date || kenya_today()
    visits = PatientVisits.list_visits_without_doctor_note(socket.assigns.patient.id, date)

    {:noreply,
     socket
     |> assign(:show_visit_modal, true)
     |> assign(:visit_modal_date, date)
     |> assign(:visits_for_modal, visits)}
  end

  def handle_event("close_visit_modal", _params, socket) do
    {:noreply, assign(socket, :show_visit_modal, false)}
  end

  def handle_event("change_visit_modal_date", %{"date" => date_str}, socket) do
    date = Date.from_iso8601!(date_str)
    visits = PatientVisits.list_visits_without_doctor_note(socket.assigns.patient.id, date)

    {:noreply,
     socket
     |> assign(:visit_modal_date, date)
     |> assign(:visits_for_modal, visits)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-[100%]">
      <.doctor_notes_table
        route_prefix={"/doctor/patients/#{@patient.id}/notes"}
        add_note_click="open_add_note_modal"
        doctor_notes={@doctor_notes}
        patient={@patient}
        count={@doctor_notes_count}
      />

      <.modal
        :if={@show_visit_modal}
        id="select-visit-modal"
        show
        on_cancel={JS.push("close_visit_modal")}
      >
        <div class="p-6">
          <h2 class="text-lg font-semibold text-[#373896] mb-4">
            Select Patient Visit
          </h2>
          <p class="text-sm text-gray-600 mb-4">
            Choose a visit to create a doctor note for. Each visit can have one doctor note.
          </p>

          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700 mb-1">Visit date</label>
            <form phx-change="change_visit_modal_date">
              <input
                type="date"
                name="date"
                value={@visit_modal_date && Calendar.strftime(@visit_modal_date, "%Y-%m-%d")}
                class="w-full rounded-lg border border-gray-300 px-3 py-2 focus:ring-[#6667ab] focus:border-[#6667ab]"
              />
            </form>
          </div>

          <div class="space-y-2 max-h-64 overflow-y-auto">
            <%= if @visits_for_modal == [] do %>
              <p class="text-gray-500 py-4 text-center">
                No visits without a doctor note for this date. Create a patient visit first.
              </p>
            <% else %>
              <%= for visit <- @visits_for_modal do %>
                <.link
                  navigate={"/doctor/patients/#{@patient.id}/notes/new?patient_visit_id=#{visit.id}"}
                  class="block p-4 rounded-lg border border-gray-200 hover:border-[#6667ab] hover:bg-[#f8f8ff] transition-colors"
                >
                  <div class="flex justify-between items-center">
                    <div>
                      <span class="font-medium text-gray-900">
                        {Calendar.strftime(visit.date, "%b %d, %Y")}
                      </span>
                      <span class="ml-2 text-gray-600">
                        {(visit.time && Calendar.strftime(visit.time, "%H:%M")) || "—"}
                      </span>
                    </div>
                    <div class="text-sm text-gray-500">
                      {visit.visit_type || "Visit"} • {visit.reason || "—" |> String.slice(0, 30)}
                    </div>
                    <span class="text-[#6667ab] text-sm font-medium">Create note →</span>
                  </div>
                </.link>
              <% end %>
            <% end %>
          </div>

          <div class="mt-6 flex justify-end">
            <button
              type="button"
              phx-click="close_visit_modal"
              class="px-4 py-2 text-gray-700 hover:text-gray-900"
            >
              Cancel
            </button>
          </div>
        </div>
      </.modal>
    </div>
    """
  end
end
