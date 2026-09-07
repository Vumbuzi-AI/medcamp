defmodule MedcampWeb.ShiftHandoverLive.FormComponent do
  use MedcampWeb, :live_component

  alias Medcamp.ShiftHandovers
  alias Medcamp.Accounts

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header class="text-[#373896] border-b border-gray-100 pb-4 mb-6">
        {@title}
        <:subtitle>
          <span class="text-gray-600">
            Document the shift handover to ensure continuity of care.
          </span>
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="shift_handover-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-6">
          <!-- Shift Information Section -->
          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-sm font-semibold text-[#373896] mb-4 flex items-center">
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
                  d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              Shift Information
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <.input
                field={@form[:shift_start]}
                type="date"
                label="Start of Shift Date"
                value={Date.add(Date.utc_today(), -3)}
                required
              />
              <.input
                field={@form[:shift_date]}
                type="date"
                label="End of Shift Date"
                value={Date.utc_today()}
                required
              />

              <.input
                field={@form[:department]}
                type="select"
                label="Department"
                options={[
                  {"Clinical Office", "Clinical Office"},
                  {"Nursing Office", "Nursing Office"},
                  {"Pharmacy", "Pharmacy"},
                  {"Laboratory", "Laboratory"},
                  {"Reception", "Reception"},
                  {"Support Staff", "Support Staff"}
                ]}
                prompt="Select department"
                required
              />
            </div>
          </div>
          
    <!-- Staff Handover Section -->
          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-sm font-semibold text-[#373896] mb-4 flex items-center">
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
                  d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"
                />
              </svg>
              Staff Handover
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <.input
                field={@form[:handover_from]}
                type="text"
                value={@current_user.name}
                readonly
                label="Handover From (Outgoing Staff)"
                placeholder="e.g., Dr. Jane Smith, Nurse John Doe"
                required
              />
              <.input
                field={@form[:handover_to]}
                type="select"
                options={@similar_users}
                prompt="Select incoming staff"
                label="Handover To (Incoming Staff)"
                placeholder="e.g., Dr. Sarah Johnson, Nurse Mike Brown"
                required
              />
            </div>
          </div>
          
    <!-- Patient Updates Section -->
          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-sm font-semibold text-[#373896] mb-4 flex items-center">
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
                  d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                />
              </svg>
              Patient Updates & Clinical Information
            </h3>
            <.input
              field={@form[:patient_updates]}
              type="textarea"
              label="Patient Updates"
              placeholder="Document any significant patient status changes, new diagnoses, treatment plan updates, or concerns..."
              rows="4"
            />
          </div>
          
    <!-- Pending Tasks Section -->
          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-sm font-semibold text-[#373896] mb-4 flex items-center">
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
                  d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
                />
              </svg>
              Pending Tasks & Follow-ups
            </h3>
            <.input
              field={@form[:pending_tasks]}
              type="textarea"
              label="Pending Tasks"
              placeholder="List any tasks that need to be completed: medication rounds, lab results to follow up, procedures scheduled, family meetings, etc..."
              rows="4"
            />
          </div>
          
    <!-- Equipment & Incidents Section -->
          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-sm font-semibold text-[#373896] mb-4 flex items-center">
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
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                />
              </svg>
              Equipment Issues & Incidents
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <.input
                field={@form[:equipment_issues]}
                type="textarea"
                label="Equipment Issues"
                placeholder="Report any equipment malfunctions, maintenance needs, or supply shortages..."
                rows="4"
              />
              <.input
                field={@form[:incidents]}
                type="textarea"
                label="Incidents/Safety Concerns"
                placeholder="Document any incidents, near misses, or safety concerns that occurred during the shift..."
                rows="4"
              />
            </div>
          </div>

          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-sm font-semibold text-[#373896] mb-4 flex items-center">
              <i class="fa fa-money mr-2"></i> Petty Cash Balance
            </h3>
            <.input
              field={@form[:petty_cash_balance]}
              type="number"
              label="Petty Cash Balance"
              placeholder="Enter the petty cash balance at the end of the shift"
            />
          </div>
          
    <!-- Cold Chain & Regulatory Logs Section -->
          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-sm font-semibold text-[#373896] mb-4 flex items-center">
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
                  d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                />
              </svg>
              Cold Chain & Regulatory Compliance
            </h3>
            <div class="space-y-4">
              <.input
                field={@form[:daily_coldchain_temperature_log]}
                type="textarea"
                label="Daily Cold Chain Temperature Log"
                placeholder="Record refrigerator/freezer temperatures for vaccines and temperature-sensitive medications (e.g., Fridge: 2-8°C ✓, Freezer: -15°C ✓)..."
                rows="3"
              />
              <.input
                field={@form[:dangerous_drug_register]}
                type="textarea"
                label="Dangerous Drug Register"
                placeholder="Document any controlled substances dispensed, administered, or wasted during shift (Drug name, quantity, patient, witness, etc.)..."
                rows="3"
              />
              <.input
                field={@form[:equipment_maintenance_log]}
                type="textarea"
                label="Equipment Maintenance Log"
                placeholder="Note any equipment maintenance performed, calibrations due, or servicing scheduled (e.g., Autoclave serviced, BP machine calibrated)..."
                rows="3"
              />
            </div>
          </div>
          
    <!-- Additional Notes Section -->
          <div class="bg-gray-50 rounded-lg p-4">
            <h3 class="text-sm font-semibold text-[#373896] mb-4 flex items-center">
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
                  d="M7 8h10M7 12h4m1 8l-4-4H5a2 2 0 01-2-2V6a2 2 0 012-2h14a2 2 0 012 2v8a2 2 0 01-2 2h-3l-4 4z"
                />
              </svg>
              Additional Notes
            </h3>
            <.input
              field={@form[:notes]}
              type="textarea"
              label="General Notes"
              placeholder="Any other information the incoming staff should know..."
              rows="3"
            />
          </div>
          
    <!-- Status Section -->
          <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <div class="flex items-start">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5 text-blue-600 mt-0.5 mr-3"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
              <div class="flex-1">
                <h4 class="text-sm font-semibold text-blue-900 mb-2">Handover Status</h4>
                <.input
                  field={@form[:status]}
                  type="select"
                  label="Status"
                  options={[
                    {"Pending - Waiting for acknowledgment", "pending"},
                    {"Acknowledged - Received by incoming staff", "acknowledged"},
                    {"Completed - Handover finalized", "completed"}
                  ]}
                  value="pending"
                />
              </div>
            </div>
          </div>
        </div>

        <:actions>
          <div class="flex items-center justify-end gap-4 pt-4 border-t border-gray-200">
            <.button
              type="button"
              phx-click={JS.patch(@patch)}
              class="bg-gray-200 hover:bg-gray-300 text-gray-700"
            >
              Cancel
            </.button>
            <.button phx-disable-with="Saving..." class="bg-[#6667ab] hover:bg-[#5556a0]">
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
                Submit Handover
              </div>
            </.button>
          </div>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{shift_handover: shift_handover} = assigns, socket) do
    similar_users = Accounts.list_poeple_in_same_department_as_current_user(assigns.current_user)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:similar_users, similar_users)
     |> assign_new(:form, fn ->
       to_form(ShiftHandovers.change_shift_handover(shift_handover))
     end)}
  end

  @impl true
  def handle_event("validate", %{"shift_handover" => shift_handover_params}, socket) do
    changeset =
      ShiftHandovers.change_shift_handover(socket.assigns.shift_handover, shift_handover_params)

    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"shift_handover" => shift_handover_params}, socket) do
    # Automatically set submitted_at if status is not pending
    params =
      if shift_handover_params["status"] != "pending" and
           is_nil(socket.assigns.shift_handover.submitted_at) do
        Map.put(shift_handover_params, "submitted_at", DateTime.utc_now())
      else
        shift_handover_params
      end

    save_shift_handover(socket, socket.assigns.action, params)
  end

  defp save_shift_handover(socket, :edit, shift_handover_params) do
    case ShiftHandovers.update_shift_handover(
           socket.assigns.shift_handover,
           shift_handover_params
         ) do
      {:ok, shift_handover} ->
        notify_parent({:saved, shift_handover})

        {:noreply,
         socket
         |> put_flash(:info, "Shift handover updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  # In the FormComponent, update the save function:

  defp save_shift_handover(socket, :new, shift_handover_params) do
    # Automatically set submitted_by_id and submitted_at
    params =
      shift_handover_params
      |> Map.put("submitted_by_id", socket.assigns.current_user.id)
      |> Map.put("submitted_at", DateTime.utc_now())

    case ShiftHandovers.create_shift_handover(params) do
      {:ok, shift_handover} ->
        notify_parent({:saved, shift_handover})

        {:noreply,
         socket
         |> put_flash(:info, "Shift handover created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
