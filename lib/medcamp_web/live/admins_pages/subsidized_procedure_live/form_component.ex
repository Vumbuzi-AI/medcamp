defmodule MedcampWeb.SubsidizedProcedureLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.SubsidizedProcedures

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="subsidized-procedure-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:price]} type="number" label="Price (KES)" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Subsidized Procedure</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{subsidized_procedure: subsidized_procedure} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(SubsidizedProcedures.change_subsidized_procedure(subsidized_procedure))
     end)}
  end

  @impl true
  def handle_event("validate", %{"subsidized_procedure" => params}, socket) do
    changeset =
      SubsidizedProcedures.change_subsidized_procedure(
        socket.assigns.subsidized_procedure,
        params
      )

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"subsidized_procedure" => params}, socket) do
    params = Map.put(params, "user_id", socket.assigns.current_user.id)
    save_subsidized_procedure(socket, socket.assigns.action, params)
  end

  defp save_subsidized_procedure(socket, :edit, params) do
    case SubsidizedProcedures.update_subsidized_procedure(
           socket.assigns.subsidized_procedure,
           params
         ) do
      {:ok, subsidized_procedure} ->
        notify_parent({:saved, subsidized_procedure})

        {:noreply,
         socket
         |> put_flash(:info, "Subsidized procedure updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_subsidized_procedure(socket, :new, params) do
    case SubsidizedProcedures.create_subsidized_procedure(params) do
      {:ok, subsidized_procedure} ->
        notify_parent({:saved, subsidized_procedure})

        {:noreply,
         socket
         |> put_flash(:info, "Subsidized procedure created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
