defmodule MedcampWeb.DoctorsPages.EachPatientFormsLive do
  use MedcampWeb, :each_patient_live_view
  alias Medcamp.PatientFormRecords
  alias Medcamp.PatientFormRecords.PatientFormRecord
  alias Medcamp.Patients

  @impl true
  def mount(%{"patient_id" => patient_id}, _session, socket) do
    mount(%{"id" => patient_id}, %{}, socket)
  end

  @impl true
  def mount(%{"id" => patient_id}, _session, socket) do
    patient = Patients.get_patient!(patient_id)

    {:ok,
     socket
     |> assign(:active_tab, :forms)
     |> assign(:patient, patient)
     |> assign(:forms, PatientFormRecords.list_patient_form_records(patient_id))
     |> assign(:active_form_type, nil)
     |> assign(:form_record, nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("select_form_type", %{"form_type" => form_type}, socket) do
    {:noreply, assign(socket, :active_form_type, form_type)}
  end

  @impl true
  def handle_event("cancel_form", _, socket) do
    {:noreply, assign(socket, :active_form_type, nil)}
  end

  @impl true
  def handle_event("save", %{"patient_form_record" => params}, socket) do
    form_data = Map.get(params, "form_data", %{})

    attrs = %{
      "form_type" => params["form_type"],
      "form_data" => form_data,
      "patient_id" => socket.assigns.patient.id,
      "created_by_id" => socket.assigns.current_user.id,
      "updated_by_id" => socket.assigns.current_user.id
    }

    case PatientFormRecords.create_patient_form_record(attrs) do
      {:ok, _record} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{PatientFormRecord.form_label(params["form_type"])} saved")
         |> assign(
           :forms,
           PatientFormRecords.list_patient_form_records(socket.assigns.patient.id)
         )
         |> assign(:active_form_type, nil)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to save form. Please try again.")}
    end
  end

  @impl true
  def handle_event(
        "update_record",
        %{"record_id" => record_id, "patient_form_record" => %{"form_data" => form_data}},
        socket
      ) do
    record =
      PatientFormRecords.get_patient_form_record_for_patient!(
        socket.assigns.patient.id,
        record_id
      )

    case PatientFormRecords.update_patient_form_record(record, %{
           "form_data" => form_data,
           "updated_by_id" => socket.assigns.current_user.id
         }) do
      {:ok, updated_record} ->
        {:noreply,
         socket
         |> put_flash(:info, "#{PatientFormRecord.form_label(updated_record.form_type)} updated")
         |> assign(:form_record, updated_record)
         |> assign(
           :forms,
           PatientFormRecords.list_patient_form_records(socket.assigns.patient.id)
         )}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to update form. Please try again.")}
    end
  end

  defp apply_action(socket, :index, _params) do
    assign(socket, :form_record, nil)
  end

  defp apply_action(socket, :show, %{"record_id" => record_id}) do
    record =
      PatientFormRecords.get_patient_form_record_for_patient!(
        socket.assigns.patient.id,
        record_id
      )

    assign(socket, :form_record, record)
  end

  defp forms_path(patient_id), do: ~p"/doctor/#{patient_id}/forms"

  defp form_record_path(patient_id, record_id), do: ~p"/doctor/#{patient_id}/forms/#{record_id}"

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @live_action == :show and @form_record do %>
      <.saved_form_preview
        record={@form_record}
        patient={@patient}
        back_path={forms_path(@patient.id)}
        save_event="update_record"
      />
    <% else %>
      <div class="space-y-6">
        <.header class="border-b border-gray-100 pb-4 text-[#373896]">
          Medical Forms — {[@patient.first_name, @patient.middle_name, @patient.last_name]
          |> Enum.filter(&(&1 not in [nil, ""]))
          |> Enum.join(" ")}
        </.header>

        <%= if @active_form_type do %>
          <div class="rounded-lg border border-gray-100 bg-white p-6 shadow-sm">
            <div class="mb-5 flex items-center justify-between">
              <h2 class="text-base font-semibold text-gray-900">
                {PatientFormRecord.form_label(@active_form_type)}
              </h2>
              <button
                phx-click="cancel_form"
                class="flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700"
              >
                <.icon name="hero-x-mark" class="h-4 w-4" /> Cancel
              </button>
            </div>

            <form phx-submit="save" class="space-y-4">
              <input type="hidden" name="patient_form_record[form_type]" value={@active_form_type} />

              <%= case @active_form_type do %>
                <% "dama" -> %>
                  <div class="space-y-4">
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Reason for Leaving Against Medical Advice
                      </label>
                      <textarea
                        name="patient_form_record[form_data][reason_for_leaving]"
                        rows="4"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="State reason for leaving..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Attending Staff
                      </label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][attending_staff]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Staff name"
                      />
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">Ward / Unit</label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][ward]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Ward or unit"
                      />
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Additional Notes
                      </label>
                      <textarea
                        name="patient_form_record[form_data][notes]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                      ></textarea>
                    </div>
                  </div>
                <% "lab_request" -> %>
                  <div class="space-y-4">
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Investigations Requested
                      </label>
                      <textarea
                        name="patient_form_record[form_data][investigations]"
                        rows="3"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="List the lab tests required..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Clinical Information / Diagnosis
                      </label>
                      <textarea
                        name="patient_form_record[form_data][clinical_info]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Relevant clinical information..."
                      ></textarea>
                    </div>
                    <div class="grid grid-cols-2 gap-4">
                      <div>
                        <label class="mb-1 block text-sm font-medium text-gray-700">Urgency</label>
                        <select
                          name="patient_form_record[form_data][urgency]"
                          class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        >
                          <option value="routine">Routine</option>
                          <option value="urgent">Urgent</option>
                          <option value="stat">STAT</option>
                        </select>
                      </div>
                      <div>
                        <label class="mb-1 block text-sm font-medium text-gray-700">
                          Specimen Type
                        </label>
                        <input
                          type="text"
                          name="patient_form_record[form_data][specimen_type]"
                          class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                          placeholder="e.g. Blood, Urine"
                        />
                      </div>
                    </div>
                  </div>
                <% "discharge_summary" -> %>
                  <div class="space-y-4">
                    <div class="grid grid-cols-2 gap-4">
                      <div>
                        <label class="mb-1 block text-sm font-medium text-gray-700">
                          Date of Admission
                        </label>
                        <input
                          type="date"
                          name="patient_form_record[form_data][admission_date]"
                          class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        />
                      </div>
                      <div>
                        <label class="mb-1 block text-sm font-medium text-gray-700">
                          Date of Discharge
                        </label>
                        <input
                          type="date"
                          name="patient_form_record[form_data][discharge_date]"
                          class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        />
                      </div>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">Diagnosis</label>
                      <textarea
                        name="patient_form_record[form_data][diagnosis]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Primary and secondary diagnoses..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Treatment Summary
                      </label>
                      <textarea
                        name="patient_form_record[form_data][treatment_summary]"
                        rows="3"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Procedures performed, medications given..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Follow-up Instructions
                      </label>
                      <textarea
                        name="patient_form_record[form_data][follow_up]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Follow-up plan and instructions..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Condition on Discharge
                      </label>
                      <select
                        name="patient_form_record[form_data][condition_on_discharge]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                      >
                        <option value="">Select condition</option>
                        <option value="improved">Improved</option>
                        <option value="stable">Stable</option>
                        <option value="unchanged">Unchanged</option>
                        <option value="deteriorated">Deteriorated</option>
                      </select>
                    </div>
                  </div>
                <% "radiology_request" -> %>
                  <div class="space-y-4">
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Investigation Requested
                      </label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][investigation]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="e.g. Chest X-Ray, Abdominal Ultrasound"
                      />
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Clinical Information
                      </label>
                      <textarea
                        name="patient_form_record[form_data][clinical_info]"
                        rows="3"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Relevant clinical information and indication..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">Urgency</label>
                      <select
                        name="patient_form_record[form_data][urgency]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                      >
                        <option value="routine">Routine</option>
                        <option value="urgent">Urgent</option>
                        <option value="stat">STAT</option>
                      </select>
                    </div>
                  </div>
                <% "prescription_sheet" -> %>
                  <div class="space-y-4">
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">Medications</label>
                      <textarea
                        name="patient_form_record[form_data][medications]"
                        rows="5"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Drug name, dose, frequency, duration (one per line)..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Special Instructions
                      </label>
                      <textarea
                        name="patient_form_record[form_data][instructions]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Any special instructions for the patient..."
                      ></textarea>
                    </div>
                  </div>
                <% "sick_leave" -> %>
                  <div class="space-y-4">
                    <div class="grid grid-cols-2 gap-4">
                      <div>
                        <label class="mb-1 block text-sm font-medium text-gray-700">Start Date</label>
                        <input
                          type="date"
                          name="patient_form_record[form_data][start_date]"
                          class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        />
                      </div>
                      <div>
                        <label class="mb-1 block text-sm font-medium text-gray-700">End Date</label>
                        <input
                          type="date"
                          name="patient_form_record[form_data][end_date]"
                          class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        />
                      </div>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Diagnosis / Reason
                      </label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][diagnosis]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Medical reason for sick leave"
                      />
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Fit for Return to Work After Rest
                      </label>
                      <select
                        name="patient_form_record[form_data][fitness]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                      >
                        <option value="yes">Yes</option>
                        <option value="review_required">Requires Review</option>
                        <option value="no">Not Fit</option>
                      </select>
                    </div>
                  </div>
                <% "surgical_consent" -> %>
                  <div class="space-y-4">
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Procedure Name
                      </label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][procedure]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Name of surgical procedure"
                      />
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Surgeon / Clinician
                      </label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][surgeon]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Surgeon's name"
                      />
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Risks Explained
                      </label>
                      <textarea
                        name="patient_form_record[form_data][risks_explained]"
                        rows="3"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Risks explained to patient..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Date of Procedure
                      </label>
                      <input
                        type="date"
                        name="patient_form_record[form_data][procedure_date]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                      />
                    </div>
                  </div>
                <% "blood_transfusion_consent" -> %>
                  <div class="space-y-4">
                    <div class="grid grid-cols-2 gap-4">
                      <div>
                        <label class="mb-1 block text-sm font-medium text-gray-700">
                          Blood Group
                        </label>
                        <input
                          type="text"
                          name="patient_form_record[form_data][blood_type]"
                          class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                          placeholder="e.g. O+, A-, B+"
                        />
                      </div>
                      <div>
                        <label class="mb-1 block text-sm font-medium text-gray-700">
                          Units Requested
                        </label>
                        <input
                          type="text"
                          name="patient_form_record[form_data][units]"
                          class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                          placeholder="Number of units"
                        />
                      </div>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Indication for Transfusion
                      </label>
                      <textarea
                        name="patient_form_record[form_data][indication]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Clinical reason for transfusion..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Risks and Alternatives Explained
                      </label>
                      <textarea
                        name="patient_form_record[form_data][risks_explained]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                      ></textarea>
                    </div>
                  </div>
                <% "hiv_testing_consent" -> %>
                  <div class="space-y-4">
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Pre-Test Counseling Notes
                      </label>
                      <textarea
                        name="patient_form_record[form_data][pre_test_counseling]"
                        rows="3"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Summary of pre-test counseling provided..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">Counselor</label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][counselor]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Name of counselor"
                      />
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Date of Consent
                      </label>
                      <input
                        type="date"
                        name="patient_form_record[form_data][consent_date]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                      />
                    </div>
                  </div>
                <% "medical_report" -> %>
                  <div class="space-y-4">
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Purpose of Report
                      </label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][purpose]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="e.g. Insurance, Fitness, Legal"
                      />
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Clinical Findings
                      </label>
                      <textarea
                        name="patient_form_record[form_data][findings]"
                        rows="4"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Clinical examination findings and diagnosis..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Recommendation
                      </label>
                      <textarea
                        name="patient_form_record[form_data][recommendation]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Medical recommendation or conclusion..."
                      ></textarea>
                    </div>
                  </div>
                <% "patient_referral" -> %>
                  <div class="space-y-4">
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Referred To (Facility / Specialist)
                      </label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][referred_to]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Receiving facility or specialist name"
                      />
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">Urgency</label>
                      <select
                        name="patient_form_record[form_data][urgency]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                      >
                        <option value="routine">Routine</option>
                        <option value="urgent">Urgent</option>
                        <option value="emergency">Emergency</option>
                      </select>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Reason for Referral
                      </label>
                      <textarea
                        name="patient_form_record[form_data][reason]"
                        rows="3"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Clinical reason for referral..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Current Management
                      </label>
                      <textarea
                        name="patient_form_record[form_data][current_management]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="Treatments initiated before referral..."
                      ></textarea>
                    </div>
                  </div>
                <% "payment_receipt" -> %>
                  <div class="space-y-4">
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Services Rendered
                      </label>
                      <textarea
                        name="patient_form_record[form_data][services]"
                        rows="4"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="List services and their costs..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">Total Amount</label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][total_amount]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                        placeholder="e.g. GHS 250.00"
                      />
                    </div>
                    <div>
                      <label class="mb-1 block text-sm font-medium text-gray-700">
                        Payment Method
                      </label>
                      <select
                        name="patient_form_record[form_data][payment_method]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                      >
                        <option value="cash">Cash</option>
                        <option value="mobile_money">Mobile Money</option>
                        <option value="insurance">Insurance</option>
                        <option value="card">Card</option>
                      </select>
                    </div>
                  </div>
                <% _ -> %>
                  <div>
                    <label class="mb-1 block text-sm font-medium text-gray-700">Notes</label>
                    <textarea
                      name="patient_form_record[form_data][notes]"
                      rows="4"
                      class="w-full rounded-lg border border-gray-300 p-2 text-sm outline-none focus:border-[#6667ab]"
                      placeholder="Enter form details..."
                    ></textarea>
                  </div>
              <% end %>

              <div class="pt-2">
                <.button class="bg-[#6667ab] hover:bg-[#5556a0]">Save Form</.button>
              </div>
            </form>
          </div>
        <% else %>
          <div class="rounded-lg border border-gray-100 bg-white p-4 shadow-sm">
            <h2 class="mb-4 text-sm font-semibold text-gray-700">Select a Form to Fill</h2>
            <div class="grid grid-cols-2 gap-3 sm:grid-cols-3">
              <%= for {key, label} <- PatientFormRecord.form_types() do %>
                <button
                  phx-click="select_form_type"
                  phx-value-form_type={key}
                  class="group rounded-lg border border-gray-200 p-3 text-left transition-colors hover:border-[#6667ab] hover:bg-indigo-50"
                >
                  <div class="text-sm font-medium text-gray-900 group-hover:text-[#6667ab]">
                    {label}
                  </div>
                </button>
              <% end %>
            </div>
          </div>
        <% end %>

        <div class="rounded-lg border border-gray-100 bg-white p-4 shadow-sm">
          <h2 class="mb-4 text-sm font-semibold text-gray-700">Form Records</h2>
          <%= if @forms == [] do %>
            <p class="text-sm text-gray-500">No forms saved for this patient yet.</p>
          <% else %>
            <ul class="divide-y divide-gray-100">
              <%= for record <- @forms do %>
                <li class="py-3">
                  <.link
                    navigate={form_record_path(@patient.id, record.id)}
                    class="-mx-3 block rounded-lg px-3 py-3 transition-colors hover:bg-gray-50"
                  >
                    <div class="flex items-start justify-between gap-3">
                      <div>
                        <p class="text-sm font-medium text-gray-900">
                          {PatientFormRecord.form_label(record.form_type)}
                        </p>
                        <p class="mt-1 text-xs text-[#373896]">View saved fields and print</p>
                      </div>
                      <span class="whitespace-nowrap text-xs text-gray-400">
                        {Calendar.strftime(record.inserted_at, "%d %b %Y %H:%M")}
                      </span>
                    </div>
                    <%= if record.form_data && record.form_data != %{} do %>
                      <div class="mt-2 space-y-1">
                        <%= for {key, value} <- Enum.take(record.form_data, 3), is_binary(value) and String.trim(value) != "" do %>
                          <div class="text-xs text-gray-600">
                            <span class="font-medium capitalize">{String.replace(key, "_", " ")}</span>: {value}
                          </div>
                        <% end %>
                      </div>
                    <% end %>
                  </.link>
                </li>
              <% end %>
            </ul>
          <% end %>
        </div>
      </div>
    <% end %>
    """
  end
end
