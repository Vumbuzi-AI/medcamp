defmodule MedcampWeb.DrugAllocationComponents do
  use Phoenix.Component
  use Gettext, backend: MedcampWeb.Gettext
  import MedcampWeb.CoreComponents

  def drug_allocations_section(assigns) do
    ~H"""
    <div class="bg-white mt-4 rounded-lg shadow border border-slate-200 overflow-hidden">
      <div class="px-6 py-4 bg-brand-50 border-b border-slate-200">
        <h2 class="text-xl font-semibold text-brand-primary">Drug Prescriptions</h2>
      </div>

      <div class="p-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-brand-primary">Patient Medications</h3>

          <.link patch={"/doctor/patients/#{@patient.id}/notes/#{@doctor_note.id}/prescribe_drug?tab=medication&subtab=admission"}>
            <.button class="bg-brand-accent hover:bg-brand-accent-dark">
              <span class="flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-1"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4v16m8-8H4"
                  />
                </svg>
                Prescribe Medicine
              </span>
            </.button>
          </.link>
        </div>

        <%= if Enum.empty?(@drug_allocations) do %>
          <div class="text-center py-8 bg-slate-50 rounded-lg border border-dashed border-slate-300">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="mx-auto h-12 w-12 text-slate-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"
              />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-slate-900">No medications</h3>
            <p class="mt-1 text-sm text-slate-500">
              No medications have been prescribed for this patient yet.
            </p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for drug_allocation <- @drug_allocations do %>
              <.drug_allocation_card
                add_drug_path={"/doctor/patients/#{@patient.id}/notes/#{@doctor_note.id}/assign_new_drug/#{drug_allocation.id}?tab=medication&subtab=admission"}
                patient={@patient}
                doctor_note={@doctor_note}
                drug_allocation={drug_allocation}
              />
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def drug_allocations_section_for_nurse(assigns) do
    ~H"""
    <div class="bg-white mt-4 rounded-lg shadow border border-slate-200 overflow-hidden">
      <div class="px-6 py-4 bg-brand-50 border-b border-slate-200">
        <h2 class="text-xl font-semibold text-brand-primary">Drug Prescriptions</h2>
      </div>

      <div class="p-6">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-lg font-semibold text-brand-primary">Patient Medications</h3>
        </div>

        <%= if Enum.empty?(@drug_allocations) do %>
          <div class="text-center py-8 bg-slate-50 rounded-lg border border-dashed border-slate-300">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="mx-auto h-12 w-12 text-slate-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"
              />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-slate-900">No medications</h3>
            <p class="mt-1 text-sm text-slate-500">
              No medications have been prescribed for this patient yet.
            </p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for drug_allocation <- @drug_allocations do %>
              <.drug_allocation_card
                patient={@patient}
                doctor_note={@doctor_note}
                drug_allocation={drug_allocation}
              />
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def drug_allocation_card(assigns) do
    ~H"""
    <div class="border border-slate-200 rounded-lg overflow-hidden mb-4">
      <div class="px-4 py-3 bg-slate-50 border-b border-slate-200">
        <div class="mb-4">
          <div class="w-[100%] flex justify-between items-center">
            <h4 class="font-medium text-brand-primary">Prescription from Doctor</h4>

            <button
              :if={
                @drug_allocation.has_paid == false and
                  not Medcamp.DrugAllocations.prescription_has_dispensed_drugs?(@drug_allocation)
              }
              type="button"
              class="text-red-500 hover:text-red-700"
              phx-click="remove_drug_allocation"
              data-confirm-message="Are you sure you want to delete this prescription? This action cannot be undone."
              phx-value-id={@drug_allocation.id}
            >
              Delete Prescription <.icon name="hero-trash" class="h-5 w-5" />
            </button>
          </div>
          <div class="p-3 mt-2 bg-[#f8f8ff] rounded-lg border border-brand-100 whitespace-pre-line text-slate-800">
            {@drug_allocation.prescription}
          </div>
        </div>
      </div>

      <div class="p-4">
        <div class="flex justify-between items-center mb-4">
          <h3 class="text-md font-semibold text-brand-primary">Drugs Assigned</h3>
          <.link :if={assigns[:add_drug_path]} patch={@add_drug_path}>
            <.button class="bg-brand-accent hover:bg-brand-accent-dark">
              <span class="flex items-center">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="h-4 w-4 mr-1"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 4v16m8-8H4"
                  />
                </svg>
                Add Drug
              </span>
            </.button>
          </.link>
        </div>

        <%= if Enum.empty?(@drug_allocation.drugs_assigned) do %>
          <div class="text-center py-6 bg-slate-50 rounded-lg border border-dashed border-slate-300">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="mx-auto h-10 w-10 text-slate-400"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"
              />
            </svg>
            <h3 class="mt-2 text-sm font-medium text-slate-900">No drugs assigned</h3>
            <p class="mt-1 text-sm text-slate-500">
              Click "Add Drug" to assign medications to this prescription.
            </p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for drug_assigned <- @drug_allocation.drugs_assigned do %>
              <div class="border border-slate-200 rounded-lg overflow-hidden">
                <div class="px-4 py-3 bg-slate-50 border-b border-slate-200 flex justify-between items-start">
                  <div>
                    <h4 class="font-medium text-slate-900">
                      {Medcamp.InventoriesReceived.get_inventory_received!(
                        drug_assigned.inventory_received_id
                      ).strength} {Medcamp.InventoriesReceived.get_inventory_received!(
                        drug_assigned.inventory_received_id
                      ).weight} {Medcamp.InventoriesReceived.get_inventory_received!(
                        drug_assigned.inventory_received_id
                      ).uom} {drug_assigned.brand_name}
                    </h4>
                    <p class="text-sm text-slate-600">{drug_assigned.generic_name}</p>
                  </div>
                  <div class="flex items-center space-x-2">
                    <span class="px-2 py-1 bg-brand-50 text-brand-primary rounded-full text-sm">
                      {drug_assigned.route_of_administration}
                    </span>
                    <%= if !drug_assigned.has_been_given do %>
                      <button
                        type="button"
                        phx-click="delete_drug_assigned"
                        data-confirm-message="Are you sure?"
                        phx-value-id={drug_assigned.id}
                        phx-value-drug_allocation_id={@drug_allocation.id}
                        class="text-red-500 flex gap-2 items-center hover:text-red-700"
                      >
                        <p>
                          Delete Drug
                        </p>
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-5 w-5"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                          />
                        </svg>
                      </button>
                    <% end %>
                  </div>
                </div>

                <div class="p-4">
                  <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-3">
                    <div class="bg-slate-50 rounded p-3 border border-slate-100">
                      <p class="text-xs text-slate-500 uppercase font-semibold">Quantity</p>
                      <p class="font-medium text-slate-900">
                        {drug_assigned.quantity} {drug_assigned.unit_of_measurement}
                      </p>
                    </div>

                    <div class="bg-slate-50 rounded p-3 border border-slate-100">
                      <p class="text-xs text-slate-500 uppercase font-semibold">Frequency</p>
                      <p class="font-medium text-slate-900">{drug_assigned.frequency}</p>
                    </div>

                    <div class="bg-slate-50 rounded p-3 border border-slate-100">
                      <p class="text-xs text-slate-500 uppercase font-semibold">Duration</p>
                      <p class="font-medium text-slate-900">{drug_assigned.duration_in_days} days</p>
                    </div>

                    <div class="bg-slate-50 rounded p-3 border border-slate-100">
                      <p class="text-xs text-slate-500 uppercase font-semibold">Prescription Note</p>
                      <p class="font-medium text-slate-900">
                        {drug_assigned.prescription_note || "None"}
                      </p>
                    </div>

                    <div class="bg-slate-50 rounded p-3 border border-slate-100">
                      <p class="text-xs text-slate-500 uppercase font-semibold">Price</p>
                      <p class="font-medium text-slate-900">KSh {drug_assigned.price}</p>
                    </div>
                  </div>

                  <div class="mt-4 flex justify-end">
                    <%= if drug_assigned.has_been_given do %>
                      <span class="inline-flex items-center px-3 py-2 text-sm font-medium text-green-700 bg-green-100 rounded-md">
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4 mr-1"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M5 13l4 4L19 7"
                          />
                        </svg>
                        Already Given
                      </span>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  attr :drug, :any, required: true

  def available_batches_preview(assigns) do
    batches =
      assigns.drug.drug_batches
      |> List.wrap()
      |> Medcamp.DrugBatches.sort_active_batches_by_expiry()

    assigns = assign(assigns, :available_batches, batches)

    ~H"""
    <div
      :if={@available_batches != []}
      class="mt-2 rounded-md border border-amber-100 bg-amber-50/70 p-3"
    >
      <div class="flex items-center justify-between gap-2">
        <p class="text-xs font-semibold uppercase tracking-wide text-amber-700">
          Available Batches
        </p>
        <p class="text-xs text-amber-700">Earliest expiry first</p>
      </div>

      <div class="mt-2 space-y-2">
        <div
          :for={{drug_batch, index} <- Enum.with_index(@available_batches)}
          class="rounded-md bg-white px-3 py-2 ring-1 ring-amber-100"
        >
          <div class="flex items-center justify-between gap-3">
            <div>
              <p class="text-sm font-medium text-slate-900">
                Batch {(drug_batch.batch && drug_batch.batch.batch) || "N/A"}
              </p>
              <p class="text-xs text-slate-600">
                Expires {(drug_batch.batch && drug_batch.batch.expiry) || "Unknown"}
              </p>
            </div>

            <span
              :if={index == 0}
              class="inline-flex items-center rounded-full bg-green-100 px-2 py-1 text-xs font-medium text-green-700"
            >
              Dispense first
            </span>
          </div>

          <div class="mt-2 flex flex-wrap gap-3 text-xs text-slate-700">
            <span>Available: {drug_batch.remaining_quantity}</span>
            <span :if={Medcamp.DrugBatches.batch_days_to_expiry(drug_batch) != nil}>
              Days to expiry: {Medcamp.DrugBatches.batch_days_to_expiry(drug_batch)}
            </span>
            <span :if={drug_batch.batch && drug_batch.batch.price_per_unit}>
              Unit price: KSh {drug_batch.batch.price_per_unit}
            </span>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def pharmacist_drug_allocation_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg border border-slate-200 overflow-hidden">
      <div class="px-4 py-5 sm:px-6 bg-blue-50 border-b border-blue-100">
        <h2 class="text-xl font-semibold text-blue-800">Drug Prescription</h2>
      </div>

      <div class="p-4 sm:p-6">
        <div class="bg-slate-50 rounded-lg p-4 mb-6 border border-slate-200">
          <h3 class="text-sm font-medium text-slate-500 mb-2">Prescription from Doctor</h3>
          <div class="p-3 bg-white rounded border">
            <p class="text-slate-800 whitespace-pre-line">{@drug_allocation.prescription}</p>
          </div>
        </div>

        <div class="mb-4">
          <h3 class="text-lg font-semibold text-blue-800 mb-4">Drugs Assigned</h3>

          <div class="space-y-6">
            <%= for drug_assigned <- @drug_allocation.drugs_assigned do %>
              <div class="border border-slate-200 rounded-lg overflow-hidden">
                <div class="px-4 py-3 bg-slate-50 border-b flex justify-between items-center">
                  <div>
                    <h4 class="font-medium text-slate-900">
                      {Medcamp.InventoriesReceived.get_inventory_received!(
                        drug_assigned.inventory_received_id
                      ).strength} {Medcamp.InventoriesReceived.get_inventory_received!(
                        drug_assigned.inventory_received_id
                      ).weight} {Medcamp.InventoriesReceived.get_inventory_received!(
                        drug_assigned.inventory_received_id
                      ).uom} {drug_assigned.brand_name}
                    </h4>
                    <p class="text-sm text-slate-600">{drug_assigned.generic_name}</p>
                  </div>
                  <span class="px-2 py-1 bg-blue-100 text-blue-800 rounded-full text-sm">
                    {drug_assigned.route_of_administration}
                  </span>
                </div>

                <div class="p-5 sm:p-6">
                  <div class="grid grid-cols-2 gap-3 sm:grid-cols-4">
                    <div class="bg-slate-50 rounded-md p-3 border border-slate-100">
                      <p class="text-xs text-slate-500 uppercase font-semibold">Quantity</p>
                      <p class="font-medium text-slate-900">
                        {drug_assigned.quantity} {drug_assigned.unit_of_measurement}
                      </p>
                    </div>

                    <div class="bg-slate-50 rounded-md p-3 border border-slate-100">
                      <p class="text-xs text-slate-500 uppercase font-semibold">Frequency</p>
                      <p class="font-medium text-slate-900">{drug_assigned.frequency}</p>
                    </div>

                    <div class="bg-slate-50 rounded-md p-3 border border-slate-100">
                      <p class="text-xs text-slate-500 uppercase font-semibold">Duration</p>
                      <p class="font-medium text-slate-900">{drug_assigned.duration_in_days} days</p>
                    </div>

                    <div class="bg-slate-50 rounded-md p-3 border border-slate-100">
                      <p class="text-xs text-slate-500 uppercase font-semibold">Price</p>
                      <p class="font-medium text-slate-900">KSh {drug_assigned.price}</p>
                    </div>
                  </div>

                  <div class="mt-5 grid grid-cols-1 gap-3 md:grid-cols-2">
                    <div class="rounded-xl border border-slate-200 bg-slate-50 p-4">
                      <p class="text-xs font-bold uppercase tracking-wide text-slate-500">
                        Doctor note
                      </p>
                      <p class="mt-2 text-sm text-slate-800">
                        {drug_assigned.prescription_note || "None"}
                      </p>
                    </div>

                    <div class="rounded-xl border border-slate-200 bg-slate-50 p-4">
                      <p class="text-xs font-bold uppercase tracking-wide text-slate-500">
                        Pharmacist note
                      </p>
                      <p class="mt-2 text-sm text-slate-800">
                        {drug_assigned.pharmacist_note || "None"}
                      </p>
                    </div>
                  </div>

                  <div class="mt-5 flex flex-wrap justify-end gap-2 border-t border-slate-200 pt-4">
                    <%= if !drug_assigned.has_been_given do %>
                      <.link
                        navigate={"/pharmacist/drug_allocations/#{@drug_allocation.id}/give_drug/#{drug_assigned.id}"}
                        class="inline-flex items-center px-3 py-2 border border-green-500 text-sm leading-4 font-medium rounded-md text-white bg-green-500 hover:bg-green-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500"
                      >
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4 mr-1"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M5 13l4 4L19 7"
                          />
                        </svg>
                        Give Drug
                      </.link>
                    <% else %>
                      <span class="inline-flex items-center px-3 py-2 text-sm leading-4 font-medium rounded-md text-green-700 bg-green-100">
                        <svg
                          xmlns="http://www.w3.org/2000/svg"
                          class="h-4 w-4 mr-1"
                          fill="none"
                          viewBox="0 0 24 24"
                          stroke="currentColor"
                        >
                          <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M5 13l4 4L19 7"
                          />
                        </svg>
                        Given
                      </span>
                    <% end %>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def drugs_given_to_patient_card(assigns) do
    ~H"""
    <div class="space-y-5">
      <div class="flex flex-col gap-4 border-b border-slate-200 pb-5 sm:flex-row sm:items-center sm:justify-between">
        <div class="flex items-center">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-5 w-5 mr-2 text-brand-accent"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2"
            />
          </svg>
          <div>
            <h2 class="text-xl font-bold text-slate-900">Dispensing summary</h2>
            <p class="mt-1 text-sm text-slate-500">
              Review the prescription and issue the allocated medicines.
            </p>
          </div>
        </div>

        <.link
          :if={!@drug_allocation.has_been_assigned}
          navigate={"/pharmacist/drug_allocations/#{@drug_allocation.id}/confirm"}
        >
          <.button class="bg-brand-primary px-4 py-2.5 hover:bg-[#2d2f7d]">
            <div class="flex items-center">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-4 w-4 mr-2"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M5 13l4 4L19 7"
                />
              </svg>
              Confirm and dispense
            </div>
          </.button>
        </.link>
      </div>
      <div class="space-y-4">
        <%= for item <- @complete_drugs_info do %>
          <div class="overflow-hidden rounded-2xl border border-slate-200 bg-white">
            <div class="border-b border-slate-200 bg-slate-50 px-5 py-5 sm:px-6">
              <div class="flex justify-between items-center">
                <h3 class="text-lg font-bold text-brand-primary">
                  {item.complete_info.brand_name}
                  <span class="text-sm text-blue-600">({item.complete_info.generic_name})</span>
                </h3>
                <span class="rounded-full bg-emerald-100 px-3 py-1 text-xs font-bold text-emerald-700">
                  {item.complete_info.route_of_administration}
                </span>
              </div>
            </div>

            <div class="px-5 py-5 sm:p-6">
              <dl class="grid grid-cols-2 gap-3 sm:grid-cols-4">
                <div>
                  <dt class="text-sm font-medium text-slate-500">Quantity</dt>
                  <dd class="mt-1 text-sm text-slate-900">
                    {item.complete_info.quantity} {item.complete_info.unit_of_measurement}
                  </dd>
                </div>

                <div>
                  <dt class="text-sm font-medium text-slate-500">Price</dt>
                  <dd class="mt-1 text-sm text-slate-900">KSh {item.complete_info.price}</dd>
                </div>

                <div>
                  <dt class="text-sm font-medium text-slate-500">Frequency</dt>
                  <dd class="mt-1 text-sm text-slate-900">{item.complete_info.frequency}</dd>
                </div>

                <div>
                  <dt class="text-sm font-medium text-slate-500">Duration</dt>
                  <dd class="mt-1 text-sm text-slate-900">
                    {item.complete_info.duration_in_days} days
                  </dd>
                </div>
              </dl>

              <%= if item.complete_info.prescription_note do %>
                <div class="mt-4">
                  <h4 class="text-sm font-medium text-slate-500">Doctor Prescription Note</h4>
                  <p class="mt-1 text-sm text-slate-900 bg-slate-50 p-2 rounded">
                    {item.complete_info.prescription_note}
                  </p>
                </div>
              <% end %>

              <%= if item.complete_info.pharmacist_note do %>
                <div class="mt-4">
                  <h4 class="text-sm font-medium text-slate-500">Pharmacist Note</h4>
                  <p class="mt-1 text-sm text-slate-900 bg-slate-50 p-2 rounded">
                    {item.complete_info.pharmacist_note}
                  </p>
                </div>
              <% end %>

              <div class="border-t border-slate-200 mt-4 pt-4">
                <div class="flex justify-between items-center">
                  <div class="text-sm text-slate-500">
                    <span>Dispensed by {item.complete_info.pharmacist_name}</span>
                    <span class="block text-xs">
                      {Calendar.strftime(item.complete_info.inserted_at, "%d %b %Y, %H:%M")}
                    </span>
                  </div>

                  <div class="flex space-x-2">
                    <.link
                      navigate={"/pharmacist/drug_allocations/#{@drug_allocation.id}/print_preview/#{item.drug_given.id}"}
                      phx-click="print_prescription"
                      phx-value-id={item.drug_given.id}
                      class="inline-flex items-center px-3 py-2 border border-blue-300 text-sm leading-4 font-medium rounded-md text-blue-700 bg-white hover:bg-blue-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4 mr-1"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
                        />
                      </svg>
                      Print
                    </.link>
                    <button
                      phx-click="undo_drug_given"
                      data-confirm-message="Are you sure you want to undo this drug given?"
                      phx-value-id={item.drug_given.id}
                      class="inline-flex items-center px-3 py-2 border border-red-300 text-sm leading-4 font-medium rounded-md text-red-700 bg-white hover:bg-red-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        class="h-4 w-4 mr-1"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                      >
                        <path
                          stroke-linecap="round"
                          stroke-linejoin="round"
                          stroke-width="2"
                          d="M3 10h10a8 8 0 018 8v2M3 10l6 6m-6-6l6-6"
                        />
                      </svg>
                      Undo
                    </button>
                  </div>
                </div>
              </div>
            </div>

            <div class="border-t border-slate-100 bg-slate-50 px-5 py-5 sm:px-6">
              <h4 class="mb-3 text-sm font-bold uppercase tracking-wide text-slate-500">
                Batch allocations
              </h4>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-slate-200">
                  <thead class="bg-slate-100">
                    <tr>
                      <th
                        scope="col"
                        class="px-3 py-2 text-left text-xs font-medium text-slate-500 uppercase tracking-wider"
                      >
                        Batch
                      </th>
                      <th
                        scope="col"
                        class="px-3 py-2 text-left text-xs font-medium text-slate-500 uppercase tracking-wider"
                      >
                        GTIN
                      </th>
                      <th
                        scope="col"
                        class="px-3 py-2 text-left text-xs font-medium text-slate-500 uppercase tracking-wider"
                      >
                        Expiry Date
                      </th>
                      <th
                        scope="col"
                        class="px-3 py-2 text-left text-xs font-medium text-slate-500 uppercase tracking-wider"
                      >
                        Quantity
                      </th>
                      <th
                        scope="col"
                        class="px-3 py-2 text-left text-xs font-medium text-slate-500 uppercase tracking-wider"
                      >
                        Unit Price
                      </th>
                      <th
                        scope="col"
                        class="px-3 py-2 text-left text-xs font-medium text-slate-500 uppercase tracking-wider"
                      >
                        Subtotal
                      </th>
                      <th
                        scope="col"
                        class="px-3 py-2 text-left text-xs font-medium text-slate-500 uppercase tracking-wider"
                      >
                        Status
                      </th>
                      <th
                        scope="col"
                        class="px-3 py-2 text-left text-xs font-medium text-slate-500 uppercase tracking-wider"
                      >
                        Action
                      </th>
                    </tr>
                  </thead>
                  <tbody class="bg-white divide-y divide-slate-200">
                    <%= for allocation <- item.drug_given.batch_allocations do %>
                      <% batch = Medcamp.Batches.get_batch!(allocation.batch_id) %>
                      <% is_expired = check_if_expired(batch.expiry) %>
                      <% days_to_expiry = calculate_days_to_expiry(batch.expiry) %>

                      <tr class={if is_expired, do: "bg-red-50", else: ""}>
                        <td class="px-3 py-2 whitespace-nowrap text-xs text-slate-900">
                          <div class="flex items-center">
                            <span class="font-medium">Batch #{batch.batch}</span>
                            <%= if is_expired do %>
                              <span class="ml-2 inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-red-100 text-red-800">
                                Expired
                              </span>
                            <% end %>
                            <%= if days_to_expiry && days_to_expiry <= 30 && days_to_expiry > 0 do %>
                              <span class="ml-2 inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-yellow-100 text-yellow-800">
                                Expires Soon
                              </span>
                            <% end %>
                          </div>
                        </td>
                        <td class="px-3 py-2 whitespace-nowrap text-xs text-slate-600 font-mono">
                          {batch.gtin || (batch.inventory_received && batch.inventory_received.gtin) ||
                            "—"}
                        </td>
                        <td class="px-3 py-2 whitespace-nowrap text-xs">
                          <div class={"font-medium " <> if(is_expired, do: "text-red-600", else: if(days_to_expiry && days_to_expiry <= 30, do: "text-yellow-600", else: "text-slate-900"))}>
                            {batch.expiry}
                          </div>
                          <%= if days_to_expiry do %>
                            <div class="text-slate-500">
                              <%= cond do %>
                                <% days_to_expiry < 0 -> %>
                                  Expired {abs(days_to_expiry)} days ago
                                <% days_to_expiry == 0 -> %>
                                  Expires today
                                <% days_to_expiry <= 30 -> %>
                                  {days_to_expiry} days left
                                <% true -> %>
                                  {days_to_expiry} days left
                              <% end %>
                            </div>
                          <% end %>
                        </td>
                        <td class="px-3 py-2 whitespace-nowrap text-xs text-slate-900 font-medium">
                          {allocation.quantity}
                        </td>
                        <td class="px-3 py-2 whitespace-nowrap text-xs text-slate-900">
                          KSh {Number.Delimit.number_to_delimited(allocation.unit_price,
                            delimiter: ","
                          )}
                        </td>
                        <td class="px-3 py-2 whitespace-nowrap text-xs text-slate-900 font-medium">
                          KSh {Number.Delimit.number_to_delimited(
                            allocation.quantity * allocation.unit_price,
                            delimiter: ","
                          )}
                        </td>
                        <td class="px-3 py-2 whitespace-nowrap text-xs">
                          <%= if allocation.is_verified do %>
                            <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                              <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                                <path
                                  fill-rule="evenodd"
                                  d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
                                  clip-rule="evenodd"
                                />
                              </svg>
                              Verified
                            </span>
                          <% else %>
                            <span class="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800">
                              <svg class="w-3 h-3 mr-1" fill="currentColor" viewBox="0 0 20 20">
                                <path
                                  fill-rule="evenodd"
                                  d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z"
                                  clip-rule="evenodd"
                                />
                              </svg>
                              Pending
                            </span>
                          <% end %>
                        </td>
                        <td class="px-3 py-2 whitespace-nowrap text-xs">
                          <%= if allocation.is_verified do %>
                            <span class="text-slate-400">Verified</span>
                          <% else %>
                          <% end %>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def scan_to_verify_batch(assigns) do
    ~H"""
    <div class="fixed inset-0 z-50 overflow-y-auto">
      <div class="flex items-center justify-center min-h-screen px-4 pt-4 pb-20 text-center sm:block sm:p-0">
        <div class="fixed inset-0 transition-opacity bg-slate-500 bg-opacity-75" aria-hidden="true">
        </div>

        <span
          phx-click="close_scan_modal"
          class="hidden sm:inline-block sm:align-middle sm:h-screen"
          aria-hidden="true"
        >
          &#8203;
        </span>

        <div
          class="inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6"
          phx-click-away="close_scan_modal"
          phx-window-keydown="close_scan_modal"
          phx-key="escape"
        >
          <div>
            <div class="flex items-center justify-between mb-4">
              <h3 class="text-lg font-medium leading-6 text-slate-900">
                Verify Batch Allocation
              </h3>
              <button
                type="button"
                phx-click="close_scan_modal"
                class="text-slate-400 hover:text-slate-500"
              >
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>

            <div class="mb-4 p-4 bg-slate-50 rounded-lg">
              <div class="text-sm space-y-2">
                <div class="flex justify-between">
                  <span class="text-slate-600">Drug:</span>
                  <span class="font-medium text-slate-900">{@scan_data.drug_name}</span>
                </div>
                <div class="flex justify-between">
                  <span class="text-slate-600">Batch Number:</span>
                  <span class="font-medium text-slate-900">{@scan_data.batch_number}</span>
                </div>
                <%= if @scan_data.allocation do %>
                  <div class="flex justify-between">
                    <span class="text-slate-600">Quantity:</span>
                    <span class="font-medium text-slate-900">
                      {@scan_data.allocation.quantity}
                    </span>
                  </div>
                  <div class="flex justify-between">
                    <span class="text-slate-600">Unit Price:</span>
                    <span class="font-medium text-slate-900">
                      KSh {Number.Delimit.number_to_delimited(@scan_data.allocation.unit_price,
                        delimiter: ","
                      )}
                    </span>
                  </div>
                <% end %>
              </div>
            </div>

            <.form for={@scan_form} phx-submit="verify_allocation">
              <div class="space-y-4">
                <div>
                  <label class="block text-sm font-medium text-slate-700 mb-2">
                    Scan QR Code or Enter Batch Number
                  </label>
                  <input
                    type="text"
                    name="datamatrix"
                    placeholder="Scan QR code or enter code manually"
                    autocomplete="off"
                    autofocus
                    phx-debounce="300"
                    class="block w-full rounded-md border-slate-300 focus:border-brand-accent focus:ring-brand-accent sm:text-sm"
                  />
                </div>

                <%= if @scan_error do %>
                  <div class="rounded-md bg-red-50 p-4">
                    <div class="flex">
                      <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                        <path
                          fill-rule="evenodd"
                          d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 9.586 8.707 8.293z"
                          clip-rule="evenodd"
                        />
                      </svg>
                      <div class="ml-3">
                        <p class="text-sm text-red-800">{@scan_error}</p>
                      </div>
                    </div>
                  </div>
                <% end %>
              </div>

              <div class="mt-6 flex items-center justify-end gap-x-3">
                <button
                  type="button"
                  phx-click="close_scan_modal"
                  class="rounded-md bg-white px-3 py-2 text-sm font-semibold text-slate-900 ring-1 ring-inset ring-slate-300 hover:bg-slate-50"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  class="rounded-md bg-brand-accent px-3 py-2 text-sm font-semibold text-white hover:bg-brand-accent-dark focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-accent"
                >
                  Verify Batch
                </button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp check_if_expired(nil), do: false
  defp check_if_expired(""), do: false

  defp check_if_expired(expiry_string) when is_binary(expiry_string) do
    case Date.from_iso8601(expiry_string) do
      {:ok, expiry_date} -> Date.compare(expiry_date, Date.utc_today()) == :lt
      {:error, _} -> false
    end
  end

  defp check_if_expired(_), do: false

  defp calculate_days_to_expiry(nil), do: nil
  defp calculate_days_to_expiry(""), do: nil

  defp calculate_days_to_expiry(expiry_string) when is_binary(expiry_string) do
    case Date.from_iso8601(expiry_string) do
      {:ok, expiry_date} -> Date.diff(expiry_date, Date.utc_today())
      {:error, _} -> nil
    end
  end
end
