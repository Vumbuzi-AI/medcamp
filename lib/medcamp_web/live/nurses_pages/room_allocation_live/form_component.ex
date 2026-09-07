defmodule MedcampWeb.RoomAllocationLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.RoomAllocations

  alias Medcamp.Rooms
  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="room_allocation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%= if @selected_patient do %>
          <.input
            field={@form[:patient_id]}
            type="select"
            options={@patients}
            value={@selected_patient.id}
            disabled={true}
            prompt="Select a patient"
            label="Patient"
          />
        <% else %>
          <.input
            field={@form[:patient_id]}
            type="select"
            options={@patients}
            prompt="Select a patient"
            label="Patient"
          />
        <% end %>
        <.input
          field={@form[:room_id]}
          type="select"
          options={@rooms}
          prompt="Select a room"
          label="Room"
        /> <.input field={@form[:start_date]} type="date" label="Admission Date" />
        <.input field={@form[:end_date]} type="date" label="Discharge Date" />

        <:actions>
          <.button phx-disable-with="Saving...">Assign Room To Patient</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{room_allocation: room_allocation} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(RoomAllocations.change_room_allocation(room_allocation))
     end)}
  end

  @impl true
  def handle_event("validate", %{"room_allocation" => room_allocation_params}, socket) do
    changeset =
      RoomAllocations.change_room_allocation(
        socket.assigns.room_allocation,
        room_allocation_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"room_allocation" => room_allocation_params}, socket) do
    room_allocation_params =
      room_allocation_params
      |> Map.put("nurse_id", socket.assigns.nurse.id)
      |> Map.put(
        "patient_id",
        (socket.assigns.selected_patient && socket.assigns.selected_patient.id) ||
          room_allocation_params["patient_id"]
      )

    save_room_allocation(socket, socket.assigns.action, room_allocation_params)
  end

  defp save_room_allocation(socket, :edit, room_allocation_params) do
    case RoomAllocations.update_room_allocation(
           socket.assigns.room_allocation,
           room_allocation_params
         ) do
      {:ok, room_allocation} ->
        room = Rooms.get_room!(room_allocation.room_id)

        {:ok, _} = Rooms.update_room(room, %{"is_free" => false})

        if room_allocation.payment_type == "Insurance" do
          {:ok, _} =
            RoomAllocations.update_room_allocation(room_allocation, %{"has_paid" => true})
        end

        {:noreply,
         socket
         |> put_flash(:info, "Room allocation updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_room_allocation(socket, :new, room_allocation_params) do
    case RoomAllocations.create_room_allocation(room_allocation_params) do
      {:ok, room_allocation} ->
        room = Rooms.get_room!(room_allocation.room_id)

        {:ok, _} = Rooms.update_room(room, %{"is_free" => false})

        {:noreply,
         socket
         |> put_flash(:info, "Room allocation created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
