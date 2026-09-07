defmodule MedcampWeb.PharmacistsLive.PendingDrugBatchesScan do
  alias Medcamp.InventoriesReceived
  use MedcampWeb, :live_component

  alias Medcamp.InventoriesIssues
  alias Medcamp.InventoriesReceived
  alias Medcamp.Batches
  alias Medcamp.Drugs
  alias Medcamp.DrugBatches

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Scan Drug Batch to Confirm ({@drug_batch.drug.brand_name} - Batch {@drug_batch.batch.batch})
      </.header>

      <.simple_form
        for={%{}}
        id="inventory_issued-form"
        phx-target={@myself}
        phx-submit="save_gtin"
        phx-change="save_gtin"
      >
        <.input type="text" name="inventory_issued[gtin]" value={@gtin} label="Inventory received" />

        <p :if={@error} class="text-red-500 text-sm mt-2">
          {@error}
        </p>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(gtin: "")
     |> assign(:inventory_received, nil)
     |> assign(:error, nil)
     |> assign(:batch, nil)}
  end

  @impl true

  def handle_event("save_gtin", %{"inventory_issued" => inventory_issued_params}, socket) do
    gtin = InventoriesReceived.strip_first_three_take_13(inventory_issued_params["gtin"])

    IO.inspect(gtin, label: "Scanned GTIN")

    case InventoriesReceived.get_inventory_received_by_gtin(gtin) do
      nil ->
        {:noreply,
         socket
         |> assign(inventory_received: nil)
         |> assign(:error, "No inventory received found with the provided GTIN and batch")
         |> assign(:gtin, inventory_issued_params["gtin"])
         |> assign(:batch, nil)}

      _inventory_received ->
        batch =
          Batches.get_batch_by_gtin_and_batch(
            gtin,
            InventoriesReceived.extract_batch(inventory_issued_params["gtin"])
          )

        if batch == nil do
          {:noreply,
           socket
           |> assign(:error, "No batch found with the provided GTIN and batch")
           |> assign(:inventory_received, nil)
           |> assign(:gtin, inventory_issued_params["gtin"])
           |> assign(:batch, nil)}
        else
          DrugBatches.update_drug_batch(socket.assigns.drug_batch, %{
            is_confirmed: true,
            confirmed_by_id: socket.assigns.current_user.id
          })

          {:ok, _} =
            Batches.update_batch(batch, %{
              has_been_issued: true,
              remaining_quantity:
                batch.remaining_quantity - socket.assigns.drug_batch.remaining_quantity
            })

          {:noreply,
           socket
           |> put_flash(:info, "Batch Confirmed successfully")
           |> push_navigate(to: socket.assigns.patch)}
        end
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
