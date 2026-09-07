defmodule MedcampWeb.DrugAllocationLive.ConfirmComponent do
  use MedcampWeb, :live_component

  @moduledoc """
  Final check before a pharmacist hands drugs to the patient.

  Camp drugs are free, so this is a dispense confirmation rather than a
  payment gate: the pharmacist reviews what was picked and batch-scanned,
  then confirms, which marks the allocation dispensed.
  """

  alias Medcamp.DrugAllocations
  alias Medcamp.PatientVisits

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        Confirm Dispensing
      </.header>
      <div class="flex flex-col gap-2">
        <p class="mb-4 font-semibold text-darkblue">
          Drugs To be Given to Patient
        </p>

        <%= for drug_given <- @drugs_given do %>
          <div class="flex flex-col gap-3 p-4 rounded-lg shadow-md bg-white border border-gray-200 mb-4">
            <div class="border-b border-gray-200 pb-2">
              <h3 class="font-semibold text-lg text-gray-800">Drug Information</h3>
            </div>

            <div class="grid grid-cols-2 gap-2">
              <div class="flex flex-col">
                <span class="text-sm text-gray-500">Brand Name</span>
                <span class="font-medium text-gray-900">{drug_given.complete_info.brand_name}</span>
              </div>

              <div class="flex flex-col">
                <span class="text-sm text-gray-500">Generic Name</span>
                <span class="font-medium text-gray-900">{drug_given.complete_info.generic_name}</span>
              </div>

              <div class="flex flex-col">
                <span class="text-sm text-gray-500">Quantity</span>
                <span class="font-medium text-gray-900">{drug_given.complete_info.quantity}</span>
              </div>
            </div>
          </div>
        <% end %>

        <p :if={@dispense_error} class="bg-red-200 text-red-500 rounded-md p-2 w-full">
          {@dispense_error}
        </p>

        <button
          phx-click="confirm_dispense"
          phx-target={@myself}
          phx-disable-with="Dispensing..."
          class="w-full rounded-md bg-[#373896] px-4 py-2 text-sm font-semibold text-white hover:bg-[#6667ab] focus:outline-none focus:ring-2 focus:ring-[#6667ab] focus:ring-offset-2"
        >
          Confirm & Dispense
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:dispense_error, fn -> nil end)}
  end

  @impl true
  def handle_event("confirm_dispense", _params, socket) do
    drug_allocation = socket.assigns.drug_allocation

    case DrugAllocations.update_drug_allocation(drug_allocation, %{
           "has_been_assigned" => true
         }) do
      {:ok, _updated} ->
        # Pharmacy is the last stop, so handing the drugs over closes the visit.
        case PatientVisits.current_visit_for_patient(drug_allocation.patient_id) do
          nil -> :ok
          visit -> PatientVisits.mark_completed(visit)
        end

        {:noreply,
         socket
         |> put_flash(:info, "Drugs dispensed successfully.")
         |> push_navigate(to: "/pharmacist/drug_allocations/#{drug_allocation.id}")}

      {:error, _changeset} ->
        {:noreply,
         assign(socket, :dispense_error, "Failed to dispense the drugs. Please try again.")}
    end
  end
end
