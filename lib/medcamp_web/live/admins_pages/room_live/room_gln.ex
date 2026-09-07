defmodule MedcampWeb.AdminRoomLive.RoomGln do
  use MedcampWeb, :live_component

  alias Medcamp.Rooms

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <input
        type="text"
        id="text"
        value={"https://glocalhealthcentre.org/414/#{@room.room_number}"}
        style="display:none;"
      />

      <div class="flex flex-col gap-1">
        <div class="flex gap-0 font-bold items-center">
          GS1 <span>&#174; </span>
        </div>
        <div class="flex flex-col gap-1">
          <div class="w-[100px] h-[100px]">
            <div phx-hook="CardQrCode" phx-update="ignore" id="qrcode" class="rounded-md  " />
          </div>
        </div>
        <p class="font-bold text-xl">
          (414) {@room.room_number}
        </p>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{room: room} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Rooms.change_room(room))
     end)}
  end

  @impl true
  def handle_event("validate", %{"room" => room_params}, socket) do
    changeset = Rooms.change_room(socket.assigns.room, room_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"room" => room_params}, socket) do
    room_params =
      room_params
      |> Map.put("added_by", socket.assigns.admin.id)

    save_room(socket, socket.assigns.action, room_params)
  end

  defp save_room(socket, :edit, room_params) do
    case Rooms.update_room(socket.assigns.room, room_params) do
      {:ok, _room} ->
        {:noreply,
         socket
         |> put_flash(:info, "Room updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_room(socket, :new, room_params) do
    case Rooms.create_room(room_params) do
      {:ok, _room} ->
        {:noreply,
         socket
         |> put_flash(:info, "Room created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
