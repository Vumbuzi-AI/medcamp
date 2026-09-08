defmodule MedcampWeb.DoctorsPagePatientLive.DoctorNoteIndex do
  use MedcampWeb, :each_patient_live_view
  alias Medcamp.Patients
  alias Medcamp.DoctorNotes
  alias Medcamp.PatientVisits

  @impl true
  def mount(%{"id" => id} = _params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :doctor_notes)
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
  def handle_event("open_add_note", _params, socket) do
    patient_id = socket.assigns.patient.id

    case PatientVisits.latest_visit_without_doctor_note(patient_id) do
      nil ->
        {:noreply,
         put_flash(socket, :error, "This patient has no visit available for a doctor note")}

      visit ->
        {:noreply,
         push_navigate(
           socket,
           to: "/doctor/patients/#{patient_id}/notes/new?patient_visit_id=#{visit.id}"
         )}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-[100%]">
      <.doctor_notes_table
        route_prefix={"/doctor/patients/#{@patient.id}/notes"}
        add_note_click="open_add_note"
        doctor_notes={@doctor_notes}
        patient={@patient}
        count={@doctor_notes_count}
      />
    </div>
    """
  end
end
