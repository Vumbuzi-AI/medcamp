defmodule MedcampWeb.LabTestLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.LabTests

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="lab_test-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:desription]} type="textarea" label="Desription" />
        <div class="mb-4">
          <h4 class="text-sm font-medium text-gray-700 mb-2">Rates</h4>
          <div class="space-y-3">
            <.input field={@form[:price]} type="number" label="Standard rate (KES)" />
            <.input
              field={@form[:subsidized_price]}
              type="number"
              label="Subsidized rate (30% off for students, KES)"
            />
          </div>
        </div>
        <:actions>
          <.button phx-disable-with="Saving...">Save Lab test</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{lab_test: lab_test} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(LabTests.change_lab_test(lab_test))
     end)}
  end

  @impl true
  def handle_event("validate", %{"lab_test" => lab_test_params}, socket) do
    changeset = LabTests.change_lab_test(socket.assigns.lab_test, lab_test_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"lab_test" => lab_test_params}, socket) do
    lab_test_params = Map.put(lab_test_params, "creator_id", socket.assigns.current_user.id)
    save_lab_test(socket, socket.assigns.action, lab_test_params)
  end

  defp save_lab_test(socket, :edit, lab_test_params) do
    case LabTests.update_lab_test(socket.assigns.lab_test, lab_test_params) do
      {:ok, _lab_test} ->
        {:noreply,
         socket
         |> put_flash(:info, "Lab test updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_lab_test(socket, :new, lab_test_params) do
    case LabTests.create_lab_test(lab_test_params) do
      {:ok, _lab_test} ->
        {:noreply,
         socket
         |> put_flash(:info, "Lab test created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
