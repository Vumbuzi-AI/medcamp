defmodule MedcampWeb.AppointmentLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Appointments
  alias Medcamp.Patients
  alias Medcamp.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="appointment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:date]} type="date" label="Date" />
        <.input field={@form[:time]} type="time" label="Time" />
        <%= if @selected_patient do %>
          <.input
            field={@form[:patient_id]}
            type="select"
            disabled={true}
            value={@selected_patient.id}
            options={@patients}
            prompt="Select a patient"
            label="Patient"
          />
        <% else %>
          <.input
            field={@form[:patient_id]}
            type="select"
            options={@patients}
            prompt="Select a patient"
            label="Patient"
          />
        <% end %>
        <.input
          field={@form[:doctor_id]}
          type="select"
          options={@doctors}
          prompt="Select a doctor for the visit"
          label="Doctor for the visit"
        />
        <.input
          field={@form[:reason]}
          type="select"
          options={[
            "Chest Pain",
            "Difficulty Breathing",
            "Abdominal Pain",
            "Injury/Trauma",
            "High Fever",
            "Severe Headache",
            "Nausea/Vomiting",
            "Back Pain",
            "Dizziness/Fainting",
            "Allergic Reaction",
            "Flu Symptoms",
            "Scheduled Surgery",
            "Diagnostic Test/Imaging",
            "Annual Check-up",
            "Pregnancy Check-up",
            "Chronic Disease Management",
            "Mental Health Issue",
            "Prescription Refill",
            "Laboratory Work",
            "Follow-up Appointment"
          ]}
          prompt="Select a reason for the appointment"
          label="Reason"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Appointment</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{appointment: appointment} = assigns, socket) do
    patients = Patients.list_patients_for_selection()
    doctors = Accounts.list_all_doctors_for_selection()

    IO.inspect(assigns.selected_patient, label: "Selected Patient")

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:patients, patients)
     |> assign(:doctors, doctors)
     |> assign_new(:form, fn ->
       to_form(Appointments.change_appointment(appointment))
     end)}
  end

  @impl true
  def handle_event("validate", %{"appointment" => appointment_params}, socket) do
    changeset = Appointments.change_appointment(socket.assigns.appointment, appointment_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"appointment" => appointment_params}, socket) do
    appointment_params =
      if socket.assigns.selected_patient do
        Map.put(appointment_params, "patient_id", socket.assigns.selected_patient.id)
      else
        appointment_params
      end

    save_appointment(socket, socket.assigns.action, appointment_params)
  end

  defp save_appointment(socket, :edit, appointment_params) do
    case Appointments.update_appointment(socket.assigns.appointment, appointment_params) do
      {:ok, _appointment} ->
        {:noreply,
         socket
         |> put_flash(:info, "Appointment updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_appointment(socket, :new, appointment_params) do
    case Appointments.create_appointment(appointment_params) do
      {:ok, _appointment} ->
        {:noreply,
         socket
         |> put_flash(:info, "Appointment created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
