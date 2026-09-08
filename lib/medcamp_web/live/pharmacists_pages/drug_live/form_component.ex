defmodule MedcampWeb.PharmacistsLive.DrugFormComponent do
  use MedcampWeb, :live_component

  @moduledoc """
  Adds a drug to the camp pharmacy, or edits one.

  A drug is identified by its GTIN, so adding one creates both the item-master
  row and the drug (`Medcamp.Drugs.create_camp_drug/2`). Stock itself is not
  entered here - a drug is a catalogue entry, and quantities arrive as batches
  under Drug Batches.
  """

  alias Medcamp.Drugs

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle :if={@action == :new}>
          Adds the drug to the catalogue. Record quantities separately, as batches.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="drug-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:gtin]}
          type="text"
          label="GTIN"
          required={@action == :new}
          disabled={@action == :edit}
        />
        <.input field={@form[:generic_name]} type="text" label="Generic name" required />
        <.input field={@form[:brand_name]} type="text" label="Brand name" />
        <.input field={@form[:strength]} type="text" label="Strength" />
        <.input field={@form[:uom]} type="text" label="Unit of measure" />
        <p :if={@error} class="text-red-500 text-sm">{@error}</p>

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
     |> assign(:error, nil)
     |> assign_new(:form, fn -> to_form(initial_params(drug), as: :drug) end)}
  end

  defp initial_params(nil), do: %{}

  defp initial_params(drug) do
    item = item_master(drug)

    %{
      "gtin" => item && item.gtin,
      "generic_name" => drug.generic_name,
      "brand_name" => drug.brand_name,
      "strength" => item && item.strength,
      "uom" => item && item.uom
    }
  end

  # A brand new `%Drug{}` has an unloaded association rather than nil, so it
  # cannot be dereferenced directly.
  defp item_master(%{inventory_received: %Ecto.Association.NotLoaded{}}), do: nil
  defp item_master(%{inventory_received: item}), do: item
  defp item_master(_drug), do: nil

  @impl true
  def handle_event("validate", %{"drug" => drug_params}, socket) do
    {:noreply, assign(socket, :form, to_form(drug_params, as: :drug))}
  end

  def handle_event("save", %{"drug" => drug_params}, socket) do
    save_drug(socket, socket.assigns.action, drug_params)
  end

  defp save_drug(socket, :edit, drug_params) do
    attrs = Map.take(drug_params, ["generic_name", "brand_name"])

    case Drugs.update_drug(socket.assigns.drug, attrs) do
      {:ok, _drug} ->
        {:noreply,
         socket
         |> put_flash(:info, "Drug updated successfully")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(:error, changeset_message(changeset))}
    end
  end

  defp save_drug(socket, :new, drug_params) do
    case Drugs.create_camp_drug(drug_params, socket.assigns.current_user) do
      {:ok, _drug} ->
        {:noreply,
         socket
         |> put_flash(:info, "Drug added to the catalogue")
         |> push_navigate(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply,
         socket
         |> assign(:error, changeset_message(changeset))
         |> assign(:form, to_form(drug_params, as: :drug))}
    end
  end

  defp changeset_message(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
    |> Enum.map_join("; ", fn {field, msgs} -> "#{field} #{Enum.join(msgs, ", ")}" end)
  end
end
