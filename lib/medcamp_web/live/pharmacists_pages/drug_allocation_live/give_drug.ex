defmodule MedcampWeb.DrugAllocationLive.GiveDrugComponent do
  use MedcampWeb, :live_component
  alias Medcamp.DrugsGiven

  def render(assigns) do
    ~H"""
    <div>
      <p class="text-xl">
        Drug You Want to Assign
      </p>
      <div class="mt-4 grid grid-cols-1 gap-4 sm:grid-cols-3">
        <div class="bg-gray-50 rounded-md p-3 border border-gray-100">
          <p class="text-xs text-gray-500 uppercase font-semibold">Quantity</p>
          <p class="font-medium text-gray-900">
            {@drug_assigned.quantity} {@drug_assigned.unit_of_measurement}
          </p>
        </div>

        <div class="bg-gray-50 rounded-md p-3 border border-gray-100">
          <p class="text-xs text-gray-500 uppercase font-semibold">Frequency</p>
          <p class="font-medium text-gray-900">{@drug_assigned.frequency}</p>
        </div>

        <div class="bg-gray-50 rounded-md p-3 border border-gray-100">
          <p class="text-xs text-gray-500 uppercase font-semibold">Duration</p>
          <p class="font-medium text-gray-900">{@drug_assigned.duration_in_days} days</p>
        </div>

        <div class="bg-gray-50 rounded-md p-3 border border-gray-100">
          <p class="text-xs text-gray-500 uppercase font-semibold">Prescription Note</p>
          <p class="font-medium text-gray-900">
            {@drug_assigned.prescription_note || "None"}
          </p>
        </div>

        <div class="bg-gray-50 rounded-md p-3 border border-gray-100">
          <p class="text-xs text-gray-500 uppercase font-semibold">Price</p>
          <p class="font-medium text-gray-900">KSh {@drug_assigned.price}</p>
        </div>
        <div class="bg-gray-50 rounded-md p-3 border border-gray-100">
          <p class="text-xs text-gray-500 uppercase font-semibold">Quantity</p>
          <p class="font-medium text-gray-900">
            {@drug_assigned.quantity} {@drug_assigned.unit_of_measurement}
          </p>
        </div>
      </div>

      <form class="mt-4" phx-submit="give_drug" phx-target={@myself}>
        <textarea
          id="drug_form_pharmacist_note"
          name="drug_form[pharmacist_note]"
          placeholder="Pharmacist Note"
          value={@pharmacist_note}
          class="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
        />
        <button
          type="submit"
          class="px-4 mt-4 py-2 bg-indigo-600 hover:bg-indigo-700 rounded-md text-white"
        >
          Add Drug
        </button>
      </form>
    </div>
    """
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(:pharmacist_note, "")
     |> assign(assigns)}
  end

  def handle_event(
        "give_drug",
        %{"drug_form" => %{"pharmacist_note" => pharmacist_note}},
        socket
      ) do
    case DrugsGiven.create_drug_given_by_brand(
           socket.assigns.drug_allocation.id,
           socket.assigns.drug_assigned.brand_name,
           socket.assigns.drug_assigned.generic_name,
           socket.assigns.current_user.id,
           socket.assigns.drug_assigned.id,
           pharmacist_note
         ) do
      {:ok, _} ->
        {:noreply,
         socket
         |> push_navigate(to: socket.assigns.patch)}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to give drug to patient. Please try again.")}

      _ ->
        {:noreply,
         socket
         |> put_flash(:info, "Drug successfully given to patient.")}
    end
  end
end
