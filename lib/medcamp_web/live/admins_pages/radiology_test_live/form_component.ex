defmodule MedcampWeb.RadiologyTestLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.RadiologyTests

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="radiology_test-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:price]} type="number" label="Price" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Radiology test</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{radiology_test: radiology_test} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(RadiologyTests.change_radiology_test(radiology_test))
     end)}
  end

  @impl true
  def handle_event("validate", %{"radiology_test" => radiology_test_params}, socket) do
    changeset =
      RadiologyTests.change_radiology_test(socket.assigns.radiology_test, radiology_test_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"radiology_test" => radiology_test_params}, socket) do
    radiology_test_params =
      radiology_test_params
      |> Map.put("creator_id", socket.assigns.current_user.id)

    save_radiology_test(socket, socket.assigns.action, radiology_test_params)
  end

  defp save_radiology_test(socket, :edit, radiology_test_params) do
    case RadiologyTests.update_radiology_test(
           socket.assigns.radiology_test,
           radiology_test_params
         ) do
      {:ok, radiology_test} ->
        notify_parent({:saved, radiology_test})

        {:noreply,
         socket
         |> put_flash(:info, "Radiology test updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_radiology_test(socket, :new, radiology_test_params) do
    case RadiologyTests.create_radiology_test(radiology_test_params) do
      {:ok, radiology_test} ->
        notify_parent({:saved, radiology_test})

        {:noreply,
         socket
         |> put_flash(:info, "Radiology test created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
