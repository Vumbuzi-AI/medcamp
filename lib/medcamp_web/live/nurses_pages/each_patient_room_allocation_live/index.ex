defmodule MedcampWeb.NursesPages.EachPatientRoomAllocationIndex do
  use MedcampWeb, :nurse_each_patient_live_view

  alias Medcamp.RoomAllocations
  alias Medcamp.RoomAllocations.RoomAllocation
  alias Medcamp.Rooms
  alias Medcamp.Patients

  @per_page 10

  @impl true
  def mount(%{"patient_id" => id}, _session, socket) do
    rooms = Rooms.open_rooms_for_selection()
    patients = Patients.list_patients_for_selection()

    {:ok,
     socket
     |> assign(:active_tab, :room_allocations)
     |> assign(:patients, patients)
     |> assign(:rooms, rooms)
     |> assign(:patient, Patients.get_patient!(id))
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_room_allocations()}
  end

  defp load_room_allocations(socket) do
    patient_id = socket.assigns.patient.id
    total_count = RoomAllocations.count_room_allocations_by_patient(patient_id)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    room_allocations =
      RoomAllocations.list_room_allocations_by_patient_paginated(
        patient_id,
        page,
        socket.assigns.per_page
      )

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:room_allocations, room_allocations)
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Room allocation")
    |> assign(:room_allocation, RoomAllocations.get_room_allocation!(id))
  end

  defp apply_action(socket, :trigger_payment, %{"id" => id}) do
    socket
    |> assign(:page_title, "Trigger Room allocation Payment")
    |> assign(:room_allocation, RoomAllocations.get_room_allocation!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Room allocation")
    |> assign(:room_allocation, %RoomAllocation{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Room allocations")
    |> assign(:room_allocation, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    room_allocation = RoomAllocations.get_room_allocation!(id)
    {:ok, _} = RoomAllocations.delete_room_allocation(room_allocation)

    {:noreply, load_room_allocations(socket)}
  end

  def handle_event("discharge_patient", %{"id" => id}, socket) do
    room = Rooms.get_room!(id)
    {:ok, _} = Rooms.update_room(room, %{"is_free" => true})

    {:noreply,
     socket
     |> put_flash(:info, "Patient discharged successfully")
     |> load_room_allocations()}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_room_allocations()}
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
              d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
            />
          </svg>
          Listing Room allocations for {[
            @patient.first_name,
            @patient.middle_name,
            @patient.last_name
          ]
          |> Enum.filter(&(&1 != nil))
          |> Enum.join(" ")}
        </div>
        <:actions>
          <.link patch={~p"/nurse/#{@patient.id}/room_allocations/new"}>
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
                New Room allocation
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
              d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No room allocations</h3>
          <p class="mt-1 text-sm text-gray-500">
            No room allocations have been recorded for this patient yet.
          </p>
        </div>
      <% else %>
        <.table
          id="room_allocations"
          rows={@room_allocations}
          row_click={
            fn room_allocation ->
              JS.navigate(~p"/nurse/#{@patient.id}/room_allocations/#{room_allocation}/edit")
            end
          }
          row_id={&"room_allocations-#{&1.id}"}
        >
          <:col :let={room_allocation} label="Room">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-blue-100 text-blue-800 font-medium">
                Room {room_allocation.room.room_number}
              </span>
            </div>
          </:col>

          <:col :let={room_allocation} label="Patient">
            <div class="flex items-center py-3">
              <div class="h-8 w-8 rounded-full bg-[#e7e7ff] flex items-center justify-center text-[#373896] font-medium mr-2 text-sm">
                {String.first(room_allocation.patient.first_name || "")}
              </div>
              <span class="font-medium text-gray-900">
                {[
                  room_allocation.patient.first_name,
                  room_allocation.patient.middle_name
                ]
                |> Enum.filter(&(&1 != nil))
                |> Enum.join(" ")}
              </span>
            </div>
          </:col>

          <:col :let={room_allocation} label="Nurse">
            <div class="flex items-center py-3">
              <span class="px-2 py-1 text-xs rounded-full bg-[#f0f0ff] text-[#373896]">
                {room_allocation.nurse.name}
              </span>
            </div>
          </:col>

          <:col :let={room_allocation} label="Admission Date">
            <div class="flex items-center py-3">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1 text-[#6667ab]"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                />
              </svg>
              <span class="text-gray-700">{room_allocation.start_date}</span>
            </div>
          </:col>

          <:col :let={room_allocation} label="Discharge Date">
            <div class="flex items-center py-3">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-1 text-[#6667ab]"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                />
              </svg>
              <span class="text-gray-700">{room_allocation.end_date}</span>
            </div>
          </:col>

          <:col :let={room_allocation}>
            <div class="flex items-center justify-center">
              <.button
                :if={room_allocation.room.is_free == false}
                phx-click="discharge_patient"
                phx-value-id={room_allocation.room.id}
                data-confirm="Are you sure?"
                class="bg-red-500 hover:bg-red-600 py-1 px-2 text-xs"
              >
                <div class="flex items-center">
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
                      d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
                    />
                  </svg>
                  Discharge Patient
                </div>
              </.button>
            </div>
          </:col>
        </.table>
        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      <% end %>

      <.modal
        :if={@live_action in [:new, :edit]}
        id="room_allocation-modal"
        show
        on_cancel={JS.patch(~p"/nurse/#{@patient.id}/room_allocations")}
      >
        <.live_component
          module={MedcampWeb.RoomAllocationLive.FormComponent}
          id={@room_allocation.id || :new}
          title={@page_title}
          action={@live_action}
          rooms={@rooms}
          nurse={@current_user}
          selected_patient={@patient}
          patients={@patients}
          room_allocation={@room_allocation}
          patch={~p"/nurse/#{@patient.id}/room_allocations"}
        />
      </.modal>
      <.modal
        :if={@live_action in [:trigger_payment]}
        id="room_allocation-modal"
        show
        on_cancel={JS.patch(~p"/nurse/#{@patient.id}/room_allocations")}
      >
        <.live_component
          module={MedcampWeb.TriggerPayment}
          id={@room_allocation.id || :new}
          title={@page_title}
          action={@live_action}
          action_to_perform="create_room_allocation"
          return_url="/nurse/room_allocations"
          actionable_type={@room_allocation}
          current_user={@current_user}
          patient_id={@room_allocation.patient_id}
          patch={~p"/nurse/#{@patient.id}/room_allocations"}
        />
      </.modal>
    </div>
    """
  end
end
