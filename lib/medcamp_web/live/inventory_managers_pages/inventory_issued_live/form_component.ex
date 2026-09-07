defmodule MedcampWeb.InventoryIssuedLive.FormComponent do
  alias Medcamp.InventoriesReceived
  use MedcampWeb, :live_component

  alias Medcamp.InventoriesIssues
  alias Medcamp.InventoriesReceived
  alias Medcamp.Batches
  alias Medcamp.Batches.Batch
  alias Medcamp.Drugs
  alias Medcamp.Accounts
  alias Medcamp.DrugBatches
  alias Medcamp.Repo

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <div :if={@prefill_requisition} class="mb-4 rounded-lg border border-blue-100 bg-blue-50 p-3">
        <p class="text-sm font-medium text-blue-900">Requisition context</p>
        <p class="text-sm text-blue-700">
          Requested by: <span class="font-semibold">{@prefill_requisition.requested_by.name}</span>
          <%= if @prefill_requisition.requested_by.department do %>
            · Department:
            <span class="font-semibold">{@prefill_requisition.requested_by.department.name}</span>
          <% end %>
        </p>
      </div>

      <div :if={@inventory_received != nil} class="text-sm text-gray-500">
        <span class="font-semibold">Inventory received:</span>
        <div class="flex gap-2 text-lg bg-gray-100 p-2 rounded-lg items-center justify-between">
          <div class="flex items-center gap-2">
            <span class="text-gray-700">{@inventory_received.brand_name}</span>
            <span class=" text-gray-500">{@inventory_received.generic_name}</span>
          </div>
          <i
            class="fa fa-times text-red-500 cursor-pointer"
            phx-click="remove_inventory_received"
            phx-target={@myself}
          >
          </i>
        </div>
      </div>
      <div :if={@inventory_received == nil}>
        <form phx-change="search_inventory_received" phx-target={@myself}>
          <input
            type="text"
            class="mt-2 block w-full rounded-lg text-zinc-900 focus:ring-0 sm:text-sm sm:leading-6"
            label="Inventory received"
            name="search"
            placeholder="Search for inventory received by GTIN, Batch, or Supplier"
          />
        </form>
        <div
          :if={@inventories_for_select != []}
          class="flex flex-col gap-1 bg-gray-100 h-[200px] overflow-y-scroll divider-y"
        >
          <%= for inventory <- @inventories_for_select do %>
            <div
              phx-click="select_inventory_received"
              phx-value-id={inventory.id}
              phx-target={@myself}
              class="flex items-center p-2 hover:bg-gray-200 cursor-pointer border-b-[1px] justify-between py-2"
            >
              <span class="text-sm text-gray-700">{inventory.brand_name}</span>
              <span class="text-xs text-gray-500">{inventory.generic_name}</span>
            </div>
          <% end %>
        </div>
      </div>
      <.simple_form
        for={@form}
        id="inventory_issued-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%!--
        <.input
          field={@form[:inventory_received_id]}
          type="select"
          label="Inventory received"
          options={@inventories_for_select}
          required={true}
          prompt="Select an inventory received"
        /> --%>
        <div :if={@batches_with_expiry != []} class="space-y-2">
          <p class="text-sm font-semibold text-gray-700">
            Batch <span class="text-gray-500 font-normal">(first expiry, first out)</span>
          </p>
          <input type="hidden" name="inventory_issued[batch_id]" value={@form[:batch_id].value} />
          <div class="border border-gray-200 rounded-lg divide-y max-h-48 overflow-y-auto">
            <%= for b <- @batches_with_expiry do %>
              <div
                phx-click="select_batch"
                phx-value-id={b.id}
                phx-target={@myself}
                class={"flex items-center justify-between px-3 py-2.5 cursor-pointer hover:bg-gray-50 " <> (if @selected_batch_id == b.id, do: "bg-[#f0f0ff] border-l-4 border-[#373896]", else: "")}
              >
                <span class="font-medium text-gray-900">{b.batch}</span>
                <span class="text-sm text-gray-600">
                  {if b.expiry && b.expiry != "", do: b.expiry, else: "N/A"}
                </span>
              </div>
            <% end %>
          </div>
        </div>

        <div
          :if={@selected_batch_remaining != nil}
          class="rounded-lg bg-blue-50 border border-blue-200 px-3 py-2 text-sm"
        >
          <span class="font-medium text-blue-900">Remaining in selected batch:</span>
          <span class="ml-2 font-semibold text-blue-700">{@selected_batch_remaining}</span>
        </div>

        <.input
          :if={@inventory_received != nil}
          value={@inventory_received && @inventory_received.gtin}
          field={@form[:gtin]}
          type="text"
          label="GTIN"
          required
        />

        <.input
          :if={@batches_with_expiry != []}
          field={@form[:quantity]}
          type="number"
          label="Quantity"
        />

        <.input
          field={@form[:location]}
          type="select"
          options={[
            "Pharmacy",
            "Store",
            "Warehouse",
            "Laboratory",
            "Nurse",
            "Clinical Office",
            "Kitchen"
          ]}
          prompt="Select a location"
          label="Location"
        />

        <.input
          field={@form[:assigned_to_id]}
          type="select"
          label="Assigned to"
          prompt="Select a user"
          options={@users_for_select}
        />

        <:actions>
          <.button phx-disable-with="Saving...">Save Inventory issued</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{inventory_issued: inventory_issued} = assigns, socket) do
    batches_with_expiry =
      if inventory_issued.inventory_received_id do
        Batches.list_batches_with_expiry_for_inventory_received(
          inventory_issued.inventory_received_id
        )
      else
        []
      end

    users_for_select =
      Accounts.list_users_for_selection()

    {selected_batch_remaining, selected_batch_id} =
      if inventory_issued.batch_id do
        case Repo.get(Batch, inventory_issued.batch_id) do
          nil -> {nil, nil}
          batch -> {batch.remaining_quantity, batch.id}
        end
      else
        {nil, nil}
      end

    inventory_received =
      if inventory_issued.inventory_received_id do
        InventoriesReceived.get_inventory_received!(inventory_issued.inventory_received_id)
      else
        nil
      end

    {:ok,
     socket
     |> assign(assigns)
     |> assign(users_for_select: users_for_select)
     |> assign(inventories_for_select: [])
     |> assign(:inventory_received, inventory_received)
     |> assign(batches_with_expiry: batches_with_expiry)
     |> assign(:selected_batch_id, selected_batch_id)
     |> assign(:selected_batch_remaining, selected_batch_remaining)
     |> assign(:prefill_requisition, assigns[:prefill_requisition])
     |> assign(:drug_batch_id, assigns[:drug_batch_id])
     |> assign_new(:form, fn ->
       to_form(InventoriesIssues.change_inventory_issued(inventory_issued))
     end)}
  end

  @impl true
  def handle_event("select_batch", %{"id" => id}, socket) do
    batch_id = String.to_integer(id)
    current_params = socket.assigns.form.params |> Map.put("batch_id", id)

    changeset =
      InventoriesIssues.change_inventory_issued(
        socket.assigns.inventory_issued,
        current_params
      )

    selected_batch_remaining =
      case Repo.get(Batch, batch_id) do
        nil -> nil
        batch -> batch.remaining_quantity
      end

    {:noreply,
     socket
     |> assign(form: to_form(changeset, action: :validate))
     |> assign(:selected_batch_id, batch_id)
     |> assign(:selected_batch_remaining, selected_batch_remaining)}
  end

  def handle_event("validate", %{"inventory_issued" => inventory_issued_params}, socket) do
    changeset =
      InventoriesIssues.change_inventory_issued(
        socket.assigns.inventory_issued,
        inventory_issued_params
      )

    {selected_batch_remaining, selected_batch_id} =
      case inventory_issued_params["batch_id"] do
        "" ->
          {nil, nil}

        nil ->
          {nil, nil}

        id when is_binary(id) ->
          case Integer.parse(id) do
            {batch_id, _} ->
              case Repo.get(Batch, batch_id) do
                nil -> {nil, nil}
                batch -> {batch.remaining_quantity, batch_id}
              end

            _ ->
              {nil, nil}
          end

        _ ->
          {nil, nil}
      end

    {:noreply,
     socket
     |> assign(form: to_form(changeset, action: :validate))
     |> assign(:selected_batch_remaining, selected_batch_remaining)
     |> assign(:selected_batch_id, selected_batch_id)}
  end

  def handle_event("select_inventory_received", %{"id" => id}, socket) do
    inventory_received = InventoriesReceived.get_inventory_received!(id)

    batches_with_expiry =
      Batches.list_batches_with_expiry_for_inventory_received(inventory_received.id)

    {:noreply,
     socket
     |> assign(:inventory_received, inventory_received)
     |> assign(batches_with_expiry: batches_with_expiry)
     |> assign(:selected_batch_id, nil)
     |> assign(:selected_batch_remaining, nil)}
  end

  def handle_event("remove_inventory_received", _params, socket) do
    {:noreply,
     socket
     |> assign(:inventory_received, nil)
     |> assign(batches_with_expiry: [])
     |> assign(inventories_for_select: [])
     |> assign(:selected_batch_id, nil)
     |> assign(:selected_batch_remaining, nil)}
  end

  def handle_event("search_inventory_received", %{"search" => search}, socket) do
    inventories_for_select =
      InventoriesReceived.search_inventories_received(search)

    {:noreply,
     socket
     |> assign(inventories_for_select: inventories_for_select)
     |> assign(:inventory_received, nil)}
  end

  def handle_event("save", %{"inventory_issued" => inventory_issued_params}, socket) do
    inventory_issued_params =
      inventory_issued_params
      |> Map.put("inventory_manager_id", socket.assigns.current_user.id)
      |> Map.put("inventory_received_id", socket.assigns.inventory_received.id)
      |> Map.put("batch_id", socket.assigns.selected_batch_id)
      |> Map.put("requisition_id", socket.assigns.inventory_issued.requisition_id)
      |> maybe_put_drug_batch_id(socket.assigns.drug_batch_id)

    save_inventory_issued(socket, socket.assigns.action, inventory_issued_params)
  end

  defp maybe_put_drug_batch_id(params, nil), do: params

  defp maybe_put_drug_batch_id(params, drug_batch_id),
    do: Map.put(params, "drug_batch_id", drug_batch_id)

  defp save_inventory_issued(socket, :edit, inventory_issued_params) do
    case InventoriesIssues.update_inventory_issued(
           socket.assigns.inventory_issued,
           inventory_issued_params
         ) do
      {:ok, _inventory_issued} ->
        {:noreply,
         socket
         |> put_flash(:info, "Inventory issued updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_inventory_issued(socket, :new, inventory_issued_params) do
    case InventoriesIssues.create_inventory_issued(inventory_issued_params) do
      {:ok, inventory_issued} ->
        batch = Batches.get_batch!(inventory_issued.batch_id)

        inventory_received =
          InventoriesReceived.get_inventory_received!(inventory_issued.inventory_received_id)

        if inventory_issued.location == "Pharmacy" do
          {:ok, drug} =
            Drugs.get_or_create_drug_with_inventory_received_id(
              inventory_received,
              socket.assigns.current_user.id
            )

          DrugBatches.create_drug_batch(%{
            drug_id: drug.id,
            remaining_quantity: inventory_issued.quantity,
            batch_id: batch.id,
            is_confirmed: false,
            inventory_received_id: inventory_issued.inventory_received_id,
            inventory_manager_id: socket.assigns.current_user.id
          })
        end

        if inventory_issued.location == "Laboratory" do
          quantity =
            inventory_issued.quantity

          {:ok, _lab_allocation} =
            Medcamp.LabAllocations.create_lab_allocation(%{
              allocated_quantity: quantity,
              remaining_quantity: quantity,
              uom: inventory_received.uom,
              expiry_date: batch.expiry,
              inventory_issued_id: inventory_issued.id,
              allocated_by: socket.assigns.current_user.id,
              allocated_to: inventory_issued.assigned_to_id
            })
        end

        if inventory_issued.location == "Nurse" do
          quantity =
            inventory_issued.quantity

          {:ok, _lab_allocation} =
            Medcamp.Nursing.create_nursing_allocation(%{
              allocated_quantity: quantity,
              remaining_quantity: quantity,
              uom: inventory_received.uom,
              expiry_date: batch.expiry,
              inventory_issued_id: inventory_issued.id,
              allocated_by: socket.assigns.current_user.id,
              allocated_to: inventory_issued.assigned_to_id
            })
        end

        {:noreply,
         socket
         |> put_flash(:info, "Inventory issued created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
