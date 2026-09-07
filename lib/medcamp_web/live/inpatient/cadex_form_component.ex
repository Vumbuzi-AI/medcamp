defmodule MedcampWeb.Inpatient.CadexFormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.CadexNotes

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="mb-4">
        {@title}
        <:subtitle>Nursing CaDex note for this admission</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="cadex-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input field={@form[:note_date]} type="date" label="Date" required />
          <.input field={@form[:note_time]} type="time" label="Time" required />
        </div>

        <.input
          field={@form[:note]}
          type="textarea"
          label="Nursing Note"
          placeholder="Write the CaDex nursing note..."
          rows={5}
          required
        />

        <:actions>
          <.button phx-disable-with="Saving..." class="bg-[#6667ab] hover:bg-[#5556a0]">
            Save CaDex Note
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{cadex_note: cadex_note} = assigns, socket) do
    changeset = CadexNotes.change_cadex_note(cadex_note)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"cadex_note" => params}, socket) do
    changeset =
      socket.assigns.cadex_note
      |> CadexNotes.change_cadex_note(params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"cadex_note" => params}, socket) do
    params =
      params
      |> Map.put("admission_note_id", socket.assigns.admission_note.id)
      |> Map.put("patient_id", socket.assigns.admission_note.patient_id)
      |> Map.put("nurse_id", socket.assigns.current_user.id)

    case socket.assigns.action do
      :new_cadex ->
        case CadexNotes.create_cadex_note(params) do
          {:ok, _cadex_note} ->
            {:noreply,
             socket
             |> put_flash(:info, "CaDex note added successfully")
             |> push_patch(to: socket.assigns.patch)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign_form(socket, changeset)}
        end

      :edit_cadex ->
        case CadexNotes.update_cadex_note(socket.assigns.cadex_note, params) do
          {:ok, _cadex_note} ->
            {:noreply,
             socket
             |> put_flash(:info, "CaDex note updated successfully")
             |> push_patch(to: socket.assigns.patch)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign_form(socket, changeset)}
        end
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset, as: "cadex_note"))
  end
end
