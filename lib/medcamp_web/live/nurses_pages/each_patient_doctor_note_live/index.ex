defmodule MedcampWeb.NursesPages.EachPatientDoctorNoteIndex do
  use MedcampWeb, :nurse_each_patient_live_view
  alias Medcamp.Patients
  alias Medcamp.DoctorNotes

  @impl true
  def mount(%{"patient_id" => id} = _params, _session, socket) do
    doctor_notes = DoctorNotes.doctor_notes_for_patient(id)

    {:ok,
     socket
     |> assign(:active_tab, :doctor_notes)
     |> assign(:doctor_notes_count, length(doctor_notes))
     |> assign(:doctor_notes, doctor_notes)}
  end

  @impl true
  def handle_params(%{"patient_id" => id} = params, _url, socket) do
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
  def render(assigns) do
    ~H"""
    <div class="w-[100%]">
      <.nurse_doctor_notes_table
        route_prefix={"/nurse/#{@patient.id}/doctor_notes"}
        doctor_notes={@doctor_notes}
        patient={@patient}
        count={@doctor_notes_count}
      />
    </div>
    """
  end
end
