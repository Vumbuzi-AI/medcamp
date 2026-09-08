defmodule MedcampWeb.DoctorsPagePatientLive.TriageFormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Triages

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <p class="text-lg text-darkblue font-semibold">Triage</p>

      <.simple_form
        for={@form}
        id="triage-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <.input field={@form[:date]} type="date" label="Date" />
          <.input field={@form[:time]} type="time" label="Time" />
          <.input field={@form[:temperature]} type="number" label="Temperature" step="any" />
          <.input field={@form[:blood_pressure]} type="text" label="Blood pressure" step="any" />
          <.input field={@form[:pulse_rate]} type="number" label="Pulse rate" step="any" />
          <.input
            field={@form[:oxygen_saturation]}
            type="number"
            label="Oxygen saturation"
            step="any"
          />
          <.input field={@form[:height]} type="number" label="Height" step="any" />
          <.input field={@form[:weight]} type="number" label="Weight" step="any" />
          <.input field={@form[:alert]} type="checkbox" label="Alert" />
          <.input field={@form[:verbal]} type="checkbox" label="Verbal" />
          <.input field={@form[:pain]} type="checkbox" label="Pain" />
          <.input field={@form[:unresponsive]} type="checkbox" label="Unresponsive" />
        </div>
        <.input field={@form[:allergies]} type="textarea" label="Allergies" />
        <.input
          field={@form[:emergency_scale]}
          type="select"
          options={[
            {"High (Red)", "High"},
            {"Medium (Amber)", "Medium"},
            {"Low (Green)", "Low"}
          ]}
          prompt="Select emergency scale"
          label="Emergency scale"
        />

        <.input field={@form[:triage_notes]} type="textarea" label="Triage notes" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Triage</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{triage: triage} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Triages.change_triage(triage))
     end)}
  end

  @impl true
  def handle_event("validate", %{"triage" => triage_params}, socket) do
    changeset = Triages.change_triage(socket.assigns.triage, triage_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"triage" => triage_params}, socket) do
    triage_params =
      triage_params
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> Map.put("creator_id", socket.assigns.current_user.id)

    save_triage(socket, socket.assigns.action, triage_params)
  end

  defp save_triage(socket, :edit, triage_params) do
    case Triages.update_triage(socket.assigns.triage, triage_params) do
      {:ok, _triage} ->
        {:noreply,
         socket
         |> put_flash(:info, "Triage updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_triage(socket, :new, triage_params) do
    case Triages.create_triage(triage_params) do
      {:ok, _triage} ->
        {:noreply,
         socket
         |> put_flash(:info, "Triage created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
