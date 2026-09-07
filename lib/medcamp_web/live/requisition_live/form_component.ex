defmodule MedcampWeb.RequisitionLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Requisitions
  alias Medcamp.Departments
  alias Medcamp.InventoriesReceived

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-6">
        {@title}
        <:subtitle>
          <span class="text-gray-600">
            Create a requisition request to a department.
          </span>
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="requisition-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" required />
        <.input
          field={@form[:description]}
          type="textarea"
          label="Description"
          required={is_nil(@inventory_received)}
        />
        <.input
          field={@form[:quantity]}
          type="number"
          min="1"
          label="Quantity needed"
          required={!is_nil(@inventory_received)}
        />
        <.input
          field={@form[:to_department_id]}
          type="select"
          options={@departments}
          prompt="Select department to request from"
          label="Request from (department)"
          required
        />
        <.input field={@form[:notes]} type="textarea" label="Notes (Optional)" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Requisition</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{requisition: requisition} = assigns, socket) do
    departments = Departments.list_departments_for_selection()

    inventory_received =
      requisition.inventory_received_id &&
        InventoriesReceived.get_inventory_received!(requisition.inventory_received_id)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:departments, departments)
     |> assign(:inventory_received, inventory_received)
     |> assign(:inventory_search, "")
     |> assign(:inventories_for_select, [])
     |> assign_new(:form, fn ->
       to_form(Requisitions.change_requisition(requisition))
     end)}
  end

  @impl true
  def handle_event("validate", %{"requisition" => requisition_params}, socket) do
    requisition_params =
      maybe_put_inventory_received(requisition_params, socket.assigns.inventory_received)

    changeset =
      Requisitions.change_requisition(socket.assigns.requisition, requisition_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("search_inventory_received", %{"inventory_search" => term}, socket) do
    inventories_for_select =
      term
      |> String.trim()
      |> case do
        "" -> []
        search -> InventoriesReceived.search_inventories_received(search) |> Enum.take(10)
      end

    {:noreply,
     socket
     |> assign(:inventory_search, term)
     |> assign(:inventories_for_select, inventories_for_select)}
  end

  def handle_event("select_inventory_received", %{"id" => id}, socket) do
    inventory_received = InventoriesReceived.get_inventory_received!(id)

    params =
      socket.assigns.form.params
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> Map.put("inventory_received_id", to_string(inventory_received.id))

    changeset = Requisitions.change_requisition(socket.assigns.requisition, params)

    {:noreply,
     socket
     |> assign(:inventory_received, inventory_received)
     |> assign(:inventory_search, "")
     |> assign(:inventories_for_select, [])
     |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("remove_inventory_received", _params, socket) do
    params =
      socket.assigns.form.params
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> Map.put("inventory_received_id", nil)

    changeset = Requisitions.change_requisition(socket.assigns.requisition, params)

    {:noreply,
     socket
     |> assign(:inventory_received, nil)
     |> assign(:inventory_search, "")
     |> assign(:inventories_for_select, [])
     |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"requisition" => requisition_params}, socket) do
    requisition_params =
      requisition_params
      |> Map.put("requested_by_id", socket.assigns.current_user.id)
      |> maybe_put_inventory_received(socket.assigns.inventory_received)

    save_requisition(socket, socket.assigns.action, requisition_params)
  end

  defp maybe_put_inventory_received(params, nil),
    do: Map.put(params, "inventory_received_id", nil)

  defp maybe_put_inventory_received(params, inventory_received) do
    Map.put(params, "inventory_received_id", inventory_received.id)
  end

  defp save_requisition(socket, :edit, requisition_params) do
    case Requisitions.update_requisition(socket.assigns.requisition, requisition_params) do
      {:ok, requisition} ->
        notify_parent({:saved, requisition})

        {:noreply,
         socket
         |> put_flash(:info, "Requisition updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_requisition(socket, :new, requisition_params) do
    case Requisitions.create_requisition(requisition_params) do
      {:ok, requisition} ->
        notify_parent({:saved, requisition})

        {:noreply,
         socket
         |> put_flash(:info, "Requisition created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
