defmodule MedcampWeb.PharmacistsLive.DrugBatchFormComponent do
  use MedcampWeb, :live_component

  @moduledoc """
  Takes a new batch of an existing drug into the camp pharmacy.

  The pharmacist picks the drug, then keys in what is printed on the pack -
  GTIN, batch/lot number, expiry and quantity. The batch is saved unconfirmed;
  confirming it means scanning the pack's GS1 DataMatrix on the pending
  batches list, which is what proves the physical stock matches what was
  keyed in.
  """

  alias Medcamp.Drugs
  alias Medcamp.DrugBatches

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Add Drug Batch
        <:subtitle>
          Record a batch of an existing drug. Scan its DataMatrix afterwards to confirm it.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="drug-batch-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:drug_id]}
          type="select"
          options={@drug_options}
          prompt="Select drug"
          label="Drug"
          required
        />
        <.input field={@form[:gtin]} type="text" label="GTIN" required />
        <.input field={@form[:batch]} type="text" label="Batch / lot number" required />
        <.input field={@form[:expiry]} type="date" label="Expiry date" required />
        <.input field={@form[:quantity]} type="number" min="1" label="Quantity" required />
        <.input field={@form[:manufacturer]} type="text" label="Manufacturer" />
        <.input field={@form[:serial]} type="text" label="Serial (optional)" />

        <p :if={@error} class="text-red-500 text-sm">{@error}</p>

        <:actions>
          <.button phx-disable-with="Saving...">Add Batch</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:error, nil)
     |> assign(:drug_options, drug_options())
     |> assign_new(:form, fn -> to_form(%{}, as: :drug_batch) end)}
  end

  @impl true
  def handle_event("validate", %{"drug_batch" => params}, socket) do
    {:noreply, assign(socket, :form, to_form(params, as: :drug_batch))}
  end

  def handle_event("save", %{"drug_batch" => params}, socket) do
    with {:ok, drug_id} <- fetch_integer(params, "drug_id", "Select a drug."),
         {:ok, quantity} <- fetch_integer(params, "quantity", "Enter a quantity."),
         drug when not is_nil(drug) <- Drugs.get_drug!(drug_id) do
      attrs = %{
        drug_id: drug.id,
        inventory_received_id: drug.inventory_received_id,
        inventory_manager_id: socket.assigns.current_user.id,
        quantity: quantity,
        gtin: params["gtin"],
        batch: params["batch"],
        expiry: params["expiry"],
        serial: blank_to_nil(params["serial"]),
        manufacturer: blank_to_nil(params["manufacturer"])
      }

      case DrugBatches.take_in_batch(attrs) do
        {:ok, _drug_batch} ->
          {:noreply,
           socket
           |> put_flash(:info, "Batch added. Scan its DataMatrix to confirm it.")
           |> push_navigate(to: socket.assigns.patch)}

        {:error, changeset} ->
          {:noreply,
           socket
           |> assign(:error, changeset_message(changeset))
           |> assign(:form, to_form(params, as: :drug_batch))}
      end
    else
      {:error, message} ->
        {:noreply,
         socket |> assign(:error, message) |> assign(:form, to_form(params, as: :drug_batch))}
    end
  end

  defp drug_options do
    Drugs.list_drugs()
    |> Enum.map(fn drug ->
      label =
        drug.generic_name || drug.brand_name ||
          (drug.inventory_received &&
             (drug.inventory_received.generic_name || drug.inventory_received.brand_name)) ||
          "Drug ##{drug.id}"

      {label, drug.id}
    end)
    |> Enum.sort_by(fn {label, _id} -> String.downcase(label) end)
  end

  defp fetch_integer(params, key, message) do
    case Integer.parse(to_string(params[key] || "")) do
      {value, ""} when value > 0 -> {:ok, value}
      _ -> {:error, message}
    end
  end

  defp blank_to_nil(value) when is_binary(value) do
    case String.trim(value) do
      "" -> nil
      trimmed -> trimmed
    end
  end

  defp blank_to_nil(_), do: nil

  defp changeset_message(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
    |> Enum.map_join("; ", fn {field, msgs} -> "#{field} #{Enum.join(msgs, ", ")}" end)
  end
end
