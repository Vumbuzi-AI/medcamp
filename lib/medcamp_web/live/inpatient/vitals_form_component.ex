defmodule MedcampWeb.Inpatient.VitalsFormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Inpatient

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="mb-4">
        {@title}
        <:subtitle>Record patient vital signs</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="vitals-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input field={@form[:recorded_date]} type="date" label="Date" />
          <.input field={@form[:recorded_time]} type="time" label="Time" />
        </div>

        <div class="grid grid-cols-2 md:grid-cols-5 gap-4">
          <.input
            field={@form[:blood_pressure]}
            type="text"
            label="Blood Pressure (mmHg)"
            placeholder="120/80"
          />
          <.input
            field={@form[:pulse_rate]}
            type="number"
            label="Pulse Rate (B/Min)"
            placeholder="72"
          />
          <.input
            field={@form[:temperature]}
            type="number"
            label="Temperature (°C)"
            placeholder="36.5"
            step="0.1"
          />
          <.input field={@form[:spo2]} type="number" label="SpO2 (%)" placeholder="98" />
          <.input
            field={@form[:respiratory_rate]}
            type="number"
            label="Respiratory Rate (Br/Min)"
            placeholder="16"
          />
        </div>

        <.input
          field={@form[:remarks]}
          type="textarea"
          label="Remarks"
          placeholder="Any additional observations or remarks..."
          rows={2}
        />

        <:actions>
          <.button phx-disable-with="Saving..." class="bg-rose-500 hover:bg-rose-600">
            Record Vitals
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{vital_record: vital_record} = assigns, socket) do
    changeset = Inpatient.change_vital_record(vital_record)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"vital_record" => params}, socket) do
    changeset =
      socket.assigns.vital_record
      |> Inpatient.change_vital_record(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"vital_record" => params}, socket) do
    params =
      params
      |> Map.put("admission_note_id", socket.assigns.admission_note.id)
      |> Map.put("recorded_by_id", socket.assigns.current_user.id)

    case Inpatient.create_vital_record(params) do
      {:ok, _vital_record} ->
        {:noreply,
         socket
         |> put_flash(:info, "Vital signs recorded successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: "vital_record"))
  end
end
