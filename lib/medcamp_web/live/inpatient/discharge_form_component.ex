defmodule MedcampWeb.Inpatient.DischargeFormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Inpatient

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="mb-4">
        {@title}
        <:subtitle>Create discharge summary for the patient</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="discharge-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:discharge_date]} type="date" label="Discharge Date" />

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input
            field={@form[:admission_diagnosis]}
            type="textarea"
            label="Admission Diagnosis"
            placeholder="Diagnosis at the time of admission..."
            rows={2}
          />
          <.input
            field={@form[:discharge_diagnosis]}
            type="textarea"
            label="Discharge Diagnosis"
            placeholder="Final diagnosis at discharge..."
            rows={2}
          />
        </div>

        <.input
          field={@form[:clinical_history]}
          type="textarea"
          label="Clinical History & Physical Examination"
          placeholder="Summary of clinical history and examination findings..."
          rows={3}
        />

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input
            field={@form[:procedures_done]}
            type="textarea"
            label="Procedures Done"
            placeholder="List of procedures performed..."
            rows={2}
          />
          <.input
            field={@form[:lab_investigations]}
            type="textarea"
            label="Lab/Investigations Done"
            placeholder="Lab tests and investigations performed..."
            rows={2}
          />
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input
            field={@form[:drugs_given]}
            type="textarea"
            label="Drugs & Fluids Given"
            placeholder="Medications and fluids administered during stay..."
            rows={2}
          />
          <.input
            field={@form[:discharge_drugs]}
            type="textarea"
            label="Discharge Drugs"
            placeholder="Medications prescribed at discharge..."
            rows={2}
          />
        </div>

        <div class="border-t border-gray-200 pt-4 mt-4">
          <h3 class="text-sm font-semibold text-gray-700 mb-3">Follow-up (TCA)</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <.input field={@form[:follow_up_date]} type="date" label="Follow-up Date" />
            <.input
              field={@form[:follow_up_clinic]}
              type="text"
              label="Clinic"
              placeholder="e.g., General OPD, Surgical"
            />
          </div>
        </div>

        <.input
          field={@form[:doctor_notes]}
          type="textarea"
          label="Additional Notes"
          placeholder="Any additional instructions or notes..."
          rows={2}
        />

        <:actions>
          <.button phx-disable-with="Saving..." class="bg-amber-500 hover:bg-amber-600">
            Create Discharge Summary
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{discharge_summary: discharge_summary} = assigns, socket) do
    changeset = Inpatient.change_discharge_summary(discharge_summary)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"discharge_summary" => params}, socket) do
    changeset =
      socket.assigns.discharge_summary
      |> Inpatient.change_discharge_summary(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"discharge_summary" => params}, socket) do
    params =
      params
      |> Map.put("admission_note_id", socket.assigns.admission_note.id)
      |> Map.put("doctor_id", socket.assigns.current_user.id)

    case Inpatient.create_discharge_summary(params) do
      {:ok, _discharge_summary} ->
        {:noreply,
         socket
         |> put_flash(:info, "Discharge summary created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: "discharge_summary"))
  end
end
