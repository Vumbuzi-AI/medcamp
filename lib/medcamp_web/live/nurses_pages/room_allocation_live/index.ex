defmodule MedcampWeb.NursesPages.RoomAllocationIndex do
  use MedcampWeb, :nurse_live_view

  alias Medcamp.RoomAllocations
  alias Medcamp.RoomAllocations.RoomAllocation
  alias Medcamp.Rooms
  alias Medcamp.Patients

  @per_page 10

  @impl true
  def mount(_params, _session, socket) do
    rooms = Rooms.open_rooms_for_selection()
    patients = Patients.list_patients_for_selection()

    {:ok,
     socket
     |> assign(:active_tab, :room_allocations)
     |> assign(:patients, patients)
     |> assign(:rooms, rooms)
     |> assign(:search, "")
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_room_allocations()}
  end

  defp load_room_allocations(socket) do
    search = socket.assigns.search
    total_count = RoomAllocations.count_room_allocations(search)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    room_allocations =
      RoomAllocations.list_room_allocations_paginated(search, page, socket.assigns.per_page)

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
  def handle_event("search", %{"search" => query}, socket) do
    {:noreply,
     socket
     |> assign(:search, query)
     |> assign(:page, 1)
     |> load_room_allocations()}
  end

  @impl true
  def handle_event("clear_search", _params, socket) do
    {:noreply,
     socket
     |> assign(:search, "")
     |> assign(:page, 1)
     |> load_room_allocations()}
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
          Listing Room Allocations
        </div>
      </.header>

      <form phx-change="search" class="mb-4">
        <.search_input
          name="search"
          value={@search}
          placeholder="Search by patient name or room number"
        />
      </form>

      <.blank_state
        :if={@total_count == 0}
        icon_path="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4"
        title="No room allocations found"
        description={
          if @search != "",
            do: "No room allocations match \"#{@search}\".",
            else: "No room allocations have been recorded yet."
        }
      >
        <:actions :if={@search != ""}>
          <button phx-click="clear_search" class="text-xs text-[#6667ab] hover:underline">
            Clear filters
          </button>
        </:actions>
      </.blank_state>

      <%= if @total_count > 0 do %>
        <.table
          id="room_allocations"
          rows={@room_allocations}
          row_click={
            fn room_allocation ->
              JS.navigate(~p"/nurse/room_allocations/#{room_allocation}/edit")
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
                  room_allocation.patient.middle_name,
                  room_allocation.patient.last_name
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
              <.link
                navigate={~p"/nurse/room_allocations/#{room_allocation}/edit"}
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
          </:col>
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
      id="room_allocation-modal"
      show
      on_cancel={JS.patch(~p"/nurse/room_allocations")}
    >
      <.live_component
        module={MedcampWeb.RoomAllocationLive.FormComponent}
        id={@room_allocation.id || :new}
        title={@page_title}
        action={@live_action}
        rooms={@rooms}
        selected_patient={nil}
        nurse={@current_user}
        patients={@patients}
        room_allocation={@room_allocation}
        patch={~p"/nurse/room_allocations"}
      />
    </.modal>
    <.modal
      :if={@live_action in [:trigger_payment]}
      id="room_allocation-modal"
      show
      on_cancel={JS.patch(~p"/nurse/room_allocations")}
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
        patch={~p"/nurse/room_allocations"}
      />
    </.modal>
    """
  end
end
