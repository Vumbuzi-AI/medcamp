defmodule MedcampWeb.Inpatient.TreatmentFormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Inpatient

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="mb-4">
        {@title}
        <:subtitle>
          {if @action == :edit_treatment,
            do: "Update medication prescription",
            else: "Add medication prescription to treatment sheet"}
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="treatment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <.input field={@form[:prescription_date]} type="date" label="Prescription Date" />
          <.input field={@form[:prescription_time]} type="time" label="Prescription Time" />
          <.input
            field={@form[:prescription_type]}
            type="select"
            label="Prescription Type"
            options={Medcamp.Inpatient.TreatmentSheet.prescription_types()}
          />
        </div>

        <.input field={@form[:drug_name]} type="text" label="Drug Name" placeholder="Enter drug name" />

        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
          <.input
            field={@form[:route]}
            type="select"
            label="Route"
            options={Medcamp.Inpatient.TreatmentSheet.route_types()}
            prompt="Select route"
          />
          <.input field={@form[:dose]} type="text" label="Dose" placeholder="e.g., 500" />
          <.input field={@form[:units]} type="text" label="Units" placeholder="e.g., mg, ml" />
          <.input field={@form[:frequency]} type="text" label="Frequency" placeholder="e.g., TDS, BD" />
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input
            field={@form[:duration_days]}
            type="number"
            label="Duration (Days)"
            placeholder="e.g., 7"
          />
          <.input
            field={@form[:notes]}
            type="text"
            label="Notes"
            placeholder="Any special instructions"
          />
        </div>

        <:actions>
          <.button phx-disable-with="Saving..." class="bg-emerald-500 hover:bg-emerald-600">
            {if @action == :edit_treatment, do: "Update Treatment", else: "Add to Treatment Sheet"}
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{treatment_sheet: treatment_sheet} = assigns, socket) do
    changeset = Inpatient.change_treatment_sheet(treatment_sheet)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"treatment_sheet" => params}, socket) do
    changeset =
      socket.assigns.treatment_sheet
      |> Inpatient.change_treatment_sheet(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"treatment_sheet" => params}, socket) do
    params =
      params
      |> Map.put("admission_note_id", socket.assigns.admission_note.id)
      |> Map.put("prescriber_id", socket.assigns.current_user.id)

    result =
      if socket.assigns.action == :edit_treatment && socket.assigns.treatment_sheet.id do
        Inpatient.update_treatment_sheet(socket.assigns.treatment_sheet, params)
      else
        Inpatient.create_treatment_sheet(params)
      end

    case result do
      {:ok, _treatment_sheet} ->
        flash_msg =
          if socket.assigns.action == :edit_treatment,
            do: "Treatment updated successfully",
            else: "Prescription added to treatment sheet"

        {:noreply,
         socket
         |> put_flash(:info, flash_msg)
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: "treatment_sheet"))
  end
end
