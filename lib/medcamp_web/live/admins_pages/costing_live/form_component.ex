defmodule MedcampWeb.CostingLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Costings

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="costing-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:type]}
          type="select"
          options={[
            "Consultation",
            "Admission Request",
            "Triage Only"
          ]}
          label="Type"
          prompt="Select a type"
        />
        <.input field={@form[:price]} type="number" label="Price" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Costing</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{costing: costing} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Costings.change_costing(costing))
     end)}
  end

  @impl true
  def handle_event("validate", %{"costing" => costing_params}, socket) do
    changeset = Costings.change_costing(socket.assigns.costing, costing_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"costing" => costing_params}, socket) do
    costing_params =
      costing_params
      |> Map.put("user_id", socket.assigns.current_user.id)

    save_costing(socket, socket.assigns.action, costing_params)
  end

  defp save_costing(socket, :edit, costing_params) do
    case Costings.update_costing(socket.assigns.costing, costing_params) do
      {:ok, costing} ->
        notify_parent({:saved, costing})

        {:noreply,
         socket
         |> put_flash(:info, "Costing updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_costing(socket, :new, costing_params) do
    case Costings.create_costing(costing_params) do
      {:ok, costing} ->
        notify_parent({:saved, costing})

        {:noreply,
         socket
         |> put_flash(:info, "Costing created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
