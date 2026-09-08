defmodule MedcampWeb.PharmacistsLive.DrugBatchFormComponent do
  use MedcampWeb, :live_component

  @moduledoc """
  Takes a new batch of an existing drug into the camp pharmacy.

  The pharmacist picks the drug, then keys in what is printed on the pack -
  GTIN, batch/lot number, expiry and quantity. The batch is available
  immediately after it is recorded.
  """

  alias Medcamp.Drugs
  alias Medcamp.DrugBatches

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {if @action == :edit_batch, do: "Edit Drug Batch", else: "Add Drug Batch"}
        <:subtitle>
          {if @action == :edit_batch,
            do: "Update this batch's stock and GS1 details.",
            else: "Record a batch of an existing drug. It will be available immediately."}
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="drug-batch-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <%= if @drug do %>
          <input type="hidden" name="drug_batch[drug_id]" value={@drug.id} />
          <div class="rounded-lg border border-slate-200 bg-slate-50 px-4 py-3">
            <p class="text-xs font-medium uppercase tracking-wide text-slate-500">Drug</p>
            <p class="mt-1 font-semibold text-slate-900">{Drugs.display_name(@drug)}</p>
          </div>
        <% else %>
          <.input
            field={@form[:drug_id]}
            type="select"
            options={@drug_options}
            prompt="Select drug"
            label="Drug"
            required
          />
        <% end %>
        <.input field={@form[:gtin]} type="text" label="GTIN" required readonly={not is_nil(@drug)} />
        <.input field={@form[:batch]} type="text" label="Batch / lot number" required />
        <.input field={@form[:manufacture_date]} type="date" label="Production date" required />
        <.input field={@form[:expiry]} type="date" label="Expiry date" required />
        <.input field={@form[:quantity]} type="number" min="1" label="Quantity" required />
        <.input
          field={@form[:price_per_unit]}
          type="number"
          min="0"
          label="Price per unit (KSh)"
          required
        />
        <.input field={@form[:manufacturer]} type="text" label="Manufacturer" />
        <.input field={@form[:serial]} type="text" label="Serial (optional)" />

        <p :if={@error} class="text-red-500 text-sm">{@error}</p>

        <:actions>
          <.button phx-disable-with="Saving...">
            {if @action == :edit_batch, do: "Save Batch", else: "Add Batch"}
          </.button>
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
     |> assign_new(:drug, fn -> nil end)
     |> assign_new(:drug_batch, fn -> nil end)
     |> assign(:error, nil)
     |> assign(:drug_options, drug_options())
     |> assign_new(:form, fn ->
       to_form(initial_params(assigns[:drug], assigns[:drug_batch]), as: :drug_batch)
     end)}
  end

  defp initial_params(nil, nil), do: %{}

  defp initial_params(drug, nil) do
    %{"drug_id" => drug.id, "gtin" => drug.inventory_received.gtin}
  end

  defp initial_params(drug, drug_batch) do
    batch = drug_batch.batch

    %{
      "drug_id" => drug.id,
      "gtin" => batch.gtin || drug.inventory_received.gtin,
      "batch" => batch.batch,
      "manufacture_date" => batch.manufacture_date,
      "expiry" => batch.expiry,
      "quantity" => drug_batch.remaining_quantity,
      "price_per_unit" => batch.price_per_unit,
      "manufacturer" => batch.manufacturer,
      "serial" => batch.serial
    }
  end

  @impl true
  def handle_event("validate", %{"drug_batch" => params}, socket) do
    {:noreply, assign(socket, :form, to_form(params, as: :drug_batch))}
  end

  def handle_event("save", %{"drug_batch" => params}, socket) do
    with {:ok, drug_id} <- selected_drug_id(socket, params),
         {:ok, quantity} <- fetch_integer(params, "quantity", "Enter a quantity."),
         {:ok, price_per_unit} <-
           fetch_non_negative_integer(params, "price_per_unit", "Enter a valid unit price."),
         drug when not is_nil(drug) <- Drugs.get_drug!(drug_id) do
      attrs = %{
        drug_id: drug.id,
        inventory_received_id: drug.inventory_received_id,
        inventory_manager_id: socket.assigns.current_user.id,
        quantity: quantity,
        price_per_unit: price_per_unit,
        gtin: params["gtin"],
        batch: params["batch"],
        manufacture_date: params["manufacture_date"],
        expiry: params["expiry"],
        serial: blank_to_nil(params["serial"]),
        manufacturer: blank_to_nil(params["manufacturer"])
      }

      case persist_batch(socket, attrs) do
        {:ok, _drug_batch} ->
          message =
            if socket.assigns.action == :edit_batch, do: "Batch updated.", else: "Batch added."

          {:noreply,
           socket
           |> put_flash(:info, message)
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

  defp persist_batch(%{assigns: %{action: :edit_batch, drug_batch: drug_batch}}, attrs) do
    DrugBatches.update_taken_in_batch(drug_batch, attrs)
  end

  defp persist_batch(_socket, attrs), do: DrugBatches.take_in_batch(attrs)

  defp selected_drug_id(%{assigns: %{drug: %{id: id}}}, _params), do: {:ok, id}
  defp selected_drug_id(_socket, params), do: fetch_integer(params, "drug_id", "Select a drug.")

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

  defp fetch_non_negative_integer(params, key, message) do
    case Integer.parse(to_string(params[key] || "")) do
      {value, ""} when value >= 0 -> {:ok, value}
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
