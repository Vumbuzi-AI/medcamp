defmodule MedcampWeb.MedicalCampPages.DoctorNoteShow do
  use MedcampWeb, :live_view

  alias MedcampWeb.PublicTenant
  alias Medcamp.DoctorNotes
  alias Medcamp.LabResults
  alias Medcamp.DrugAllocations
  alias Medcamp.DrugAllocations.DrugAllocation
  alias Medcamp.Accounts

  @impl true
  def mount(%{"gsrn" => gsrn, "note_id" => note_id}, session, socket) do
    patient = PublicTenant.resolve_patient!(gsrn)
    doctor_note = DoctorNotes.get_doctor_note!(note_id)

    current_user =
      case session["user_token"] do
        nil -> nil
        token -> Accounts.get_user_by_session_token(token)
      end

    lab_results = LabResults.list_lab_results_for_doctor_note(note_id)
    drug_allocations = DrugAllocations.list_drug_allocations_for_a_doctor_note(note_id)

    {:ok,
     socket
     |> assign(:patient, patient)
     |> assign(:doctor_note, doctor_note)
     |> assign(:current_user, current_user)
     |> assign(:form, to_form(DoctorNotes.change_doctor_note(doctor_note)))
     |> assign(:active_tab, :overview)
     |> assign(:back_url, nil)
     |> assign(:page_title, "Doctor Note")
     |> assign(:editing, false)
     |> assign(:lab_results, lab_results)
     |> assign(:drug_allocations, drug_allocations)
     |> assign(:show_lab_modal, false)
     |> assign(:show_pharmacy_modal, false)
     |> assign(:show_gsrn_modal, false)
     |> assign(:current_gsrn_test, nil)
     |> assign(:current_gsrn_lab_result, nil)
     |> assign(:drug_allocation, %DrugAllocation{})
     |> assign(:show_scanner, false)}
  end

  @impl true
  def handle_event("toggle_edit", _, socket) do
    {:noreply, assign(socket, :editing, !socket.assigns.editing)}
  end

  def handle_event("validate", %{"doctor_note" => params}, socket) do
    changeset = DoctorNotes.change_doctor_note(socket.assigns.doctor_note, params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"doctor_note" => params}, socket) do
    params =
      params
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> Map.put("doctor_id", socket.assigns.doctor_note.doctor_id)

    case DoctorNotes.update_doctor_note(socket.assigns.doctor_note, params) do
      {:ok, note} ->
        {:noreply,
         socket
         |> assign(:doctor_note, note)
         |> assign(:form, to_form(DoctorNotes.change_doctor_note(note)))
         |> assign(:editing, false)
         |> put_flash(:info, "Doctor note updated successfully")
         |> push_event("draft_saved", %{})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("open_lab_modal", _, socket) do
    {:noreply, assign(socket, :show_lab_modal, true)}
  end

  def handle_event("open_scanner", _, socket) do
    {:noreply, assign(socket, :show_scanner, true)}
  end

  def handle_event("close_scanner", _, socket) do
    {:noreply, assign(socket, :show_scanner, false)}
  end

  def handle_event("qr_scanned", %{"value" => raw_value}, socket) do
    gsrn = extract_gsrn(raw_value)

    case PublicTenant.resolve_patient!(gsrn) do
      nil ->
        {:noreply,
         socket
         |> assign(:show_scanner, false)
         |> put_flash(:error, "Patient not found for scanned QR code")}

      patient ->
        {:noreply,
         socket
         |> push_navigate(to: "/8018/#{patient.gsrn}/medical-camp/doctor_notes")}
    end
  end

  def handle_event("close_lab_modal", _, socket) do
    {:noreply, assign(socket, :show_lab_modal, false)}
  end

  def handle_event("open_pharmacy_modal", _, socket) do
    {:noreply, assign(socket, show_pharmacy_modal: true, drug_allocation: %DrugAllocation{})}
  end

  def handle_event("close_pharmacy_modal", _, socket) do
    {:noreply, assign(socket, :show_pharmacy_modal, false)}
  end

  def handle_event(
        "print_gsrn",
        %{"lab_result_id" => lab_result_id, "test_index" => test_index},
        socket
      ) do
    lab_result = Enum.find(socket.assigns.lab_results, &(to_string(&1.id) == lab_result_id))
    test_index = String.to_integer(test_index)
    test = Enum.at(lab_result.tests, test_index)

    {:noreply,
     socket
     |> assign(:show_gsrn_modal, true)
     |> assign(:current_gsrn_test, test)
     |> assign(:current_gsrn_lab_result, lab_result)}
  end

  def handle_event("close_gsrn_modal", _, socket) do
    {:noreply,
     socket
     |> assign(:show_gsrn_modal, false)
     |> assign(:current_gsrn_test, nil)
     |> assign(:current_gsrn_lab_result, nil)}
  end

  def handle_event(
        "delete_drug_assigned",
        %{"id" => id, "drug_allocation_id" => drug_allocation_id},
        socket
      ) do
    drug_allocation = DrugAllocations.get_drug_allocation!(drug_allocation_id)

    case DrugAllocations.remove_drug_assigned(drug_allocation, id) do
      {:ok, _updated_allocation} ->
        {:noreply,
         socket
         |> assign(
           :drug_allocations,
           DrugAllocations.list_drug_allocations_for_a_doctor_note(socket.assigns.doctor_note.id)
         )
         |> put_flash(:info, "Drug removed successfully")}

      {:error, :already_dispensed} ->
        {:noreply,
         put_flash(socket, :error, "You cannot delete a drug that has already been given")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to remove drug")}
    end
  end

  def handle_event("remove_drug_allocation", %{"id" => id}, socket) do
    drug_allocation = DrugAllocations.get_drug_allocation!(id)

    case DrugAllocations.delete_drug_allocation(drug_allocation) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(
           :drug_allocations,
           DrugAllocations.list_drug_allocations_for_a_doctor_note(socket.assigns.doctor_note.id)
         )
         |> put_flash(:info, "Drug allocation deleted successfully")}

      {:error, :dispensed_drugs} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "You cannot delete a prescription after any drug has been given"
         )}

      {:error, :paid_prescription} ->
        {:noreply, put_flash(socket, :error, "You cannot delete a paid prescription")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Failed to delete prescription")}
    end
  end

  @impl true
  def handle_info({:lab_order_saved}, socket) do
    note_id = socket.assigns.doctor_note.id

    {:noreply,
     socket
     |> assign(:show_lab_modal, false)
     |> put_flash(:info, "Lab order submitted successfully")
     |> assign(:lab_results, LabResults.list_lab_results_for_doctor_note(note_id))}
  end

  def handle_info({:drug_allocation_saved}, socket) do
    note_id = socket.assigns.doctor_note.id

    {:noreply,
     socket
     |> assign(:show_pharmacy_modal, false)
     |> put_flash(:info, "Drug prescription saved successfully")
     |> assign(
       :drug_allocations,
       DrugAllocations.list_drug_allocations_for_a_doctor_note(note_id)
     )}
  end

  defp extract_gsrn(qr_code_value) do
    cond do
      String.starts_with?(qr_code_value, "https://") ->
        parts = String.split(qr_code_value, "/")
        idx = Enum.find_index(parts, &(&1 == "8018"))
        if idx, do: Enum.at(parts, idx + 1, ""), else: List.last(parts)

      String.starts_with?(qr_code_value, "8018") ->
        String.slice(qr_code_value, 4..-1//-1)

      true ->
        qr_code_value
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full space-y-6">
      <%!-- Header --%>
      <div class="flex items-center justify-between">
        <div>
          <h1 class="text-xl font-semibold text-brand-primary">Doctor's Note</h1>
          <p class="text-sm text-slate-500 mt-0.5">
            {Calendar.strftime(@doctor_note.date, "%d %b %Y")}
            <span :if={@doctor_note.time} class="ml-1">
              · {@doctor_note.time |> Time.to_string() |> String.slice(0..4)}
            </span>
          </p>
        </div>
        <button
          :if={!@editing}
          type="button"
          phx-click="toggle_edit"
          class="inline-flex items-center gap-1.5 rounded-lg border border-brand-accent px-3 py-1.5 text-sm font-medium text-brand-accent hover:bg-brand-50 transition-colors"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
            />
          </svg>
          Edit
        </button>
      </div>

      <%!-- Read-only cards --%>
      <div :if={!@editing} class="bg-white rounded-lg shadow-sm border border-slate-200 p-5 space-y-4">
        <.note_field label="Complaints" value={@doctor_note.reason_for_consulatation} />
        <.note_field label="Clinical Notes" value={@doctor_note.clinical_notes} />
        <.note_field
          label="Past Medical & Surgical History"
          value={@doctor_note.past_medical_history}
        />
        <.note_field label="Examinations" value={@doctor_note.symptoms} />
        <.note_field label="Impression" value={@doctor_note.impression} />
        <.note_field label="Management" value={@doctor_note.management} />
        <.note_field label="Investigations" value={@doctor_note.investigations} />
        <.note_field
          :if={@doctor_note.diagnosis_icd_code}
          label="ICD-11 Code"
          value={@doctor_note.diagnosis_icd_code}
        />
        <.note_field label="Diagnosis Notes" value={@doctor_note.diagnosis} />
        <.note_field
          :if={@patient.gender == "Female"}
          label="Last Period Date"
          value={@doctor_note.last_period_date && to_string(@doctor_note.last_period_date)}
        />

        <div class="pt-3 border-t border-slate-100 flex justify-end">
          <button
            type="button"
            phx-click="toggle_edit"
            class="inline-flex items-center gap-2 rounded-lg bg-brand-primary px-4 py-2 text-sm font-semibold text-white hover:bg-[#2a2b73] transition-colors"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-4 w-4"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z"
              />
            </svg>
            Edit Note
          </button>
        </div>
      </div>

      <%!-- Edit form --%>
      <div :if={@editing} class="space-y-4">
        <div class="flex justify-end">
          <button
            type="button"
            phx-click="toggle_edit"
            class="text-sm text-slate-500 hover:text-slate-700"
          >
            Cancel
          </button>
        </div>
        <.doctor_notes_form
          patient={@patient}
          form={@form}
          show_lab_imaging_request={false}
          draft_key={"doctor_note:#{@patient.id}:#{@doctor_note.id}"}
        />
      </div>

      <%!-- Lab Orders Section --%>
      <div class="bg-white rounded-lg shadow-sm border border-slate-200 overflow-hidden">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 px-4 sm:px-6 py-4 border-b border-slate-100">
          <h2 class="text-lg font-semibold text-brand-primary flex items-center gap-2">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 text-brand-accent"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M9 17V7m0 10a2 2 0 01-2 2H5a2 2 0 01-2-2V7a2 2 0 012-2h2a2 2 0 012 2m0 10a2 2 0 002 2h2a2 2 0 002-2M9 7a2 2 0 012-2h2a2 2 0 012 2m0 10V7m0 10a2 2 0 002 2h2a2 2 0 002-2V7a2 2 0 00-2-2h-2a2 2 0 00-2 2"
              />
            </svg>
            Lab Orders
          </h2>
          <button
            type="button"
            phx-click="open_lab_modal"
            class="inline-flex items-center gap-2 rounded-lg bg-brand-accent px-3 py-1.5 text-sm font-semibold text-white hover:bg-brand-accent-dark"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-4 w-4"
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
            Order Lab Test
          </button>
        </div>

        <%!-- Same lab results display as regular doctor note page --%>
        <.lab_results_card lab_results={@lab_results} note_path={nil} />

        <%!-- Print stickers for each lab result --%>
        <%= if not Enum.empty?(@lab_results) do %>
          <div class="px-4 sm:px-6 pb-4 space-y-3">
            <p class="text-xs font-semibold text-slate-500 uppercase tracking-wide">Print Stickers</p>
            <%= for lr <- @lab_results do %>
              <div class="flex flex-wrap gap-2">
                <%= for {test, index} <- Enum.with_index(lr.tests) do %>
                  <button
                    type="button"
                    phx-click="print_gsrn"
                    phx-value-lab_result_id={lr.id}
                    phx-value-test_index={index}
                    class="flex items-center gap-1 px-2 py-1 text-xs rounded-lg bg-amber-100 text-amber-800 border border-amber-300 hover:bg-amber-200 transition-colors"
                  >
                    <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"
                      />
                    </svg>
                    <span>{test.name}</span>
                  </button>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>

      <%!-- Pharmacy / Drug Allocations Section --%>
      <div class="bg-white rounded-lg shadow-sm border border-slate-200 p-4 sm:p-6">
        <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-4 pb-2 border-b border-slate-100">
          <h2 class="text-lg font-semibold text-brand-primary flex items-center gap-2">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 text-brand-accent"
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
            Pharmacy Prescriptions
          </h2>
          <button
            type="button"
            phx-click="open_pharmacy_modal"
            class="inline-flex items-center gap-2 rounded-lg bg-brand-accent px-3 py-1.5 text-sm font-semibold text-white hover:bg-brand-accent-dark"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-4 w-4"
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
          </button>
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
              No medications have been prescribed for this note yet.
            </p>
          </div>
        <% else %>
          <div class="space-y-4">
            <%= for da <- @drug_allocations do %>
              <.drug_allocation_card
                patient={@patient}
                doctor_note={@doctor_note}
                drug_allocation={da}
              />
            <% end %>
          </div>
        <% end %>
      </div>

      <%!-- Scan Next Patient --%>
      <div class="bg-white rounded-lg shadow-sm border border-slate-200 p-4 sm:p-6">
        <%!-- <button
          :if={!@show_scanner}
          type="button"
          phx-click="open_scanner"
          class="w-full inline-flex items-center justify-center gap-3 rounded-lg bg-brand-primary px-6 py-4 text-lg font-semibold text-white hover:bg-[#2a2b73] transition-colors"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            class="h-6 w-6"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z"
            />
          </svg>
          Scan Next Patient
        </button> --%>

        <div :if={@show_scanner}>
          <div class="flex items-center justify-between mb-3">
            <h2 class="text-lg font-semibold text-brand-primary">Scan Next Patient</h2>
            <button
              type="button"
              phx-click="close_scanner"
              class="text-slate-400 hover:text-slate-600"
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
          <div id="qr-camera-scanner" phx-hook="QrCameraScanner" class="relative">
            <video class="w-full rounded-lg border border-slate-300" autoplay playsinline muted>
            </video>
            <div class="qr-overlay hidden absolute inset-0 bg-green-500/20 rounded-lg items-center justify-center">
              <svg
                class="h-16 w-16 text-green-600"
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
            </div>
            <p class="qr-status text-sm text-center text-slate-500 mt-2">
              Point camera at patient's QR code...
            </p>
          </div>
        </div>
      </div>

      <%!-- Lab Order Modal --%>
      <.modal :if={@show_lab_modal} id="lab-order-modal" show on_cancel={JS.push("close_lab_modal")}>
        <.live_component
          module={MedcampWeb.MedicalCampPages.LabOrderComponent}
          id="camp-lab-order"
          patient={@patient}
          current_user={@current_user}
          doctor_note_id={@doctor_note.id}
        />
      </.modal>

      <%!-- Print GSRN Sticker Modal --%>
      <.modal
        :if={@show_gsrn_modal && @current_gsrn_test}
        id="print-gsrn-modal"
        show
        on_cancel={JS.push("close_gsrn_modal")}
      >
        <.live_component
          module={MedcampWeb.LabPagesLabResultLive.GsrnPrintComponent}
          id={:print_gsrn}
          patient={@patient}
          lab_result={@current_gsrn_lab_result}
          test={@current_gsrn_test}
        />
      </.modal>

      <%!-- Pharmacy Modal --%>
      <.modal
        :if={@show_pharmacy_modal}
        id="pharmacy-modal"
        show
        on_cancel={JS.push("close_pharmacy_modal")}
      >
        <.live_component
          module={MedcampWeb.PrescribeMedicineComponent}
          id="camp-prescribe-medicine"
          title="Prescribe Medicine"
          action={:prescribe_drug}
          drug_allocation={@drug_allocation}
          patient={@patient}
          current_user={@current_user}
          doctor_note={@doctor_note}
          return_url={"/8018/#{@patient.gsrn}/medical-camp/doctor_notes/#{@doctor_note.id}"}
          patch={"/8018/#{@patient.gsrn}/medical-camp/doctor_notes/#{@doctor_note.id}"}
        />
      </.modal>
    </div>
    """
  end

  defp note_field(assigns) do
    ~H"""
    <div :if={@value && @value != ""} class="border-b border-slate-100 pb-3 last:border-0 last:pb-0">
      <p class="text-xs font-semibold text-slate-400 uppercase tracking-wide mb-1">{@label}</p>
      <p class="text-sm text-slate-800 whitespace-pre-wrap">{@value}</p>
    </div>
    """
  end
end
