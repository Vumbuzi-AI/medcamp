defmodule MedcampWeb.AdminPages.RoomIndex do
  use MedcampWeb, :admin_live_view

  alias Medcamp.Rooms
  alias Medcamp.Rooms.Room

  @per_page 10

  @default_filters %{search: "", date_from: nil, date_to: nil, type: ""}

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :rooms)
     |> assign(:filters, @default_filters)
     |> assign(:room_types, Rooms.list_room_types_for_selection())
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_rooms()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  # The search box and the filter drawer submit independently (two separate
  # <form>s), so a submission from either one only carries its own fields.
  # Merging onto a stringified version of the current filters means a key
  # absent from this submission is left unchanged rather than reset.
  defp stringify_filters(filters), do: Map.new(filters, fn {k, v} -> {Atom.to_string(k), v} end)

  defp count_active_filters(filters) do
    filters
    |> Map.drop([:search])
    |> Map.values()
    |> Enum.count(&(&1 not in [nil, ""]))
  end

  defp filter_chips(filters) do
    [
      filter_chip(filters.type, "type", filters.type),
      filter_chip(filters.date_from, "date_from", "From #{filters.date_from}"),
      filter_chip(filters.date_to, "date_to", "To #{filters.date_to}")
    ]
    |> Enum.reject(&is_nil/1)
  end

  @impl true
  def handle_event("apply_filters", %{"filters" => filters}, socket) do
    filters = Map.merge(stringify_filters(socket.assigns.filters), filters)

    filters = %{
      search: filters["search"] || "",
      date_from: filters["date_from"] || nil,
      date_to: filters["date_to"] || nil,
      type: filters["type"] || ""
    }

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:page, 1)
     |> load_rooms()}
  end

  @impl true
  def handle_event("clear_filters", _params, socket) do
    {:noreply,
     socket
     |> assign(:filters, @default_filters)
     |> assign(:page, 1)
     |> load_rooms()}
  end

  @impl true
  def handle_event("clear_chip", %{"field" => field}, socket) do
    handle_event("apply_filters", %{"filters" => %{field => ""}}, socket)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    room = Rooms.get_room!(id)
    {:ok, _} = Rooms.delete_room(room)

    {:noreply, load_rooms(socket)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, socket |> assign(:page, max(1, String.to_integer(page))) |> load_rooms()}
  end

  def handle_event("update-content", %{"content" => content}, socket) do
    room = socket.assigns.room
    changeset = Rooms.change_room(room, %{description: content})

    {
      :noreply,
      socket
      |> assign(:room, room)
      |> assign(:form, to_form(changeset))
    }
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Room")
    |> assign(:room, Rooms.get_room!(id))
  end

  defp apply_action(socket, :room_gln, %{"id" => id}) do
    IO.inspect(id, label: "ID in room_gln")

    socket
    |> assign(:page_title, "Room GLN")
    |> assign(:room, Rooms.get_room!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Room")
    |> assign(:room, %Room{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Rooms")
    |> assign(:room, nil)
  end

  @impl true

  def render(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4 mb-6">
      <.page_header
        icon_path="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"
        title="Rooms"
        subtitle="Search, filter and manage rooms."
      >
        <:actions>
          <.link patch={~p"/admin/rooms/new"}>
            <.button>New Room</.button>
          </.link>
        </:actions>
      </.page_header>

      <div class="flex flex-wrap items-center gap-3">
        <form phx-change="apply_filters" class="flex-1">
          <.search_input
            name="filters[search]"
            value={@filters.search}
            placeholder="Search by room name or room number"
          />
        </form>

        <.filter_drawer
          id="rooms-filters"
          title="Filter rooms"
          apply_event="apply_filters"
          active_count={count_active_filters(@filters)}
        >
          <:group label="Room Details">
            <div>
              <label class="block text-xs font-medium text-gray-600 mb-1">Type</label>
              <select
                name="filters[type]"
                class="w-full h-9 rounded-md border border-gray-300 px-2 text-sm focus:ring-[#6667ab] focus:border-[#6667ab]"
              >
                <option value="" selected={@filters.type == ""}>All</option>
                <option :for={type <- @room_types} value={type} selected={@filters.type == type}>
                  {type}
                </option>
              </select>
            </div>
          </:group>

          <:group label="Date Range">
            <.date_range_fields
              from_name="filters[date_from]"
              to_name="filters[date_to]"
              from_value={@filters.date_from || ""}
              to_value={@filters.date_to || ""}
            />
          </:group>

          <:chip
            :for={chip <- filter_chips(@filters)}
            label={chip.label}
            clear={JS.push("clear_chip", value: %{"field" => chip.field})}
          />
        </.filter_drawer>
      </div>
    </div>

    <.blank_state
      :if={@total_count == 0}
      icon_path="M2.25 12l8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75M8.25 21h8.25"
      title="No rooms found"
      description={
        if @filters.search != "" or count_active_filters(@filters) > 0,
          do: "No rooms match the current filters.",
          else: "No rooms have been added yet."
      }
    >
      <:actions :if={@filters.search != "" or count_active_filters(@filters) > 0}>
        <button phx-click="clear_filters" class="text-xs text-[#6667ab] hover:underline">
          Clear filters
        </button>
      </:actions>
    </.blank_state>

    <.table
      :if={@total_count > 0}
      id="rooms"
      rows={@rooms}
      row_click={fn room -> JS.navigate(~p"/admin/rooms/#{room}/edit") end}
      row_id={&"rooms-#{&1.id}"}
    >
      <:col :let={room} label="GLN">
        {room.room_number}

        <.link patch={"/admin/rooms/#{room.id}/room_gln"}>
          <.button>
            Room GLN
          </.button>
        </.link>
      </:col>
      <:col :let={room} label="Room Name">{room.name}</:col>
      <:col :let={room} label="Type">{room.type}</:col>
      <:col :let={room} label="Desc">
        {room.description
        |> Phoenix.HTML.raw()}
      </:col>
      <:col :let={room} label="Data Collected">{room.data_collected}</:col>
      <:col :let={room} label="Image">
        <img
          :if={room.image}
          src={room.image}
          alt="Room Image"
          class="w-16 h-16 object-cover rounded"
        />
      </:col>
      <:col :let={room} label="Added By">{room.user.name}</:col>
      <:action :let={room}>
        <.link patch={~p"/admin/rooms/#{room.id}/edit"}>
          View / Edit
        </.link>
      </:action>
      <:action :let={room}>
        <.link patch={~p"/admin/rooms/#{room.id}/room_equipments"}>
          Equipment
        </.link>
      </:action>
      <:action :let={room}>
        <.link
          phx-click={JS.push("delete", value: %{id: room.id}) |> hide("#rooms-#{room.id}")}
          data-confirm="Are you sure?"
        >
          Delete
        </.link>
      </:action>
    </.table>
    <.pagination
      page={@page}
      total_pages={@total_pages}
      total_count={@total_count}
      per_page={@per_page}
    />

    <.modal
      :if={@live_action in [:new, :edit]}
      id="room-modal"
      show
      on_cancel={JS.patch("/admin/rooms")}
    >
      <.live_component
        module={MedcampWeb.AdminRoomLive.FormComponent}
        id={@room.id || :new}
        title={@page_title}
        action={@live_action}
        room={@room}
        admin={@current_user}
        patch="/admin/rooms"
      />
    </.modal>

    <.modal
      :if={@live_action in [:room_gln]}
      id="room-modal"
      show
      on_cancel={JS.patch("/admin/rooms")}
    >
      <.live_component
        module={MedcampWeb.AdminRoomLive.RoomGln}
        id={@room.id || :new}
        title={@page_title}
        action={@live_action}
        room={@room}
        admin={@current_user}
        patch="/admin/rooms"
      />
    </.modal>
    """
  end

  defp load_rooms(socket) do
    filters = socket.assigns.filters
    per_page = socket.assigns.per_page
    page = socket.assigns.page

    total_count = Rooms.count_rooms(filters)
    total_pages = Medcamp.Pagination.total_pages(total_count, per_page)
    page = min(max(1, page), total_pages)
    rooms = Rooms.filter_rooms_paginated(filters, page, per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:rooms, rooms)
  end
end
