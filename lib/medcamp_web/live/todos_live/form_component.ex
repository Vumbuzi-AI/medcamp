defmodule MedcampWeb.TodosLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Todos

  @impl true
  def update(%{todo: todo} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(Todos.change_todo(todo))}
  end

  @impl true
  def handle_event("validate", %{"todo" => todo_params}, socket) do
    changeset =
      socket.assigns.todo
      |> Todos.change_todo(todo_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"todo" => todo_params}, socket) do
    save_todo(socket, socket.assigns.action, todo_params)
  end

  defp save_todo(socket, :new, todo_params) do
    params = Map.put(todo_params, "created_by_id", socket.assigns.current_user.id)

    case Todos.create_todo(params) do
      {:ok, todo} ->
        notify_parent({:saved, todo})

        {:noreply,
         socket
         |> put_flash(:info, "Todo created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_todo(socket, :edit, todo_params) do
    case Todos.update_todo(socket.assigns.todo, todo_params) do
      {:ok, todo} ->
        notify_parent({:saved, todo})

        {:noreply,
         socket
         |> put_flash(:info, "Todo updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-4">
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="todo-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" required />
        <.input field={@form[:description]} type="textarea" label="Description (optional)" />
        <.input field={@form[:due_date]} type="date" label="Due Date" />
        <.input
          field={@form[:priority]}
          type="select"
          label="Priority"
          options={[{"Low", "low"}, {"Medium", "medium"}, {"High", "high"}]}
        />
        <.input
          field={@form[:status]}
          type="select"
          label="Status"
          options={[
            {"Pending", "pending"},
            {"In Progress", "in_progress"},
            {"Completed", "completed"}
          ]}
        />
        <.input
          field={@form[:assigned_to_name]}
          type="text"
          label="Assign To"
          placeholder="Enter name (optional)"
        />
        <:actions>
          <.button phx-disable-with="Saving...">Save Todo</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end
end
