defmodule MedcampWeb.BatchLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Batches

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="batch-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:gtin]}
          type="text"
          value={@gtin_from_inventory_received}
          readonly
          label="Gtin"
        />
        <.input field={@form[:batch]} type="text" label="Batch" />
        <.input
          field={@form[:supplier_id]}
          type="select"
          label="Supplier"
          prompt="Select supplier"
          options={@supplier_options}
        />
        <.input field={@form[:cost_per_unit]} type="number" label="Cost Per Unit" />
        <.input field={@form[:price_per_unit]} type="number" label="Price Per Unit" />
        <.input field={@form[:expiry]} type="date" label="Expiry" />
        <.input field={@form[:manufacture_date]} type="date" label="Manufacture Date" />
        <.input field={@form[:received_date]} type="date" label="Received Date" />

        <.input field={@form[:serial]} type="text" label="Serial" />
        <.input field={@form[:quantity]} type="number" label="Received Quantity" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Batch</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{batch: batch} = assigns, socket) do
    suppliers = Map.get(assigns, :suppliers, [])
    supplier_options = Enum.map(suppliers, fn {name, id} -> {name, id} end)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:gtin_from_inventory_received, assigns.inventory_received.gtin)
     |> assign(:supplier_options, supplier_options)
     |> assign_new(:form, fn ->
       to_form(Batches.change_batch(batch))
     end)}
  end

  @impl true
  def handle_event("validate", %{"batch" => batch_params}, socket) do
    changeset = Batches.change_batch(socket.assigns.batch, batch_params)

    {:noreply,
     socket
     |> assign(:gtin_from_inventory_received, batch_params["gtin"])
     |> assign(form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"batch" => batch_params}, socket) do
    batch_params =
      batch_params
      |> Map.put("inventory_received_id", socket.assigns.inventory_received.id)
      |> Map.put("inventory_manager_id", socket.assigns.current_user.id)

    save_batch(socket, socket.assigns.action, batch_params)
  end

  defp save_batch(socket, :edit, batch_params) do
    # Do not update remaining_quantity on edit (form does not include it)
    batch_params = Map.delete(batch_params, "remaining_quantity")

    case Batches.update_batch(socket.assigns.batch, batch_params) do
      {:ok, batch} ->
        notify_parent({:saved, batch})

        {:noreply,
         socket
         |> put_flash(:info, "Batch updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_batch(socket, :new, batch_params) do
    # On creation only: set remaining_quantity = initial quantity (total given)
    batch_params = Map.put(batch_params, "remaining_quantity", batch_params["quantity"])

    case Batches.create_batch(batch_params) do
      {:ok, batch} ->
        notify_parent({:saved, batch})

        {:noreply,
         socket
         |> put_flash(:info, "Batch created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
