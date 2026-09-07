defmodule MedcampWeb.AdmitPatientComponent do
  use MedcampWeb, :live_component
  alias Medcamp.AdmissionRequests

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Admit {[@patient.first_name, @patient.middle_name, @patient.last_name]
        |> Enum.filter(&(&1 != nil))
        |> Enum.join(" ")}
      </.header>

      <.simple_form
        for={@form}
        id="admission_request-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:date]} type="date" label="Date" required />
        <.input field={@form[:start_time]} type="time" label="Start time (optional)" />
        <.input field={@form[:end_time]} type="time" label="End time (optional)" />

        <:actions>
          <.button phx-disable-with="Saving...">
            Admit Patient
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{admission_request: admission_request} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(AdmissionRequests.change_admission_request(admission_request))
     end)}
  end

  @impl true
  def handle_event("validate", %{"admission_request" => admission_request_params}, socket) do
    changeset =
      AdmissionRequests.change_admission_request(
        socket.assigns.admission_request,
        admission_request_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"admission_request" => admission_request_params}, socket) do
    params =
      admission_request_params
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> Map.put("doctor_id", socket.assigns.current_user.id)
      |> Map.put("doctor_note_id", socket.assigns.doctor_note.id)

    case AdmissionRequests.create_admission_request(params) do
      {:ok, _admission_request} ->
        {:noreply,
         socket
         |> put_flash(:info, "Admission request created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
