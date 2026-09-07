defmodule MedcampWeb.LabAllocationLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.LabAllocations

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage lab_allocation records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="lab_allocation-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input disabled field={@form[:allocated_quantity]} type="number" label="Allocated quantity" />
        <.input field={@form[:remaining_quantity]} type="number" label="Remaining quantity" />
        <.input field={@form[:uom]} type="text" label="Uom" />
        <.input field={@form[:expiry_date]} type="date" label="Expiry date" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Lab allocation</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{lab_allocation: lab_allocation} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(LabAllocations.change_lab_allocation(lab_allocation))
     end)}
  end

  @impl true
  def handle_event("validate", %{"lab_allocation" => lab_allocation_params}, socket) do
    changeset =
      LabAllocations.change_lab_allocation(socket.assigns.lab_allocation, lab_allocation_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"lab_allocation" => lab_allocation_params}, socket) do
    save_lab_allocation(socket, socket.assigns.action, lab_allocation_params)
  end

  defp save_lab_allocation(socket, :edit, lab_allocation_params) do
    case LabAllocations.update_lab_allocation(
           socket.assigns.lab_allocation,
           lab_allocation_params
         ) do
      {:ok, lab_allocation} ->
        notify_parent({:saved, lab_allocation})

        {:noreply,
         socket
         |> put_flash(:info, "Lab allocation updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_lab_allocation(socket, :new, lab_allocation_params) do
    case LabAllocations.create_lab_allocation(lab_allocation_params) do
      {:ok, lab_allocation} ->
        notify_parent({:saved, lab_allocation})

        {:noreply,
         socket
         |> put_flash(:info, "Lab allocation created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
