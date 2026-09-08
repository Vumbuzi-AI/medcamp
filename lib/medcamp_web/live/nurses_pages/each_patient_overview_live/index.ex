defmodule MedcampWeb.NursesPages.EachPatientOverviewIndex do
  use MedcampWeb, :nurse_each_patient_live_view

  alias Medcamp.Patients
  alias Medcamp.Triages
  alias Phoenix.LiveView.JS

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :patient_overview)
     |> assign(:show_edit_patient_modal, false)}
  end

  @impl true
  def handle_params(%{"patient_id" => id}, _url, socket) do
    patient = Patients.get_patient!(id)

    most_recent_triage = Triages.most_recent_triage(id)

    {:noreply,
     socket
     |> assign(:page_title, "Patient Overview")
     |> assign(:patient, patient)
     |> assign(:most_recent_triage, most_recent_triage)
     |> assign(:form, to_form(Patients.change_patient(patient)))}
  end

  @impl true
  def handle_event("validate", %{"patient" => patient_params}, socket) do
    changeset =
      Patients.change_patient(socket.assigns.patient, patient_params)

    {:noreply, assign(socket, :form, to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("edit_patient", _params, socket) do
    {:noreply, assign(socket, :show_edit_patient_modal, true)}
  end

  @impl true
  def handle_event("close_edit_patient_modal", _params, socket) do
    {:noreply, assign(socket, :show_edit_patient_modal, false)}
  end

  @impl true
  def handle_info({:patient_updated, patient}, socket) do
    patient = Patients.get_patient!(patient.id)

    {:noreply,
     socket
     |> assign(:patient, patient)
     |> assign(:form, to_form(Patients.change_patient(patient)))
     |> assign(:show_edit_patient_modal, false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.patient_overview
        patient={@patient}
        form={@form}
        most_recent_triage={@most_recent_triage}
        back_url="/nurse/patients"
        show_birth_certificate={false}
        show_insurance_details={false}
        new_triage_url={~p"/nurse/#{@patient.id}/triages/new"}
      />

      <.modal
        :if={@show_edit_patient_modal}
        id="edit-patient-modal"
        show
        on_cancel={JS.push("close_edit_patient_modal")}
      >
        <.live_component
          module={MedcampWeb.EditPatientComponent}
          id={"edit-patient-#{@patient.id}"}
          patient={@patient}
          current_user={@current_user}
        />
      </.modal>
    </div>
    """
  end
end
