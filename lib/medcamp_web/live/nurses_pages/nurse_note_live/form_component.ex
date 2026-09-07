defmodule MedcampWeb.NurseNoteLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.NurseNotes

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="nurse_note-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:content]} type="textarea" label="Content" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Nurse note</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{nurse_note: nurse_note} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(NurseNotes.change_nurse_note(nurse_note))
     end)}
  end

  @impl true
  def handle_event("validate", %{"nurse_note" => nurse_note_params}, socket) do
    changeset = NurseNotes.change_nurse_note(socket.assigns.nurse_note, nurse_note_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"nurse_note" => nurse_note_params}, socket) do
    nurse_note_params =
      Map.put(nurse_note_params, "nurse_id", socket.assigns.current_user.id)
      |> Map.put("patient_id", socket.assigns.patient.id)

    save_nurse_note(socket, socket.assigns.action, nurse_note_params)
  end

  defp save_nurse_note(socket, :edit, nurse_note_params) do
    case NurseNotes.update_nurse_note(socket.assigns.nurse_note, nurse_note_params) do
      {:ok, _nurse_note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Nurse note updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_nurse_note(socket, :new, nurse_note_params) do
    case NurseNotes.create_nurse_note(nurse_note_params) do
      {:ok, _nurse_note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Nurse note created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
