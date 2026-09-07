defmodule MedcampWeb.PharmacistsLive.PendingDrugBatchesScan do
  use MedcampWeb, :live_component

  @moduledoc """
  Confirms a drug batch by scanning the pack's GS1 DataMatrix.

  The scanner types the raw DataMatrix payload into the field; the GTIN and
  batch/lot are parsed out of it and matched against the batch the pharmacist
  keyed in. Only a match confirms the batch, which is what makes the batch
  dispensable - so a mis-keyed batch number is caught here rather than at the
  point of handing drugs to a patient.
  """

  alias Medcamp.Batches
  alias Medcamp.InventoriesReceived
  alias Medcamp.DrugBatches

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Scan Drug Batch to Confirm ({@drug_batch.drug.brand_name} - Batch {@drug_batch.batch.batch})
      </.header>

      <.simple_form
        for={%{}}
        id="drug-batch-scan-form"
        phx-target={@myself}
        phx-submit="save_gtin"
        phx-change="save_gtin"
      >
        <.input type="text" name="scan[gtin]" value={@gtin} label="Scan DataMatrix" />

        <p :if={@error} class="text-red-500 text-sm mt-2">
          {@error}
        </p>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign(:gtin, "")
     |> assign(:error, nil)}
  end

  @impl true
  def handle_event("save_gtin", %{"scan" => %{"gtin" => scanned}}, socket) do
    gtin = InventoriesReceived.strip_first_three_take_13(scanned)
    batch_number = InventoriesReceived.extract_batch(scanned)

    case Batches.get_batch_by_gtin_and_batch(gtin, batch_number) do
      nil ->
        {:noreply,
         socket
         |> assign(:gtin, scanned)
         |> assign(:error, "No batch found for the scanned GTIN and batch number.")}

      batch ->
        confirm_batch(socket, batch, scanned)
    end
  end

  defp confirm_batch(socket, batch, scanned) do
    drug_batch = socket.assigns.drug_batch

    if batch.id != drug_batch.batch_id do
      {:noreply,
       socket
       |> assign(:gtin, scanned)
       |> assign(
         :error,
         "That pack belongs to a different batch than the one being confirmed."
       )}
    else
      {:ok, _} =
        DrugBatches.update_drug_batch(drug_batch, %{
          is_confirmed: true,
          confirmed_by: socket.assigns.current_user.id
        })

      {:noreply,
       socket
       |> put_flash(:info, "Batch confirmed successfully")
       |> push_navigate(to: socket.assigns.patch)}
    end
  end
end
