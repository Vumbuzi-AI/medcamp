defmodule MedcampWeb.PharmacistsLive.DrugFormComponent do
  use MedcampWeb, :live_component

  @moduledoc """
  Adds a drug to the camp pharmacy, or edits one.

  A drug is identified by its GTIN, so adding one creates both the item-master
  row and the drug (`Medcamp.Drugs.create_camp_drug/2`). Stock itself is not
  entered here - a drug is a catalogue entry, and quantities arrive as batches
  under Drug Batches.

  On `:new`, the pharmacist can scan the product barcode with the device
  camera; a GS1 Data Matrix or a plain EAN/UPC both resolve to a GTIN, which
  fills the field and - if that product has been catalogued before - prefills
  the rest from the existing item master. Manual entry always stays available.
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

      <div :if={@action == :new} class="mt-4">
        <button
          type="button"
          phx-click="toggle_scan"
          phx-target={@myself}
          class="inline-flex items-center gap-2 rounded-full border border-slate-300 bg-white px-4 py-2 text-sm font-semibold text-slate-700 transition-colors hover:bg-slate-100"
        >
          <.icon name="hero-qr-code" class="h-4 w-4" />
          {if @scanning, do: "Close scanner", else: "Scan barcode"}
        </button>

        <div
          :if={@scanning}
          id="drug-barcode-scanner"
          phx-hook="QrCameraScanner"
          phx-update="ignore"
          class="relative mt-3 overflow-hidden rounded-xl border border-slate-200 bg-slate-900"
        >
          <div class="qr-overlay absolute inset-0 z-10 hidden items-center justify-center bg-slate-900/70 text-sm font-semibold text-white">
            Code detected!
          </div>
          <p class="qr-status px-4 py-3 text-center text-xs text-slate-300">
            Point the camera at the barcode...
          </p>
        </div>

        <p :if={@scan_error} class="mt-2 text-sm text-amber-600">{@scan_error}</p>
      </div>

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
          label="GTIN (barcode number)"
          placeholder="8, 12, 13 or 14 digits"
          inputmode="numeric"
          required={@action == :new}
          disabled={@action == :edit}
        />
        <.input field={@form[:generic_name]} type="text" label="Generic name" required />
        <.input field={@form[:brand_name]} type="text" label="Brand name (optional)" />
        <.input
          field={@form[:strength]}
          type="text"
          label="Strength (per unit)"
          placeholder="e.g. 500 mg, 125 mg/5 mL, 1%"
        />
        <.input
          field={@form[:uom]}
          type="select"
          label="Unit of measure"
          prompt="Select a unit"
          options={Medcamp.InventoriesReceived.InventoryReceived.units_of_measure()}
        />
        <p :if={@error} class="text-red-500 text-sm">{@error}</p>

        <:actions>
          <.button phx-disable-with="Saving...">Save Drug</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{scanned_code: raw}, socket) do
    case parse_gtin(raw) do
      {:ok, gtin} ->
        existing = Drugs.get_item_master_by_gtin(gtin)

        params =
          socket
          |> current_params()
          |> Map.put("gtin", gtin)
          |> prefill_from_item(existing)

        {:ok,
         socket
         |> assign(:scanning, false)
         |> assign(:scan_error, nil)
         |> assign(:error, nil)
         |> assign(:form, build_form(socket, params))}

      :error ->
        {:ok,
         assign(
           socket,
           :scan_error,
           "Couldn't read a GTIN from that barcode. Enter it manually below."
         )}
    end
  end

  def update(%{drug: drug} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:error, nil)
     |> assign_new(:scanning, fn -> false end)
     |> assign_new(:scan_error, fn -> nil end)
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
  def handle_event("toggle_scan", _params, socket) do
    {:noreply,
     socket
     |> assign(:scanning, not socket.assigns.scanning)
     |> assign(:scan_error, nil)}
  end

  def handle_event("validate", %{"drug" => drug_params}, socket) do
    {:noreply, assign(socket, :form, build_form(socket, drug_params))}
  end

  def handle_event("save", %{"drug" => drug_params}, socket) do
    save_drug(socket, socket.assigns.action, drug_params)
  end

  defp build_form(socket, drug_params) do
    case socket.assigns.action do
      :new ->
        %Medcamp.InventoriesReceived.InventoryReceived{}
        |> Medcamp.InventoriesReceived.InventoryReceived.changeset(drug_params, strict: true)
        |> Map.put(:action, :validate)
        |> to_form(as: :drug)

      _ ->
        to_form(drug_params, as: :drug)
    end
  end

  defp current_params(%{assigns: %{form: %{params: params}}}) when is_map(params), do: params
  defp current_params(_socket), do: %{}

  defp prefill_from_item(params, nil), do: params

  defp prefill_from_item(params, item) do
    params
    |> put_if_blank("generic_name", item.generic_name)
    |> put_if_blank("brand_name", item.brand_name)
    |> put_if_blank("strength", item.strength)
    |> put_if_blank("uom", item.uom)
  end

  defp put_if_blank(params, key, value) do
    case {Map.get(params, key), value} do
      {existing, _} when existing not in [nil, ""] -> params
      {_, nil} -> params
      {_, ""} -> params
      {_, value} -> Map.put(params, key, value)
    end
  end

  # Accepts a GS1 element string (with or without parentheses / FNC1), a raw
  # `01`-prefixed AI, or a bare EAN/UPC, and returns the 8-14 digit GTIN.
  defp parse_gtin(nil), do: :error

  defp parse_gtin(value) when is_binary(value) do
    trimmed = String.trim(value)

    cond do
      match = Regex.run(~r/\(01\)(\d{14})/, trimmed) -> {:ok, Enum.at(match, 1)}
      match = Regex.run(~r/^01(\d{14})/, trimmed) -> {:ok, Enum.at(match, 1)}
      true -> parse_bare_digits(trimmed)
    end
  end

  defp parse_gtin(_value), do: :error

  defp parse_bare_digits(value) do
    digits = String.replace(value, ~r/\D/, "")

    if String.length(digits) in [8, 12, 13, 14] do
      {:ok, digits}
    else
      :error
    end
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
