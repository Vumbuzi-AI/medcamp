defmodule MedcampWeb.NursesPages.EachPatientCadexNoteIndex do
  use MedcampWeb, :nurse_each_patient_live_view

  alias Medcamp.CadexNotes
  alias Medcamp.CadexNotes.CadexNote
  alias Medcamp.Patients
  alias Medcamp.Inpatient

  @impl true
  def mount(%{"patient_id" => patient_id}, _session, socket) do
    patient = Patients.get_patient!(patient_id)
    admission_notes = Inpatient.list_admission_notes_for_patient(patient_id)
    current_admission = Inpatient.get_current_admission(patient_id)

    {:ok,
     socket
     |> assign(:patient, patient)
     |> assign(:admission_notes, admission_notes)
     |> assign(:current_admission, current_admission)
     |> assign(:selected_admission, current_admission || List.first(admission_notes))
     |> assign(:cadex_notes_list, [])
     |> assign(:active_tab, :cadex_notes)
     |> assign(:cadex_notes, [])}
  end

  @impl true
  def handle_params(params, _url, socket) do
    params = params || %{}
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, _action, params)

  defp apply_action(socket, :edit, %{"id" => id}) do
    cadex_note = CadexNotes.get_cadex_note!(id)
    selected_admission = cadex_note.admission_note || socket.assigns.current_admission

    socket
    |> assign(:page_title, "Edit CaDex note")
    |> assign(:cadex_note, cadex_note)
    |> assign(:selected_admission, selected_admission)
    |> load_cadex_for_admission(selected_admission)
  end

  defp apply_action(socket, :new, params) do
    default_time =
      Time.utc_now()
      |> Time.add(3 * 60 * 60)
      |> Time.truncate(:second)

    selected_admission = select_admission(socket, params)
    stream_socket = load_cadex_for_admission(socket, selected_admission)

    stream_socket
    |> assign(:page_title, "New CaDex note")
    |> assign(:cadex_note, %CadexNote{note_date: Date.utc_today(), note_time: default_time})
    |> assign(:selected_admission, selected_admission)
  end

  defp apply_action(socket, :index, params) do
    selected_admission = select_admission(socket, params)

    socket
    |> assign(:page_title, "Listing CaDex notes")
    |> assign(:cadex_note, nil)
    |> assign(:selected_admission, selected_admission)
    |> load_cadex_for_admission(selected_admission)
  end

  defp select_admission(socket, params) do
    params = params || %{}
    admission_id = params["admission_id"]
    current = socket.assigns.current_admission
    all = socket.assigns.admission_notes || []

    aid =
      case admission_id && Integer.parse(to_string(admission_id)) do
        {id, _} -> id
        _ -> nil
      end

    cond do
      aid -> Enum.find(all, &(&1.id == aid)) || current || List.first(all)
      current -> current
      true -> List.first(all)
    end
  end

  defp load_cadex_for_admission(socket, nil) do
    socket
    |> assign(:cadex_notes, [])
    |> assign(:cadex_notes_list, [])
  end

  defp load_cadex_for_admission(socket, admission) do
    notes = CadexNotes.list_cadex_notes_for_admission(admission.id)

    socket
    |> assign(:cadex_notes, notes)
    |> assign(:cadex_notes_list, notes)
  end

  defp cadex_index_patch(patient_id, nil), do: "/nurse/#{patient_id}/cadex_notes"

  defp cadex_index_patch(patient_id, adm),
    do: "/nurse/#{patient_id}/cadex_notes?admission_id=#{adm.id}"

  def handle_event("change_admission", %{"admission_id" => admission_id}, socket) do
    {:noreply,
     push_patch(socket,
       to: "/nurse/#{socket.assigns.patient.id}/cadex_notes?admission_id=#{admission_id}"
     )}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    cadex_note = CadexNotes.get_cadex_note!(id)
    {:ok, _} = CadexNotes.delete_cadex_note(cadex_note)

    {:noreply,
     socket
     |> assign(:cadex_notes, Enum.reject(socket.assigns.cadex_notes, &(&1.id == cadex_note.id)))
     |> assign(
       :cadex_notes_list,
       Enum.reject(socket.assigns.cadex_notes_list, &(&1.id == cadex_note.id))
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
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
          CaDex Notes for {[
            @patient.first_name,
            @patient.middle_name,
            @patient.last_name
          ]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}
        </div>
        <:actions>
          <%= if @selected_admission do %>
            <.link patch={"/nurse/#{@patient.id}/cadex_notes/new?admission_id=#{@selected_admission.id}"}>
              <.button class="bg-[#6667ab] hover:bg-[#5556a0]">
                <div class="flex items-center">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="h-4 w-4 mr-2"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M12 4v16m8-8H4"
                    />
                  </svg>
                  New CaDex Note
                </div>
              </.button>
            </.link>
          <% end %>
        </:actions>
      </.header>

      <%= if is_nil(@selected_admission) do %>
        <div class="text-center py-8 bg-amber-50 rounded-lg border border-amber-200">
          <p class="text-amber-800 font-medium">CaDex notes are attached to admissions</p>
          <p class="mt-1 text-sm text-amber-700">
            Patient has no admissions, or select an admission above. Create an admission in Doctor Notes → Inpatient first.
          </p>
        </div>
      <% else %>
        <%= if length(@admission_notes) > 1 do %>
          <form phx-change="change_admission" class="mb-4">
            <label class="block text-sm font-medium text-gray-700 mb-1">
              View CaDex for admission
            </label>
            <select name="admission_id" class="block w-full rounded-lg border-gray-300 text-sm">
              <%= for adm <- @admission_notes do %>
                <option
                  value={adm.id}
                  selected={@selected_admission && adm.id == @selected_admission.id}
                >
                  {Calendar.strftime(adm.admission_date, "%b %d, %Y")} — Ward: {adm.ward || "N/A"}, Bed: {adm.bed_number ||
                    "N/A"}
                  {if @current_admission && adm.id == @current_admission.id,
                    do: " (Current)",
                    else: ""}
                </option>
              <% end %>
            </select>
          </form>
        <% end %>
      <% end %>

      <%= if @selected_admission && Enum.empty?(@cadex_notes_list || []) do %>
        <div class="text-center py-8 bg-gray-50 rounded-lg border border-dashed border-gray-300">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="mx-auto h-12 w-12 text-gray-400"
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
          <h3 class="mt-2 text-sm font-medium text-gray-900">No CaDex notes for this admission</h3>
          <p class="mt-1 text-sm text-gray-500">
            Add a CaDex note for this admission above.
          </p>
        </div>
      <% else %>
        <.table
          id="cadex_notes"
          rows={@cadex_notes}
          row_click={
            fn cadex_note ->
              JS.patch("/nurse/#{@patient.id}/cadex_notes/#{cadex_note.id}/edit")
            end
          }
          row_id={&"cadex_notes-#{&1.id}"}
        >
          <:col :let={cadex_note} label="Date">
            <div class="py-3">
              <span class="font-medium text-gray-900">
                {cadex_note.note_date && Calendar.strftime(cadex_note.note_date, "%d %b %Y")}
              </span>
            </div>
          </:col>

          <:col :let={cadex_note} label="Time">
            <div class="py-3">
              <span class="text-gray-700">
                {cadex_note.note_time && Calendar.strftime(cadex_note.note_time, "%H:%M")}
              </span>
            </div>
          </:col>

          <:col :let={cadex_note} label="Nursing Note">
            <div class="max-w-md py-3">
              <span class="text-gray-700 line-clamp-2">{cadex_note.note}</span>
            </div>
          </:col>

          <:col :let={cadex_note} label="Nurse">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-[#f0f0ff] text-[#373896]">
                {cadex_note.nurse.name}
              </span>
            </div>
          </:col>

          <:action :let={cadex_note}>
            <div class="flex items-center justify-center">
              <.link
                patch={"/nurse/#{@patient.id}/cadex_notes/#{cadex_note.id}/edit"}
                class="flex items-center text-[#6667ab] hover:text-[#373896]"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-1"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                  />
                </svg>
                Edit
              </.link>
            </div>
          </:action>

          <:action :let={cadex_note}>
            <div class="flex items-center justify-center">
              <.link
                phx-click={JS.push("delete", value: %{id: cadex_note.id}) |> hide("#cadex_notes-#{cadex_note.id}")}
                data-confirm="Are you sure?"
                class="flex items-center text-red-600 hover:text-red-800"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-1"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                  />
                </svg>
                Delete
              </.link>
            </div>
          </:action>
        </.table>
      <% end %>
    </div>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="cadex_note-modal"
      show
      on_cancel={JS.patch(cadex_index_patch(@patient.id, @selected_admission))}
    >
      <.live_component
        module={MedcampWeb.CadexNoteLive.FormComponent}
        id={@cadex_note.id || :new}
        title={@page_title}
        action={@live_action}
        patient={@patient}
        current_user={@current_user}
        admission_note={@selected_admission}
        cadex_note={@cadex_note}
        patch={cadex_index_patch(@patient.id, @selected_admission)}
      />
    </.modal>
    """
  end
end
