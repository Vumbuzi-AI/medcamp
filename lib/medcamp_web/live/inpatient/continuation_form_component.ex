defmodule MedcampWeb.Inpatient.ContinuationFormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Inpatient

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="mb-4">
        {@title}
        <:subtitle>Add ward round or review notes</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="continuation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <.input field={@form[:review_date]} type="date" label="Review Date" />
          <.input field={@form[:review_time]} type="time" label="Review Time" />
          <.input
            field={@form[:review_type]}
            type="select"
            label="Review Type"
            options={Medcamp.Inpatient.ContinuationNote.review_types()}
            prompt="Select review type"
          />
        </div>

        <.input
          field={@form[:complaints]}
          type="textarea"
          label="Complaints"
          placeholder="Current complaints or changes since last review..."
          rows={3}
        />

        <.input
          field={@form[:physical_examination]}
          type="textarea"
          label="Physical Examination"
          placeholder="Physical examination findings..."
          rows={3}
        />

        <.input
          field={@form[:management_plan]}
          type="textarea"
          label="Management Plan"
          placeholder="Updated management plan..."
          rows={3}
        />
        
    <!-- Vital Signs Section -->
        <div class="border-t border-gray-200 pt-4 mt-4">
          <h3 class="text-sm font-semibold text-gray-700 mb-3">Vital Signs</h3>
          <div class="grid grid-cols-2 md:grid-cols-5 gap-3">
            <.input field={@form[:blood_pressure]} type="text" label="BP (mmHg)" placeholder="120/80" />
            <.input field={@form[:pulse_rate]} type="number" label="Pulse (B/Min)" placeholder="72" />
            <.input
              field={@form[:temperature]}
              type="number"
              label="Temp (°C)"
              placeholder="36.5"
              step="0.1"
            />
            <.input field={@form[:spo2]} type="number" label="SpO2 (%)" placeholder="98" />
            <.input
              field={@form[:respiratory_rate]}
              type="number"
              label="RR (Br/Min)"
              placeholder="16"
            />
          </div>
        </div>

        <:actions>
          <.button phx-disable-with="Saving..." class="bg-blue-500 hover:bg-blue-600">
            Save Continuation Note
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{continuation_note: continuation_note} = assigns, socket) do
    changeset = Inpatient.change_continuation_note(continuation_note)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"continuation_note" => params}, socket) do
    changeset =
      socket.assigns.continuation_note
      |> Inpatient.change_continuation_note(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"continuation_note" => params}, socket) do
    params =
      params
      |> Map.put("admission_note_id", socket.assigns.admission_note.id)
      |> Map.put("doctor_id", socket.assigns.current_user.id)

    case Inpatient.create_continuation_note(params) do
      {:ok, _continuation_note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Continuation note added successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: "continuation_note"))
  end
end
