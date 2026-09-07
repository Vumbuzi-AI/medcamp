defmodule MedcampWeb.NursesPages.EachPatientNurseNoteIndex do
  use MedcampWeb, :nurse_each_patient_live_view

  alias Medcamp.NurseNotes
  alias Medcamp.NurseNotes.NurseNote
  alias Medcamp.Patients

  @per_page 10

  @impl true
  def mount(%{"patient_id" => id}, _session, socket) do
    patient = Patients.get_patient!(id)

    {:ok,
     socket
     |> assign(:patient, patient)
     |> assign(:active_tab, :nurse_notes)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_nurse_notes()}
  end

  defp load_nurse_notes(socket) do
    patient_id = socket.assigns.patient.id
    total_count = NurseNotes.count_nurse_notes_by_patient(patient_id)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    nurse_notes =
      NurseNotes.list_nurse_notes_by_patient_paginated(patient_id, page, socket.assigns.per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:nurse_notes, nurse_notes)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Nurse note")
    |> assign(:nurse_note, NurseNotes.get_nurse_note!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Nurse note")
    |> assign(:nurse_note, %NurseNote{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Nurse notes")
    |> assign(:nurse_note, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    nurse_note = NurseNotes.get_nurse_note!(id)
    {:ok, _} = NurseNotes.delete_nurse_note(nurse_note)

    {:noreply, load_nurse_notes(socket)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_nurse_notes()}
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
          Listing My Nurse Notes for {[
            @patient.first_name,
            @patient.middle_name,
            @patient.last_name
          ]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}
        </div>
        <:actions>
          <.link patch={~p"/nurse/#{@patient.id}/nurse_notes/new"}>
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
                New Note
              </div>
            </.button>
          </.link>
        </:actions>
      </.header>

      <%= if @total_count == 0 do %>
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
          <h3 class="mt-2 text-sm font-medium text-gray-900">No nurse notes</h3>
          <p class="mt-1 text-sm text-gray-500">
            You haven't created any nurse notes yet.
          </p>
        </div>
      <% else %>
        <.table
          id="nurse_notes"
          rows={@nurse_notes}
          row_click={
            fn nurse_note -> JS.navigate(~p"/nurse/nurse_notes/#{nurse_note}/edit") end
          }
          row_id={&"nurse_notes-#{&1.id}"}
        >
          <:col :let={nurse_note} label="Patient">
            <div class="flex items-center py-3">
              <div class="h-8 w-8 rounded-full bg-[#e7e7ff] flex items-center justify-center text-[#373896] font-medium mr-2 text-sm">
                {String.first(nurse_note.patient.first_name || "")}
              </div>
              <span class="font-medium text-gray-900">
                {[
                  nurse_note.patient.first_name,
                  nurse_note.patient.middle_name
                ]
                |> Enum.filter(&(&1 != nil))
                |> Enum.join(" ")}
              </span>
            </div>
          </:col>

          <:col :let={nurse_note} label="Content">
            <div class="max-w-xs py-3">
              <span class="text-gray-700 line-clamp-2">{nurse_note.content}</span>
            </div>
          </:col>

          <:col :let={nurse_note} label="Nurse">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-[#f0f0ff] text-[#373896]">
                {nurse_note.nurse.name}
              </span>
            </div>
          </:col>

          <:action :let={nurse_note}>
            <div class="flex items-center justify-center">
              <.link
                patch={"/nurse/#{@patient.id}/nurse_notes/#{nurse_note.id}/edit"}
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

          <:action :let={nurse_note}>
            <div class="flex items-center justify-center">
              <.link
                phx-click={JS.push("delete", value: %{id: nurse_note.id}) |> hide("#nurse_notes-#{nurse_note.id}")}
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
        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      <% end %>
    </div>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="nurse_note-modal"
      show
      on_cancel={JS.patch(~p"/nurse/#{@patient}/nurse_notes")}
    >
      <.live_component
        module={MedcampWeb.NurseNoteLive.FormComponent}
        id={@nurse_note.id || :new}
        title={@page_title}
        action={@live_action}
        patient={@patient}
        current_user={@current_user}
        nurse_note={@nurse_note}
        patch={~p"/nurse/#{@patient}/nurse_notes"}
      />
    </.modal>
    """
  end
end
