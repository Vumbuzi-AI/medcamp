defmodule MedcampWeb.NursesPages.RoomIndex do
  use MedcampWeb, :nurse_live_view

  alias Medcamp.Rooms
  alias Medcamp.Rooms.Room

  @impl true
  def mount(_params, _session, socket) do
    rooms = Rooms.list_rooms()

    {:ok,
     socket
     |> assign(:active_tab, :rooms)
     |> assign(:rooms_count, length(rooms))
     |> assign(:rooms, rooms)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Room")
    |> assign(:room, Rooms.get_room!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Room")
    |> assign(:room, %Room{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Rooms")
    |> assign(:room, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    room = Rooms.get_room!(id)
    {:ok, _} = Rooms.delete_room(room)

    {:noreply,
     socket
     |> update(:rooms_count, &max(&1 - 1, 0))
     |> assign(:rooms, Enum.reject(socket.assigns.rooms, &(&1.id == room.id)))}
  end

  @impl true

  def render(assigns) do
    ~H"""
    <.header>
      Listing All  Rooms
      <:actions>
        <.link patch="/nurse/rooms/new">
          <.button>New Room</.button>
        </.link>
      </:actions>
    </.header>

    <.blank_state
      :if={@rooms_count == 0}
      icon_path="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
      title="No rooms found"
      description="No rooms have been added yet."
    />

    <.table
      :if={@rooms_count > 0}
      id="rooms"
      rows={@rooms}
      row_click={fn room -> JS.navigate("/nurse/rooms/#{room.id}/edit") end}
      row_id={&"rooms-#{&1.id}"}
    >
      <:col :let={room} label="Room number">{room.room_number}</:col>
      <:col :let={room} label="Desc">{room.description}</:col>
      <:col :let={room} label="Is free?">{room.is_free}</:col>
      <:col :let={room} label="Added By">{room.user.name}</:col>
      <:action :let={room}>
        <.link
          phx-click={JS.push("delete", value: %{id: room.id}) |> hide("#rooms-#{room.id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>

    <.modal
      :if={@live_action in [:new, :edit]}
      id="room-modal"
      show
      on_cancel={JS.patch("/nurse/rooms")}
    >
      <.live_component
        module={MedcampWeb.RoomLive.FormComponent}
        id={@room.id || :new}
        title={@page_title}
        action={@live_action}
        room={@room}
        nurse={@current_user}
        patch="/nurse/rooms"
      />
    </.modal>
    """
  end
end
