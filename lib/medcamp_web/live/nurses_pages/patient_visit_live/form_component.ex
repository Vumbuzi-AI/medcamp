defmodule MedcampWeb.NursesPages.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.PatientVisits
  alias Medcamp.Patients

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="patient_visit-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:date]} type="date" label="Date" />
        <.input
          field={@form[:patient_id]}
          type="select"
          options={@patients}
          prompt="Select a patient"
          label="Patient"
        />

        <.input
          field={@form[:doctor_id]}
          type="select"
          options={@doctors}
          prompt="Select a doctor for the visit"
          label="Doctor for the visit"
        />
        <.input field={@form[:reason]} type="text" label="Reason For Visit" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Patient visit</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{patient_visit: patient_visit} = assigns, socket) do
    patients = Patients.list_patients_for_selection()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:patients, patients)
     |> assign_new(:form, fn ->
       to_form(PatientVisits.change_patient_visit(patient_visit))
     end)}
  end

  @impl true
  def handle_event("validate", %{"patient_visit" => patient_visit_params}, socket) do
    changeset =
      PatientVisits.change_patient_visit(socket.assigns.patient_visit, patient_visit_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"patient_visit" => patient_visit_params}, socket) do
    patient_visit_params =
      patient_visit_params
      |> Map.put("creator_id", socket.assigns.current_user.id)

    save_patient_visit(socket, socket.assigns.action, patient_visit_params)
  end

  defp save_patient_visit(socket, :edit, patient_visit_params) do
    case PatientVisits.update_patient_visit(socket.assigns.patient_visit, patient_visit_params) do
      {:ok, _patient_visit} ->
        {:noreply,
         socket
         |> put_flash(:info, "Patient visit updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_patient_visit(socket, :new, patient_visit_params) do
    case PatientVisits.create_patient_visit(patient_visit_params) do
      {:ok, _patient_visit} ->
        {:noreply,
         socket
         |> put_flash(:info, "Patient visit created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
