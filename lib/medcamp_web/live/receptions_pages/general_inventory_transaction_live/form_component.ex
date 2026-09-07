defmodule MedcampWeb.GeneralInventoryTransactionLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Inventories

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-6">
        {@title}
        <:subtitle>
          <span class="text-gray-600">
            Record inventory movement for
            <span class="font-semibold">{@general_inventory_item.name}</span>
          </span>
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="general_inventory_transaction-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-6">
          <!-- Current Stock Info Banner -->
          <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <div class="flex items-start">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5 text-blue-600 mt-0.5 mr-3"
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
              <div>
                <h4 class="text-sm font-semibold text-blue-900">Current Stock Level</h4>
                <p class="text-sm text-blue-700 mt-1">
                  <span class="font-bold text-lg">
                    {Decimal.to_string(@general_inventory_item.current_quantity)}
                  </span>
                  {@general_inventory_item.unit_of_measure} available
                </p>
              </div>
            </div>
          </div>
          
    <!-- Transaction Type Section -->
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
                  d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"
                />
              </svg>
              Transaction Details
            </h3>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <.input
                field={@form[:transaction_type]}
                type="select"
                label="Transaction Type"
                options={[
                  {"Items Received/Purchased", "received"},
                  {"Items Used/Consumed", "used"},
                  {"Items Destroyed/Expired", "destroyed"},
                  {"Stock Adjustment", "adjustment"}
                ]}
                prompt="Select transaction type"
                required
              />

              <.input
                field={@form[:transaction_date]}
                type="date"
                label="Transaction Date"
                value={Date.utc_today()}
                max={Date.utc_today()}
                required
              />
            </div>
          </div>
          
    <!-- Quantity Section -->
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
                  d="M7 12l3-3 3 3 4-4M8 21l4-4 4 4M3 4h18M4 4h16v12a1 1 0 01-1 1H5a1 1 0 01-1-1V4z"
                />
              </svg>
              Quantity
            </h3>

            <.input
              field={@form[:quantity]}
              type="number"
              label={"Quantity (#{@general_inventory_item.unit_of_measure})"}
              step="0.01"
              min="0.01"
              placeholder="Enter quantity"
              required
            />

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
              Stock will be automatically updated based on transaction type
            </p>
          </div>
          
    <!-- Reason Section -->
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
                  d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              Reason & Notes
            </h3>

            <.input
              field={@form[:reason]}
              type="text"
              label="Reason"
              placeholder="e.g., Daily consumption, Restocking, Expired batch, etc."
              required
            />

            <.input
              field={@form[:notes]}
              type="textarea"
              label="Additional Notes"
              placeholder="Any additional information about this transaction..."
              rows="3"
            />
          </div>
          
    <!-- Recorded By Section -->
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
                  d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
                />
              </svg>
              Recorded By
            </h3>

            <.input
              field={@form[:recorded_by]}
              type="text"
              label="Your Name"
              value={(@current_user && @current_user.email) || ""}
              placeholder="Enter your name"
              required
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
                Record Transaction
              </div>
            </.button>
          </div>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{general_inventory_transaction: general_inventory_transaction} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Inventories.change_general_inventory_transaction(general_inventory_transaction))
     end)}
  end

  @impl true
  def handle_event(
        "validate",
        %{"general_inventory_transaction" => general_inventory_transaction_params},
        socket
      ) do
    changeset =
      Inventories.change_general_inventory_transaction(
        socket.assigns.general_inventory_transaction,
        general_inventory_transaction_params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event(
        "save",
        %{"general_inventory_transaction" => general_inventory_transaction_params},
        socket
      ) do
    save_general_inventory_transaction(
      socket,
      socket.assigns.action,
      general_inventory_transaction_params
    )
  end

  defp save_general_inventory_transaction(
         socket,
         :edit_transaction,
         general_inventory_transaction_params
       ) do
    case Inventories.update_general_inventory_transaction(
           socket.assigns.general_inventory_transaction,
           general_inventory_transaction_params
         ) do
      {:ok, general_inventory_transaction} ->
        notify_parent({:saved, general_inventory_transaction})

        {:noreply,
         socket
         |> put_flash(:info, "Transaction updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_general_inventory_transaction(
         socket,
         :new_transaction,
         general_inventory_transaction_params
       ) do
    # Add the general_inventory_item_id and user_id to params
    params =
      general_inventory_transaction_params
      |> Map.put("general_inventory_item_id", socket.assigns.general_inventory_item.id)
      |> Map.put("user_id", socket.assigns.current_user && socket.assigns.current_user.id)

    case Inventories.create_general_inventory_transaction(params) do
      {:ok, general_inventory_transaction} ->
        notify_parent({:saved, general_inventory_transaction})

        {:noreply,
         socket
         |> put_flash(:info, "Transaction recorded successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
