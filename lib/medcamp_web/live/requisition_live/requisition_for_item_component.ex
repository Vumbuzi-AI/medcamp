defmodule MedcampWeb.RequisitionLive.RequisitionForItemComponent do
  @moduledoc """
  Modal form to create a requisition prefilled with a specific item (drug/inventory).
  Used from drug batches listing, nurse allocations, and lab allocations.
  """
  use MedcampWeb, :live_component

  alias Medcamp.Requisitions
  alias Medcamp.Departments
  alias Medcamp.Batches, as: InStore

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-4">
        Make requisition
        <:subtitle>
          Request this item from a department. Fulfillment will use the linked inventory received.
        </:subtitle>
      </.header>
      
    <!-- Stock quantity info -->
      <div :if={@inventory_received_id} class="mb-4 rounded-lg border border-gray-200 bg-gray-50 p-3">
        <div class="flex items-center justify-between">
          <span class="text-sm font-medium text-gray-700">Quantity in stock</span>
          <%= if @quantity_in_stock do %>
            <span class={"text-sm font-bold #{if @insufficient_stock, do: "text-red-600", else: "text-green-600"}"}>
              {@quantity_in_stock} units
            </span>
          <% else %>
            <span class="text-sm text-gray-400">Unknown</span>
          <% end %>
        </div>
        <p :if={@insufficient_stock} class="mt-1 text-xs text-red-600">
          ⚠️ Quantity needed exceeds stock. You can push to admin from the requisition page after saving.
        </p>
      </div>

      <.simple_form
        for={@form}
        id="requisition-for-item-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:title]}
          type="text"
          label="Title"
          required
          disabled={@inventory_received_id != nil}
        />
        <.input
          field={@form[:description]}
          type="textarea"
          label="Description (optional)"
          disabled={@inventory_received_id != nil}
        />
        <.input
          field={@form[:quantity]}
          type="number"
          label="Quantity needed"
          required={@inventory_received_id != nil}
        />
        <.input
          field={@form[:urgency]}
          type="select"
          options={[{"Normal", "normal"}, {"Urgent", "urgent"}, {"Critical", "critical"}]}
          label="Urgency"
          required
        />
        <.input
          field={@form[:to_department_id]}
          type="select"
          options={@departments}
          prompt="Select department to request from"
          label="Request from (department)"
          required
        />
        <.input field={@form[:notes]} type="textarea" label="Notes (optional)" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Requisition</.button>
          <button
            type="button"
            phx-click="cancel"
            phx-target={@myself}
            class="ml-2 px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50"
          >
            Cancel
          </button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    inventory_received_id = assigns[:inventory_received_id]
    general_inventory_item_id = assigns[:general_inventory_item_id]
    item_title = assigns[:item_title] || "Requisition"
    item_description = assigns[:item_description] || ""
    quantity_needed = assigns[:quantity] || nil

    # Default to Pharmacy for nursing requisitions
    pharmacy_dept = Departments.get_department_by_name("Pharmacy")
    default_dept_id = (pharmacy_dept && to_string(pharmacy_dept.id)) || nil

    # Fetch current stock quantity for display
    quantity_in_stock =
      case inventory_received_id && InStore.get_inventory_by_received_id(inventory_received_id) do
        %{quantity_in_stock: qty} -> qty
        _ -> nil
      end

    # Check stock levels (only applicable for inventory_received items)
    insufficient_stock = check_insufficient_stock(inventory_received_id, quantity_needed)

    attrs = %{
      "title" => item_title,
      "description" => item_description,
      "quantity" => quantity_needed,
      "inventory_received_id" => inventory_received_id,
      "general_inventory_item_id" => general_inventory_item_id,
      "urgency" => "normal",
      "to_department_id" => default_dept_id
    }

    requisition = %Medcamp.Requisitions.Requisition{}
    changeset = Requisitions.change_requisition(requisition, attrs)
    departments = Medcamp.Departments.list_departments_for_nursing_requisition()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:inventory_received_id, inventory_received_id)
     |> assign(:general_inventory_item_id, general_inventory_item_id)
     |> assign(:departments, departments)
     |> assign(:insufficient_stock, insufficient_stock)
     |> assign(:quantity_in_stock, quantity_in_stock)
     |> assign(:form, to_form(changeset))}
  end

  defp check_insufficient_stock(nil, _quantity), do: false
  defp check_insufficient_stock(_inventory_id, nil), do: false

  defp check_insufficient_stock(inventory_id, quantity_needed) do
    case InStore.get_inventory_by_received_id(inventory_id) do
      nil -> false
      in_store -> in_store.quantity_in_stock < quantity_needed
    end
  end

  @impl true
  def handle_event("validate", %{"requisition" => params}, socket) do
    # Disabled fields (title, description) are not submitted — preserve them from existing form params
    params = Map.merge(socket.assigns.form.params, params)

    requisition = %Medcamp.Requisitions.Requisition{}

    changeset =
      Requisitions.change_requisition(requisition, params)
      |> Map.put(:action, :validate)

    quantity_needed =
      case params["quantity"] do
        val when val in [nil, ""] -> nil
        val -> String.to_integer(val)
      end

    insufficient_stock =
      check_insufficient_stock(socket.assigns.inventory_received_id, quantity_needed)

    {:noreply,
     socket
     |> assign(form: to_form(changeset))
     |> assign(:insufficient_stock, insufficient_stock)}
  end

  def handle_event("save", %{"requisition" => params}, socket) do
    params =
      socket.assigns.form.params
      |> Map.merge(params)
      |> Map.put("requested_by_id", socket.assigns.current_user.id)
      |> Map.put("inventory_received_id", socket.assigns.inventory_received_id)
      |> Map.put("general_inventory_item_id", socket.assigns.general_inventory_item_id)

    case Requisitions.create_requisition(params) do
      {:ok, requisition} ->
        send(self(), {__MODULE__, {:saved, requisition}})

        {:noreply,
         socket
         |> put_flash(:info, "Requisition created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("cancel", _, socket) do
    {:noreply, push_patch(socket, to: socket.assigns.patch)}
  end
end
