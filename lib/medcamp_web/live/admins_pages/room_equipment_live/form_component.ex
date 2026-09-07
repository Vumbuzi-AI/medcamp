defmodule MedcampWeb.RoomEquipmentLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.RoomEquipments

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage room_equipment records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="room_equipment-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <div>
          <.live_file_input phx-change="validate" upload={@uploads.image} />

          <section phx-drop-target={@uploads.image.ref}>
            <div phx-update="stream" id="upload-entries">
              <article
                :for={entry <- @uploads.image.entries}
                class="upload-entry"
                id={"entry-#{entry.ref}"}
              >
                <figure>
                  <.live_img_preview entry={entry} />
                  <figcaption>{entry.client_name}</figcaption>
                </figure>

                <progress value={entry.progress} max="100">{entry.progress}%</progress>

                <button
                  type="button"
                  phx-click="cancel-upload"
                  phx-value-ref={entry.ref}
                  phx-target={@myself}
                  aria-label="cancel"
                >
                  &times;
                </button>
              </article>
            </div>
          </section>
        </div>
        <:actions>
          <.button phx-disable-with="Saving...">Save Room equipment</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{room_equipment: room_equipment} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:uploaded_files, [])
     |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1)
     |> assign_new(:form, fn ->
       to_form(RoomEquipments.change_room_equipment(room_equipment))
     end)}
  end

  @impl true
  def handle_event("validate", %{"room_equipment" => room_equipment_params}, socket) do
    changeset =
      RoomEquipments.change_room_equipment(socket.assigns.room_equipment, room_equipment_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("validate", _, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"room_equipment" => room_equipment_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
        dest = Path.join(Application.app_dir(:medcamp, "priv/uploads"), Path.basename(path))

        File.cp!(path, dest)
        {:ok, ~p"/uploads/#{Path.basename(dest)}"}
      end)

    image =
      case uploaded_files do
        [] ->
          socket.assigns.room_equipment.image

        [image] ->
          image
      end

    room_equipment_params =
      Map.put(room_equipment_params, "image", image)
      |> Map.put("room_id", socket.assigns.room.id)

    save_room_equipment(socket, socket.assigns.action, room_equipment_params)
  end

  defp save_room_equipment(socket, :edit, room_equipment_params) do
    case RoomEquipments.update_room_equipment(
           socket.assigns.room_equipment,
           room_equipment_params
         ) do
      {:ok, _room_equipment} ->
        {:noreply,
         socket
         |> put_flash(:info, "Room equipment updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_room_equipment(socket, :new, room_equipment_params) do
    case RoomEquipments.create_room_equipment(room_equipment_params) do
      {:ok, _room_equipment} ->
        {:noreply,
         socket
         |> put_flash(:info, "Room equipment created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
