defmodule MedcampWeb.CadexNoteLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.CadexNotes

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-4">
        <div class="flex items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-[#6667ab]"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
            />
          </svg>
          {@title}
        </div>
      </.header>

      <.simple_form
        for={@form}
        id="cadex_note-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <.input field={@form[:note_date]} type="date" label="Date" required />
          <.input field={@form[:note_time]} type="time" label="Time" required />
        </div>

        <div class="mt-4">
          <.input
            field={@form[:note]}
            type="textarea"
            label="Nursing Note"
            placeholder="Write the CaDex nursing note..."
            required
          />
        </div>

        <:actions>
          <.button phx-disable-with="Saving..." class="bg-[#6667ab] hover:bg-[#5556a0]" type="submit">
            Save CaDex note
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{cadex_note: cadex_note} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(CadexNotes.change_cadex_note(cadex_note))
     end)}
  end

  @impl true
  def handle_event("validate", %{"cadex_note" => cadex_note_params}, socket) do
    changeset = CadexNotes.change_cadex_note(socket.assigns.cadex_note, cadex_note_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  @impl true
  def handle_event("save", %{"cadex_note" => cadex_note_params}, socket) do
    cadex_note_params =
      cadex_note_params
      |> Map.put("nurse_id", socket.assigns.current_user.id)
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> maybe_put_admission_note_id(socket)

    save_cadex_note(socket, socket.assigns.action, cadex_note_params)
  end

  defp maybe_put_admission_note_id(params, socket) do
    case socket.assigns[:admission_note] do
      %{id: id} -> Map.put(params, "admission_note_id", id)
      _ -> params
    end
  end

  defp save_cadex_note(socket, :edit, cadex_note_params) do
    case CadexNotes.update_cadex_note(socket.assigns.cadex_note, cadex_note_params) do
      {:ok, _cadex_note} ->
        {:noreply,
         socket
         |> put_flash(:info, "CaDex note updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_cadex_note(socket, :new, cadex_note_params) do
    case CadexNotes.create_cadex_note(cadex_note_params) do
      {:ok, _cadex_note} ->
        {:noreply,
         socket
         |> put_flash(:info, "CaDex note created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
