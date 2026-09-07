defmodule MedcampWeb.DrugAllocationLive.DrugGivenFormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.DrugsGiven
  alias Medcamp.DrugBatches

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        for={@form}
        id="drug_given-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:drug_id]}
          prompt="Select Drug"
          type="select"
          label="Drug"
          options={@drugs_for_selection}
        />
        <.input field={@form[:quantity]} type="number" label="Quantity" />
        <:actions>
          <.button phx-disable-with="Saving...">Save Drug given</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{drug_given: drug_given} = assigns, socket) do
    drugs_for_selection = DrugBatches.get_drugs_with_active_drug_batch_for_selection()

    {:ok,
     socket
     |> assign(assigns)
     |> assign(drugs_for_selection: drugs_for_selection)
     |> assign_new(:form, fn ->
       to_form(DrugsGiven.change_drug_given(drug_given))
     end)}
  end

  @impl true
  def handle_event("validate", %{"drug_given" => drug_given_params}, socket) do
    new_params =
      if drug_given_params["drug_id"] do
        drug = DrugBatches.get_drug_with_active_drug_batch(drug_given_params["drug_id"])

        price = get_price(drug_given_params["quantity"], drug.batch.price_per_unit)

        drug_given_params
        |> Map.put("drug_batch_id", drug.batch.id)
        |> Map.put("price", price)
      else
        drug_given_params
      end

    changeset = DrugsGiven.change_drug_given(socket.assigns.drug_given, new_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"drug_given" => drug_given_params}, socket) do
    drug_given_params =
      drug_given_params
      |> Map.put("pharmacist_id", socket.assigns.current_user.id)
      |> Map.put("drug_allocation_id", socket.assigns.drug_allocation.id)

    params =
      if drug_given_params["drug_id"] do
        drug = DrugBatches.get_drug_with_active_drug_batch(drug_given_params["drug_id"])

        price = get_price(drug_given_params["quantity"], drug.batch.price_per_unit)

        drug_given_params
        |> Map.put("drug_batch_id", drug.batch.id)
        |> Map.put("price", price)
      else
        drug_given_params
      end

    save_drug_given(socket, socket.assigns.action, params)
  end

  defp save_drug_given(socket, :edit, drug_given_params) do
    case DrugsGiven.update_drug_given(socket.assigns.drug_given, drug_given_params) do
      {:ok, _drug_given} ->
        {:noreply,
         socket
         |> put_flash(:info, "Drug given updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_drug_given(socket, :new, drug_given_params) do
    case DrugsGiven.create_drug_given(drug_given_params) do
      {:ok, _drug_given} ->
        {:noreply,
         socket
         |> put_flash(:info, "Drug given created successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp get_price(nil, _price), do: nil
  defp get_price("", _price), do: nil

  defp get_price(quantity, price) do
    String.to_integer(quantity) * price
  end
end
