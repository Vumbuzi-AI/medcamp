defmodule MedcampWeb.PharmacistsLive.DrugFormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.Drugs

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="drug-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:stock_quantity]} type="number" label="Stock quantity" />
        <.input field={@form[:expiry_date]} type="date" label="Expiry date" />
        <.input field={@form[:price_per_unit]} type="text" label="Price per unit" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Drug</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{drug: drug} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:form, fn ->
       to_form(Drugs.change_drug(drug))
     end)}
  end

  @impl true
  def handle_event("validate", %{"drug" => drug_params}, socket) do
    changeset = Drugs.change_drug(socket.assigns.drug, drug_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"drug" => drug_params}, socket) do
    drug_params =
      drug_params
      |> Map.put("pharmacist_id", socket.assigns.current_user.id)

    save_drug(socket, socket.assigns.action, drug_params)
  end

  defp save_drug(socket, :edit, drug_params) do
    case Drugs.update_drug(socket.assigns.drug, drug_params) do
      {:ok, _drug} ->
        {:noreply,
         socket
         |> put_flash(:info, "Drug updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_drug(socket, :new, drug_params) do
    case Drugs.create_drug(drug_params) do
      {:ok, _drug} ->
        {:noreply,
         socket
         |> put_flash(:info, "Drug created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
