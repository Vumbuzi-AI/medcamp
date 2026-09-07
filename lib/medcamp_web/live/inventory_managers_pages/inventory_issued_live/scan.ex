defmodule MedcampWeb.InventoryIssuedLive.ScanComponent do
  alias Medcamp.InventoriesReceived
  use MedcampWeb, :live_component

  alias Medcamp.InventoriesIssues
  alias Medcamp.InventoriesReceived
  alias Medcamp.Batches
  alias Medcamp.Drugs
  alias Medcamp.Accounts
  alias Medcamp.DrugBatches

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={%{}}
        id="inventory_issued-form"
        phx-target={@myself}
        phx-submit="save_gtin"
        phx-change="save_gtin"
      >
        <.input type="text" name="inventory_issued[gtin]" value={@gtin} label="Inventory received" />
      </.simple_form>

      <div :if={@inventory_received != nil && @batch != nil} class="text-sm mt-8 text-gray-500">
        <span class="font-semibold">Inventory received:</span>
        <div class="flex gap-2 text-lg bg-gray-100 p-2 rounded-lg items-center justify-between">
          <div class="flex items-center gap-2">
            <span class="text-gray-700">{@inventory_received.brand_name}</span>
            <span class=" text-gray-500">{@inventory_received.generic_name}</span>
          </div>
        </div>

        <span class="font-semibold">Batch:</span>
        <div class="flex gap-2 text-lg bg-gray-100 p-2 rounded-lg items-center justify-between">
          <div class="flex items-center gap-2">
            <span class="text-gray-700">{@batch.batch}</span>
          </div>
        </div>
        <.simple_form
          for={@form}
          id="inventory_issued-form"
          phx-target={@myself}
          phx-change="validate"
          phx-submit="save"
        >
          <.input field={@form[:quantity]} type="number" label="Quantity" />
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
          <.button class="mt-4" phx-disable-with="Saving..." phx-target={@myself} type="submit">
            Save Inventory Issued
          </.button>
        </.simple_form>
      </div>
    </div>
    """
  end

  @impl true
  def update(%{inventory_issued: inventory_issued} = assigns, socket) do
    batches_for_select =
      Batches.list_batches_for_select_for_inventory_received(
        inventory_issued.inventory_received_id
      )

    users_for_select =
      Accounts.list_users_for_selection()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(users_for_select: users_for_select)
     |> assign(gtin: "")
     |> assign(inventories_for_select: [])
     |> assign(:inventory_received, nil)
     |> assign(:batch, nil)
     |> assign(batches_for_select: batches_for_select)
     |> assign_new(:form, fn ->
       to_form(InventoriesIssues.change_inventory_issued(inventory_issued))
     end)}
  end

  @impl true

  def handle_event("save_gtin", %{"inventory_issued" => inventory_issued_params}, socket) do
    gtin = InventoriesReceived.strip_first_three_take_13(inventory_issued_params["gtin"])

    case InventoriesReceived.get_inventory_received_by_gtin(gtin) do
      nil ->
        {:noreply,
         socket
         |> assign(inventory_received: nil)
         |> assign(:gtin, inventory_issued_params["gtin"])
         |> assign(batches_for_select: [])}

      inventory_received ->
        batch =
          Batches.get_batch_by_gtin_and_batch(
            gtin,
            InventoriesReceived.extract_batch(inventory_issued_params["gtin"])
          )

        {:noreply,
         socket
         |> assign(:inventory_received, inventory_received)
         |> assign(:gtin, inventory_issued_params["gtin"])
         |> assign(:batch, batch)}
    end
  end

  def handle_event("validate", %{"inventory_issued" => inventory_issued_params}, socket) do
    changeset =
      InventoriesIssues.change_inventory_issued(
        socket.assigns.inventory_issued,
        inventory_issued_params
      )

    {:noreply,
     socket
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("select_inventory_received", %{"id" => id}, socket) do
    inventory_received = InventoriesReceived.get_inventory_received!(id)

    batches_for_select =
      Batches.list_batches_for_select_for_inventory_received(inventory_received.id)

    {:noreply,
     socket
     |> assign(:inventory_received, inventory_received)
     |> assign(batches_for_select: batches_for_select)}
  end

  def handle_event("remove_inventory_received", _params, socket) do
    {:noreply,
     socket
     |> assign(:inventory_received, nil)
     |> assign(batches_for_select: [])
     |> assign(inventories_for_select: [])}
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
      |> Map.put("batch_id", socket.assigns.batch.id)

    save_inventory_issued(socket, socket.assigns.action, inventory_issued_params)
  end

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

        {:noreply,
         socket
         |> put_flash(:info, "Inventory issued created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_inventory_issued(socket, :scan, inventory_issued_params) do
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

        {:noreply,
         socket
         |> put_flash(:info, "Inventory issued created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
