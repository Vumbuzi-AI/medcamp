defmodule MedcampWeb.RoomEquipmentLive.Index do
  use MedcampWeb, :admin_live_view

  alias Medcamp.RoomEquipments
  alias Medcamp.RoomEquipments.RoomEquipment
  alias Medcamp.Rooms

  @per_page 10

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    room = Rooms.get_room!(id)

    {:ok,
     socket
     |> assign(:room, room)
     |> assign(:active_tab, :rooms)
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_room_equipments(id)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"room_equipment_id" => id}) do
    socket
    |> assign(:page_title, "Edit Room equipment")
    |> assign(:room_equipment, RoomEquipments.get_room_equipment!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Room equipment")
    |> assign(:room_equipment, %RoomEquipment{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Room equipments")
    |> assign(:room_equipment, nil)
  end

  @impl true
  def handle_info({MedcampWeb.RoomEquipmentLive.FormComponent, {:saved, _room_equipment}}, socket) do
    {:noreply, load_room_equipments(socket, socket.assigns.room.id)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    room_equipment = RoomEquipments.get_room_equipment!(id)
    {:ok, _} = RoomEquipments.delete_room_equipment(room_equipment)

    {:noreply, load_room_equipments(socket, socket.assigns.room.id)}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_room_equipments(socket.assigns.room.id)}
  end

  defp load_room_equipments(socket, room_id) do
    per_page = socket.assigns.per_page
    page = socket.assigns.page

    total_count = RoomEquipments.count_room_equipments_by_room(room_id)
    total_pages = Medcamp.Pagination.total_pages(total_count, per_page)
    page = min(max(1, page), total_pages)

    room_equipments =
      RoomEquipments.list_room_equipments_by_room_paginated(room_id, page, per_page)

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:room_equipments, room_equipments)
  end
end
