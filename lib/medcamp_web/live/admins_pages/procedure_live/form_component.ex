defmodule MedcampWeb.ProcedureLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Procedures

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="procedure-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:price]} type="number" label="Price" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Procedure</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{procedure: procedure} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Procedures.change_procedure(procedure))
     end)}
  end

  @impl true
  def handle_event("validate", %{"procedure" => procedure_params}, socket) do
    changeset = Procedures.change_procedure(socket.assigns.procedure, procedure_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"procedure" => procedure_params}, socket) do
    procedure_params =
      Map.put(procedure_params, "user_id", socket.assigns.current_user.id)

    save_procedure(socket, socket.assigns.action, procedure_params)
  end

  defp save_procedure(socket, :edit, procedure_params) do
    case Procedures.update_procedure(socket.assigns.procedure, procedure_params) do
      {:ok, procedure} ->
        notify_parent({:saved, procedure})

        {:noreply,
         socket
         |> put_flash(:info, "Procedure updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_procedure(socket, :new, procedure_params) do
    case Procedures.create_procedure(procedure_params) do
      {:ok, procedure} ->
        notify_parent({:saved, procedure})

        {:noreply,
         socket
         |> put_flash(:info, "Procedure created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
