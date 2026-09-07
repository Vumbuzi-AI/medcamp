defmodule MedcampWeb.GeneralInventoryItemLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Inventories
  alias Medcamp.Rooms

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-6">
        {@title}
        <:subtitle>
          <span class="text-gray-600">
            Manage your general inventory items like consumables and supplies.
          </span>
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="general_inventory_item-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-6">
          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-sm font-semibold text-[#373896] mb-4 flex items-center">
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
                  d="M3 7h2a2 2 0 012 2v10a2 2 0 01-2 2H3V7zm18 0h-2a2 2 0 00-2 2v10a2 2 0 002 2h2V7zM7 7h10a2 2 0 012 2v10a2 2 0 01-2 2H7V7z"
                />
              </svg>
              Scan GTIN
            </h3>
            <div class="grid grid-cols-1  gap-4">
              <.input
                field={@form[:gtin]}
                type="text"
                label="Global Trade Item Number (GTIN)"
                placeholder="e.g., 0123456789012"
              />
            </div>
          </div>
          <!-- Basic Information Section -->
          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-sm font-semibold text-[#373896] mb-4 flex items-center">
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
                  d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              Basic Information
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <.input
                field={@form[:name]}
                type="text"
                label="Item Name"
                placeholder="e.g., Sugar, Milk, Coffee"
                required
              />
              <.input
                field={@form[:category]}
                type="select"
                label="Category"
                options={[
                  {"Food & Beverages", "Food & Beverages"},
                  {"Cleaning Supplies", "Cleaning Supplies"},
                  {"Office Supplies", "Office Supplies"},
                  {"Medical Consumables", "Medical Consumables"},
                  {"Other", "Other"}
                ]}
                prompt="Select a category"
                required
              />
            </div>
          </div>
          
    <!-- Stock Information Section -->
          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-sm font-semibold text-[#373896] mb-4 flex items-center">
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
                  d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"
                />
              </svg>
              Stock Information
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <.input
                field={@form[:unit_of_measure]}
                type="select"
                label="Unit of Measure"
                options={[
                  {"Kilograms (kg)", "kg"},
                  {"Grams (g)", "g"},
                  {"Liters (L)", "L"},
                  {"Milliliters (mL)", "mL"},
                  {"Pieces (pcs)", "pcs"},
                  {"Boxes", "boxes"},
                  {"Packets", "packets"},
                  {"Bottles", "bottles"}
                ]}
                prompt="Select unit"
                required
              />
              <.input
                field={@form[:current_quantity]}
                type="number"
                label="Current Quantity"
                step="0.01"
                min="0"
                placeholder="0.00"
                required
              />
              <.input
                field={@form[:reorder_level]}
                type="number"
                label="Reorder Level"
                step="0.01"
                min="0"
                placeholder="Minimum stock level"
                required
              />
            </div>
            <p class="text-xs text-gray-500 mt-2">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-3 w-3 inline mr-1"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              You'll receive alerts when stock falls below the reorder level
            </p>
          </div>
          
    <!-- Supplier & Cost Section -->
          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-sm font-semibold text-[#373896] mb-4 flex items-center">
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
                  d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"
                />
              </svg>
              Supplier & Pricing
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <.input
                field={@form[:supplier]}
                type="text"
                label="Supplied By"
                placeholder="e.g., ABC Suppliers Ltd"
              />

              <.input
                field={@form[:manufacturer]}
                type="text"
                label="Manufacturer"
                placeholder="e.g., XYZ Manufacturing Co."
              />
            </div>

            <.input
              field={@form[:unit_cost]}
              type="number"
              label="Unit Cost (KES)"
              step="0.01"
              min="0"
              placeholder="0.00"
              required
            />
          </div>
          
    <!-- Supplier & Cost Section -->

          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-sm font-semibold text-[#373896] mb-4 flex items-center">
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
                  d="M8 7V3m8 4V3m-9
    8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                />
              </svg>
              Date Received
            </h3>
            <div class="grid grid-cols-1  gap-4">
              <.input field={@form[:date_received]} type="date" label="Date Received" />
            </div>
          </div>
          <!-- Notes Section -->
          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-sm font-semibold text-[#373896] mb-4 flex items-center">
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
                  d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                />
              </svg>
              Additional Notes
            </h3>
            <.input
              field={@form[:notes]}
              type="textarea"
              label="Notes"
              placeholder="Any additional information about this item..."
              rows="3"
            />
          </div>
        </div>

        <:actions>
          <div class="flex items-center justify-end gap-4 pt-4 border-t border-gray-200">
            <.button
              type="button"
              phx-click={JS.patch(@patch)}
              class="bg-gray-200 hover:bg-gray-300 text-gray-700"
            >
              Cancel
            </.button>
            <.button phx-disable-with="Saving..." class="bg-[#6667ab] hover:bg-[#5556a0]">
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
                    d="M5 13l4 4L19 7"
                  />
                </svg>
                Save Item
              </div>
            </.button>
          </div>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{general_inventory_item: general_inventory_item} = assigns, socket) do
    rooms = Rooms.list_rooms()
    room_options = Enum.map(rooms, fn room -> {room.name, room.id} end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:room_options, room_options)
     |> assign_new(:form, fn ->
       to_form(Inventories.change_general_inventory_item(general_inventory_item))
     end)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"general_inventory_item" => general_inventory_item_params},
        socket
      ) do
    changeset =
      Inventories.change_general_inventory_item(
        socket.assigns.general_inventory_item,
        general_inventory_item_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"general_inventory_item" => general_inventory_item_params}, socket) do
    case Medcamp.Gtin.validate(general_inventory_item_params["gtin"]) do
      {:ok, body} ->
        general_inventory_item_params = Map.put(general_inventory_item_params, "gtin", body)

        save_general_inventory_item(socket, socket.assigns.action, general_inventory_item_params)

      _ ->
        case Medcamp.CreateGtin.create(
               general_inventory_item_params["name"],
               general_inventory_item_params["category"],
               general_inventory_item_params["unit_of_measure"]
             ) do
          {:ok, response} ->
            response = Jason.decode!(response.body)

            general_inventory_item_params =
              general_inventory_item_params
              |> Map.put("gtin", response["gtin"])

            save_general_inventory_item(
              socket,
              socket.assigns.action,
              general_inventory_item_params
            )

          {:error, _reason} ->
            {:noreply,
             socket
             |> put_flash(:error, "Failed to create GTIN. Please try again.")
             |> assign(form: to_form(socket.assigns.form))}
        end
    end
  end

  defp save_general_inventory_item(socket, :edit, general_inventory_item_params) do
    case Inventories.update_general_inventory_item(
           socket.assigns.general_inventory_item,
           general_inventory_item_params
         ) do
      {:ok, general_inventory_item} ->
        notify_parent({:saved, general_inventory_item})

        {:noreply,
         socket
         |> put_flash(:info, "General inventory item updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_general_inventory_item(socket, :new, general_inventory_item_params) do
    case Inventories.create_general_inventory_item(general_inventory_item_params) do
      {:ok, general_inventory_item} ->
        notify_parent({:saved, general_inventory_item})

        {:noreply,
         socket
         |> put_flash(:info, "General inventory item created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
