defmodule MedcampWeb.AssignedTagLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.AssignedTags

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage assigned_tag records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="assigned_tag-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:number]} type="number" label="Assigned Number" />
        <.input field={@form[:date]} type="date" label="Date" />
        <.input field={@form[:remaining_number]} type="number" label="Remaining number" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Assigned tag</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{assigned_tag: assigned_tag} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(AssignedTags.change_assigned_tag(assigned_tag))
     end)}
  end

  @impl true
  def handle_event("validate", %{"assigned_tag" => assigned_tag_params}, socket) do
    changeset = AssignedTags.change_assigned_tag(socket.assigns.assigned_tag, assigned_tag_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"assigned_tag" => assigned_tag_params}, socket) do
    save_assigned_tag(socket, socket.assigns.action, assigned_tag_params)
  end

  defp save_assigned_tag(socket, :edit, assigned_tag_params) do
    case AssignedTags.update_assigned_tag(socket.assigns.assigned_tag, assigned_tag_params) do
      {:ok, _assigned_tag} ->
        {:noreply,
         socket
         |> put_flash(:info, "Assigned tag updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_assigned_tag(socket, :new, assigned_tag_params) do
    case AssignedTags.create_assigned_tag(assigned_tag_params) do
      {:ok, _assigned_tag} ->
        {:noreply,
         socket
         |> put_flash(:info, "Assigned tag created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
