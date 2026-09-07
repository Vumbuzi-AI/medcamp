defmodule MedcampWeb.AdminRoomLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Rooms

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.simple_form for={@form} id="room-form" phx-target={@myself} phx-submit="save">
        <.input field={@form[:room_number]} type="text" label="GLN Number" />
        <.input field={@form[:name]} type="text" label="Name" placeholder="Room name" />
        <.input
          field={@form[:type]}
          type="select"
          label="Room Type"
          prompt="Select room type"
          options={[
            "Ward",
            "Consultation Room",
            "Laboratory",
            "Pharmacy",
            "Waiting Area",
            "Office"
          ]}
        />

        <.input
          field={@form[:data_collected]}
          type="textarea"
          label="Data Collected"
          placeholder="Describe the data collected in this room"
        />

        <.input field={@form[:is_free]} type="checkbox" label="Is free" />
        
    <!-- CKEditor Field -->
        <div class="space-y-2">
          <.label for={@form[:description].id}>
            Description
          </.label>

          <div phx-update="ignore" id={"#{@form[:description].id}-container"}>
            <textarea
              id={@form[:description].id}
              name={@form[:description].name}
              phx-hook="CKEditor"
              class="hidden"
              phx-debounce="300"
            ><%= Phoenix.HTML.Form.normalize_value("textarea", @form[:description].value) %></textarea>
          </div>

          <.error :for={msg <- @form[:description].errors}>
            {msg}
          </.error>
        </div>
        
    <!-- File Upload Section - Keep static -->
        <div>
          <.live_file_input phx-change="validate" upload={@uploads.image} />
          
    <!-- Only the preview section updates -->
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
          <.button phx-disable-with="Saving...">Save Room</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{room: room} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:uploaded_files, [])
     |> allow_upload(:image, accept: ~w(.jpg .jpeg .png), max_entries: 1)
     |> assign_new(:form, fn ->
       to_form(Rooms.change_room(room))
     end)}
  end

  @impl true
  def handle_event("validate", %{"room" => room_params}, socket) do
    changeset =
      socket.assigns.room
      |> Rooms.change_room(room_params)
      |> Map.put(:action, :validate)

    # Don't update the form if only handling file uploads
    socket =
      if Map.has_key?(room_params, "_target") do
        socket
      else
        assign(socket, form: to_form(changeset))
      end

    {:noreply, socket}
  end

  # Handle file upload validation separately
  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"room" => room_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :image, fn %{path: path}, _entry ->
        dest = Path.join(Application.app_dir(:medcamp, "priv/uploads"), Path.basename(path))

        File.cp!(path, dest)
        {:ok, ~p"/uploads/#{Path.basename(dest)}"}
      end)

    IO.inspect(uploaded_files, label: "Uploaded Files")

    image =
      case uploaded_files do
        [] ->
          socket.assigns.room.image

        [image] ->
          image
      end

    room_params =
      room_params
      |> Map.put("added_by", socket.assigns.admin.id)
      |> Map.put("image", image)

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
