defmodule MedcampWeb.PharmacistsLive.DrugAllocationsShow do
  alias Medcamp.DrugsGiven.DrugGiven
  use MedcampWeb, :pharmacist_live_view

  alias Medcamp.DrugAllocations
  alias Medcamp.DrugsGiven
  alias Medcamp.DrugsGiven.DrugGiven

  alias Medcamp.Patients

  @impl true
  def mount(_, _session, socket) do
    {:ok,
     socket
     |> assign(:scan_form, to_form(%{}))
     |> assign(:scan_data, nil)
     |> assign(:scan_error, nil)
     |> assign(:view_tab, :prescription)
     |> assign(:active_tab, :drug_allocations)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    drug_allocation = DrugAllocations.get_drug_allocation!(params["id"])
    complete_drugs_info = DrugsGiven.get_complete_drugs_given_info(drug_allocation.id)
    patient = Patients.get_patient!(drug_allocation.patient_id)

    {:noreply,
     socket
     |> assign(:complete_drugs_info, complete_drugs_info)
     |> assign(:patient, patient)
     |> assign(:drug_allocation, drug_allocation)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, %{"id" => _id}) do
    socket
    |> assign(:page_title, "Listing Drug allocations")
    |> assign(:action, :index)
  end

  defp apply_action(socket, :confirm, %{"id" => _id}) do
    socket
    |> assign(:page_title, "Confirm Drug allocations")
    |> assign(:action, :confirm)
  end

  defp apply_action(socket, :print_preview, %{"drug_given_id" => id}) do
    complete_info =
      DrugsGiven.get_complete_drug_given_info_for_a_drug_given(
        id,
        socket.assigns.drug_allocation.id
      ).complete_info

    socket
    |> assign(:page_title, "Print Preview")
    |> assign(:complete_info, complete_info)
    |> assign(:action, :print_preview)
  end

  defp apply_action(socket, :new, %{"id" => _id}) do
    socket
    |> assign(:page_title, "Add New Drug To Patient")
    |> assign(:drug_given, %DrugGiven{})
    |> assign(:action, :new)
  end

  defp apply_action(socket, :edit, %{"id" => _id, "drug_given_id" => drug_given_id}) do
    drug_given = DrugsGiven.get_drug_given!(drug_given_id)

    socket
    |> assign(:page_title, "Edit Drug You want to give to patient")
    |> assign(:action, :edit)
    |> assign(:drug_given, drug_given)
  end

  defp apply_action(socket, :give_drug, %{"id" => _id, "drug_assigned_id" => drug_assigned_id}) do
    drug_assigned =
      socket.assigns.drug_allocation.drugs_assigned
      |> Enum.find(fn x -> x.id == drug_assigned_id end)

    socket
    |> assign(:page_title, "Edit Drug You want to give to patient")
    |> assign(:action, :give_drug)
    |> assign(:drug_assigned, drug_assigned)
  end

  # Tab switch event
  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :view_tab, String.to_atom(tab))}
  end

  def handle_event("show_scan_modal", params, socket) do
    batch_id = params["batch-id"]
    batch_number = params["batch-number"]
    drug_name = params["drug-name"]
    drug_given_id = params["drug-given-id"]

    drug_given = DrugsGiven.get_drug_given!(drug_given_id)

    allocation =
      Enum.find(drug_given.batch_allocations, fn alloc ->
        to_string(alloc.batch_id) == batch_id
      end)

    {:noreply,
     socket
     |> assign(:live_action, :verify_batch)
     |> assign(:scan_data, %{
       drug_given_id: drug_given_id,
       allocation: allocation,
       batch_id: batch_id,
       batch_number: batch_number,
       drug_name: drug_name
     })
     |> assign(:scan_error, nil)}
  end

  def handle_event("close_scan_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:scan_data, nil)
     |> assign(:scan_error, nil)
     |> assign(:live_action, nil)}
  end

  @impl true
  def handle_event("verify_allocation", %{"datamatrix" => _datamatrix}, socket) do
    scan_data = socket.assigns.scan_data
    drug_given = DrugsGiven.get_drug_given!(scan_data.drug_given_id)

    updated_allocations =
      Enum.map(drug_given.batch_allocations, fn allocation ->
        if allocation.batch_id == String.to_integer(scan_data.batch_id) do
          allocation
          |> Map.from_struct()
          |> Map.put(:is_verified, true)
        else
          allocation
          |> Map.from_struct()
        end
      end)

    attrs = %{batch_allocations: updated_allocations}

    drug_given
    |> DrugsGiven.DrugGiven.changeset(attrs)
    |> Medcamp.Repo.update()

    {:noreply,
     socket
     |> push_navigate(to: "/pharmacist/drug_allocations/#{socket.assigns.drug_allocation.id}")}
  end

  def handle_event("delete_drug_given", %{"id" => id}, socket) do
    drug_given = DrugsGiven.get_drug_given!(id)
    {:ok, _} = DrugsGiven.delete_drug_given(drug_given)

    {:noreply,
     assign(socket,
       drugs_given: DrugsGiven.list_drugs_given_for_an_allocation(drug_given.drug_allocation_id)
     )}
  end

  def handle_event(
        "give_drug",
        %{
          "brand-name" => brand_name,
          "generic-name" => generic_name,
          "inventory-received-id" => _inventory_received_id,
          "drug-assigned-id" => drug_assigned_id
        } = _params,
        socket
      ) do
    case DrugsGiven.create_drug_given_by_brand(
           socket.assigns.drug_allocation.id,
           brand_name,
           generic_name,
           socket.assigns.current_user.id,
           drug_assigned_id
         ) do
      {:ok, _} ->
        drug_allocation = DrugAllocations.get_drug_allocation!(socket.assigns.drug_allocation.id)
        complete_drugs_info = DrugsGiven.get_complete_drugs_given_info(drug_allocation.id)

        {:noreply,
         socket
         |> assign(:complete_drugs_info, complete_drugs_info)
         |> assign(:drug_allocation, drug_allocation)}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Error giving drug to patient")}
    end
  end

  def handle_event("undo_drug_given", %{"id" => id}, socket) do
    case DrugsGiven.cancel_drug_given(id) do
      {:ok, _} ->
        drug_allocation = DrugAllocations.get_drug_allocation!(socket.assigns.drug_allocation.id)
        complete_drugs_info = DrugsGiven.get_complete_drugs_given_info(drug_allocation.id)

        {:noreply,
         socket
         |> assign(:complete_drugs_info, complete_drugs_info)
         |> assign(:drug_allocation, drug_allocation)}

      _ ->
        {:noreply,
         socket
         |> put_flash(:error, "Error undoing drug given to patient")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <!-- Header -->
      <div class="flex items-center justify-between mb-4">
        <div class="flex items-center gap-3">
          <.link
            navigate="/pharmacist/drug_allocations"
            class="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
          >
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
                d="M10 19l-7-7m0 0l7-7m-7 7h18"
              />
            </svg>
          </.link>
          <h1 class="text-xl font-semibold text-[#373896]">Drug Allocation</h1>
        </div>

        <.button
          :if={@drug_allocation.has_been_assigned}
          class="inline-flex items-center justify-center gap-2 bg-green-500 hover:bg-green-600"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4 shrink-0"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
          Assigned to Patient
        </.button>
      </div>
      
    <!-- Drugs Given Section (Always visible at top) -->
      <.drugs_given_to_patient_card
        complete_drugs_info={@complete_drugs_info}
        drug_allocation={@drug_allocation}
      />
      
    <!-- Tab Navigation -->
      <div class="mt-6 border-b border-gray-200">
        <nav class="flex space-x-1" aria-label="Tabs">
          <button
            phx-click="switch_tab"
            phx-value-tab="prescription"
            class={[
              "px-6 py-3 text-sm font-medium border-b-2 transition-colors",
              if(@view_tab == :prescription,
                do: "border-[#6667ab] text-[#6667ab]",
                else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
              )
            ]}
          >
            <div class="flex items-center gap-2">
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
                  d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
                />
              </svg>
              Prescription
            </div>
          </button>

          <button
            phx-click="switch_tab"
            phx-value-tab="doctor_notes"
            disabled={@drug_allocation.doctor_note == nil}
            class={[
              "px-6 py-3 text-sm font-medium border-b-2 transition-colors",
              if(@view_tab == :doctor_notes,
                do: "border-[#6667ab] text-[#6667ab]",
                else: "border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300"
              ),
              if(@drug_allocation.doctor_note == nil, do: "opacity-50 cursor-not-allowed")
            ]}
          >
            <div class="flex items-center gap-2">
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
                  d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                />
              </svg>
              Doctor Notes
              <%= if @drug_allocation.doctor_note == nil do %>
                <span class="text-xs text-gray-400">(N/A)</span>
              <% end %>
            </div>
          </button>
        </nav>
      </div>
      
    <!-- Tab Content -->
      <div class="mt-4">
        <%= case @view_tab do %>
          <% :prescription -> %>
            <.pharmacist_drug_allocation_card drug_allocation={@drug_allocation} />
          <% :doctor_notes -> %>
            <%= if @drug_allocation.doctor_note do %>
              <.doctor_note_card doctor_note={@drug_allocation.doctor_note} />
            <% else %>
              <div class="text-center py-12 bg-gray-50 rounded-lg border border-dashed border-gray-300">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  class="mx-auto h-12 w-12 text-gray-400"
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
                <h3 class="mt-2 text-sm font-medium text-gray-900">No Doctor Notes</h3>
                <p class="mt-1 text-sm text-gray-500">
                  No clinical notes are linked to this prescription.
                </p>
              </div>
            <% end %>
        <% end %>
      </div>
      
    <!-- Modals -->
      <.modal
        :if={@action in [:edit, :new]}
        id="patient-modal"
        show
        on_cancel={JS.patch("/pharmacist/drug_allocations/#{@drug_allocation.id}")}
      >
        <.live_component
          module={MedcampWeb.DrugAllocationLive.DrugGivenFormComponent}
          id={:confirm}
          title={@page_title}
          drug_allocation={@drug_allocation}
          drug_given={@drug_given}
          action={@action}
          current_user={@current_user}
          patch={"/pharmacist/drug_allocations/#{@drug_allocation.id}"}
        />
      </.modal>

      <.modal
        :if={@action in [:confirm]}
        id="patient-modal"
        show
        on_cancel={JS.patch("/pharmacist/drug_allocations/#{@drug_allocation.id}")}
      >
        <.live_component
          module={MedcampWeb.DrugAllocationLive.ConfirmComponent}
          id={:confirm_here}
          title={@page_title}
          drug_allocation={@drug_allocation}
          patient={@patient}
          drugs_given={@complete_drugs_info}
          action={@action}
          current_user={@current_user}
          patch={"/pharmacist/drug_allocations/#{@drug_allocation.id}"}
        />
      </.modal>

      <.modal
        :if={@action in [:print_preview]}
        id="patient-modal"
        show
        on_cancel={JS.patch("/pharmacist/drug_allocations/#{@drug_allocation.id}")}
      >
        <.live_component
          module={MedcampWeb.DrugAllocationLive.PrintPreviewComponent}
          id={:confirm_here}
          title={@page_title}
          patient={@patient}
          drug_allocation={@drug_allocation}
          complete_info={@complete_info}
          patch={"/pharmacist/drug_allocations/#{@drug_allocation.id}"}
        />
      </.modal>

      <.modal
        :if={@action in [:give_drug]}
        id="patient-modal"
        show
        on_cancel={JS.patch("/pharmacist/drug_allocations/#{@drug_allocation.id}")}
      >
        <.live_component
          module={MedcampWeb.DrugAllocationLive.GiveDrugComponent}
          id={:confirm_here}
          title={@page_title}
          patient={@patient}
          drug_allocation={@drug_allocation}
          drug_assigned={@drug_assigned}
          current_user={@current_user}
          patch={"/pharmacist/drug_allocations/#{@drug_allocation.id}"}
        />
      </.modal>

      <%= if @scan_data do %>
        <.scan_to_verify_batch scan_data={@scan_data} scan_error={@scan_error} scan_form={@scan_form} />
      <% end %>
    </div>
    """
  end

  # ============================================================================
  # Doctor Note Card Component
  # ============================================================================

  defp doctor_note_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-md border border-gray-200 overflow-hidden">
      <div class="px-4 py-4 bg-gradient-to-r from-blue-50 to-indigo-50 border-b border-gray-200">
        <div class="flex items-center justify-between">
          <div class="flex items-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 mr-2 text-blue-600"
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
            <h2 class="text-lg font-semibold text-gray-800">Doctor's Clinical Notes</h2>
          </div>
          <div class="flex items-center text-sm text-gray-600">
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
                d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
              />
            </svg>
            <span>{Calendar.strftime(@doctor_note.date, "%d %b %Y")}</span>
            <%= if @doctor_note.time do %>
              <span class="ml-2">{Calendar.strftime(@doctor_note.time, "%H:%M")}</span>
            <% end %>
          </div>
        </div>
      </div>

      <div class="p-4 sm:p-6">
        <!-- Doctor Info -->
        <div class="flex items-center mb-4 pb-4 border-b border-gray-100">
          <div class="w-10 h-10 rounded-full bg-blue-100 text-blue-600 font-bold flex items-center justify-center mr-3">
            {get_initials(@doctor_note.doctor.name)}
          </div>
          <div>
            <p class="font-medium text-gray-900">Dr. {@doctor_note.doctor.name}</p>
            <p class="text-sm text-gray-500">Attending Physician</p>
          </div>
        </div>
        
    <!-- Key Clinical Info -->
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <!-- Diagnosis -->
          <%= if @doctor_note.diagnosis && @doctor_note.diagnosis != "" do %>
            <div class="bg-slate-50 rounded-lg p-4 border border-purple-100">
              <h4 class="text-sm font-semibold text-purple-800 uppercase tracking-wide mb-2 flex items-center">
                <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"
                  />
                </svg>
                Diagnosis
              </h4>
              <p class="text-gray-800 font-medium whitespace-pre-line">{@doctor_note.diagnosis}</p>
            </div>
          <% end %>
          
    <!-- Reason for Consultation -->
          <%= if @doctor_note.reason_for_consulatation && @doctor_note.reason_for_consulatation != "" do %>
            <div class="bg-blue-50 rounded-lg p-4 border border-blue-100">
              <h4 class="text-sm font-semibold text-blue-800 uppercase tracking-wide mb-2 flex items-center">
                <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                Reason for Consultation
              </h4>
              <p class="text-gray-800 whitespace-pre-line">{@doctor_note.reason_for_consulatation}</p>
            </div>
          <% end %>
          
    <!-- Symptoms -->
          <%= if @doctor_note.symptoms && @doctor_note.symptoms != "" do %>
            <div class="bg-amber-50 rounded-lg p-4 border border-amber-100">
              <h4 class="text-sm font-semibold text-amber-800 uppercase tracking-wide mb-2 flex items-center">
                <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"
                  />
                </svg>
                Presenting Symptoms
              </h4>
              <p class="text-gray-800 whitespace-pre-line">{@doctor_note.symptoms}</p>
            </div>
          <% end %>
          
    <!-- Clinical Notes -->
          <%= if @doctor_note.clinical_notes && @doctor_note.clinical_notes != "" do %>
            <div class="bg-gray-50 rounded-lg p-4 border border-gray-200">
              <h4 class="text-sm font-semibold text-gray-700 uppercase tracking-wide mb-2 flex items-center">
                <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
                  />
                </svg>
                Clinical Notes
              </h4>
              <p class="text-gray-800 whitespace-pre-line">{@doctor_note.clinical_notes}</p>
            </div>
          <% end %>
          
    <!-- Impression -->
          <%= if @doctor_note.impression && @doctor_note.impression != "" do %>
            <div class="bg-indigo-50 rounded-lg p-4 border border-indigo-100">
              <h4 class="text-sm font-semibold text-indigo-800 uppercase tracking-wide mb-2 flex items-center">
                <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"
                  />
                </svg>
                Clinical Impression
              </h4>
              <p class="text-gray-800 whitespace-pre-line">{@doctor_note.impression}</p>
            </div>
          <% end %>
        </div>
        
    <!-- Additional Info -->
        <div class="mt-4 space-y-3">
          <%= if @doctor_note.past_medical_history && @doctor_note.past_medical_history != "" do %>
            <div class="bg-red-50 rounded-lg p-3 border border-red-100">
              <h4 class="text-xs font-semibold text-red-800 uppercase tracking-wide mb-1 flex items-center">
                <svg class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
                  />
                </svg>
                Past Medical History
              </h4>
              <p class="text-sm text-gray-800 whitespace-pre-line">
                {@doctor_note.past_medical_history}
              </p>
            </div>
          <% end %>

          <%= if @doctor_note.investigations && @doctor_note.investigations != "" do %>
            <div class="bg-teal-50 rounded-lg p-3 border border-teal-100">
              <h4 class="text-xs font-semibold text-teal-800 uppercase tracking-wide mb-1 flex items-center">
                <svg class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.806.547M8 4h8l-1 1v5.172a2 2 0 00.586 1.414l5 5c1.26 1.26.367 3.414-1.415 3.414H4.828c-1.782 0-2.674-2.154-1.414-3.414l5-5A2 2 0 009 10.172V5L8 4z"
                  />
                </svg>
                Investigations
              </h4>
              <p class="text-sm text-gray-800 whitespace-pre-line">{@doctor_note.investigations}</p>
            </div>
          <% end %>

          <%= if @doctor_note.lab_imaging_request && @doctor_note.lab_imaging_request != "" do %>
            <div class="bg-sky-50 rounded-lg p-3 border border-sky-100">
              <h4 class="text-xs font-semibold text-sky-800 uppercase tracking-wide mb-1 flex items-center">
                <svg class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 17v-2m3 2v-4m3 4v-6m2 10H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
                  />
                </svg>
                Lab/Imaging Requests
              </h4>
              <p class="text-sm text-gray-800 whitespace-pre-line">
                {@doctor_note.lab_imaging_request}
              </p>
            </div>
          <% end %>

          <%= if @doctor_note.prescribed_medication && @doctor_note.prescribed_medication != "" do %>
            <div class="bg-green-50 rounded-lg p-3 border border-green-100">
              <h4 class="text-xs font-semibold text-green-800 uppercase tracking-wide mb-1 flex items-center">
                <svg class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"
                  />
                </svg>
                Prescribed Medication (Doctor's Notes)
              </h4>
              <p class="text-sm text-gray-800 whitespace-pre-line">
                {@doctor_note.prescribed_medication}
              </p>
            </div>
          <% end %>

          <%= if @doctor_note.lifestyle_recommendations && @doctor_note.lifestyle_recommendations != "" do %>
            <div class="bg-cyan-50 rounded-lg p-3 border border-cyan-100">
              <h4 class="text-xs font-semibold text-cyan-800 uppercase tracking-wide mb-1 flex items-center">
                <svg class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z"
                  />
                </svg>
                Lifestyle Recommendations
              </h4>
              <p class="text-sm text-gray-800 whitespace-pre-line">
                {@doctor_note.lifestyle_recommendations}
              </p>
            </div>
          <% end %>

          <%= if @doctor_note.last_period_date do %>
            <div class="bg-pink-50 rounded-lg p-3 border border-pink-100">
              <h4 class="text-xs font-semibold text-pink-800 uppercase tracking-wide mb-1 flex items-center">
                <svg class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"
                  />
                </svg>
                Last Period Date (LMP)
              </h4>
              <p class="text-sm text-gray-800 font-medium">
                {Calendar.strftime(@doctor_note.last_period_date, "%d %B %Y")}
              </p>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  # Helper function for initials
  defp get_initials(name) when is_binary(name) do
    name
    |> String.split(" ")
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end

  defp get_initials(_), do: "?"
end
