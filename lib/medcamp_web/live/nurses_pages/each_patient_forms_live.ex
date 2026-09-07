defmodule MedcampWeb.NursesPages.EachPatientFormsLive do
  use MedcampWeb, :nurse_each_patient_live_view
  alias Medcamp.PatientFormRecords
  alias Medcamp.PatientFormRecords.PatientFormRecord
  alias Medcamp.Patients

  def mount(%{"patient_id" => patient_id}, _session, socket) do
    patient = Patients.get_patient!(patient_id)

    {:ok,
     socket
     |> assign(:active_tab, :forms)
     |> assign(:patient, patient)
     |> assign(:forms, PatientFormRecords.list_patient_form_records(patient_id))
     |> assign(:active_form_type, nil)
     |> assign(:form_record, nil)}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  def handle_event("select_form_type", %{"form_type" => form_type}, socket) do
    {:noreply, assign(socket, :active_form_type, form_type)}
  end

  def handle_event("cancel_form", _, socket) do
    {:noreply, assign(socket, :active_form_type, nil)}
  end

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

  defp forms_path(patient_id), do: ~p"/nurse/#{patient_id}/forms"

  defp form_record_path(patient_id, record_id), do: ~p"/nurse/#{patient_id}/forms/#{record_id}"

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
        <.header class="text-[#373896] border-b border-gray-100 pb-4">
          Medical Forms — {[@patient.first_name, @patient.middle_name, @patient.last_name]
          |> Enum.filter(&(&1 not in [nil, ""]))
          |> Enum.join(" ")}
        </.header>

        <%= if @active_form_type do %>
          <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-6">
            <div class="flex items-center justify-between mb-5">
              <h2 class="text-base font-semibold text-gray-900">
                {PatientFormRecord.form_label(@active_form_type)}
              </h2>
              <button
                phx-click="cancel_form"
                class="text-sm text-gray-500 hover:text-gray-700 flex items-center gap-1"
              >
                <.icon name="hero-x-mark" class="w-4 h-4" /> Cancel
              </button>
            </div>

            <form phx-submit="save" class="space-y-4">
              <input type="hidden" name="patient_form_record[form_type]" value={@active_form_type} />

              <%= case @active_form_type do %>
                <% "dama" -> %>
                  <div class="space-y-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Reason for Leaving Against Medical Advice
                      </label>
                      <textarea
                        name="patient_form_record[form_data][reason_for_leaving]"
                        rows="4"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="State reason for leaving..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Attending Staff
                      </label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][attending_staff]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Staff name"
                      />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">Ward / Unit</label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][ward]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Ward or unit"
                      />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Additional Notes
                      </label>
                      <textarea
                        name="patient_form_record[form_data][notes]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                      ></textarea>
                    </div>
                  </div>
                <% "lab_request" -> %>
                  <div class="space-y-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Investigations Requested
                      </label>
                      <textarea
                        name="patient_form_record[form_data][investigations]"
                        rows="3"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="List the lab tests required..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Clinical Information / Diagnosis
                      </label>
                      <textarea
                        name="patient_form_record[form_data][clinical_info]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Relevant clinical information..."
                      ></textarea>
                    </div>
                    <div class="grid grid-cols-2 gap-4">
                      <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Urgency</label>
                        <select
                          name="patient_form_record[form_data][urgency]"
                          class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        >
                          <option value="routine">Routine</option>
                          <option value="urgent">Urgent</option>
                          <option value="stat">STAT</option>
                        </select>
                      </div>
                      <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">
                          Specimen Type
                        </label>
                        <input
                          type="text"
                          name="patient_form_record[form_data][specimen_type]"
                          class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                          placeholder="e.g. Blood, Urine"
                        />
                      </div>
                    </div>
                  </div>
                <% "discharge_summary" -> %>
                  <div class="space-y-4">
                    <div class="grid grid-cols-2 gap-4">
                      <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">
                          Date of Admission
                        </label>
                        <input
                          type="date"
                          name="patient_form_record[form_data][admission_date]"
                          class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        />
                      </div>
                      <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">
                          Date of Discharge
                        </label>
                        <input
                          type="date"
                          name="patient_form_record[form_data][discharge_date]"
                          class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        />
                      </div>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">Diagnosis</label>
                      <textarea
                        name="patient_form_record[form_data][diagnosis]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Primary and secondary diagnoses..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Treatment Summary
                      </label>
                      <textarea
                        name="patient_form_record[form_data][treatment_summary]"
                        rows="3"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Procedures performed, medications given..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Follow-up Instructions
                      </label>
                      <textarea
                        name="patient_form_record[form_data][follow_up]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Follow-up plan and instructions..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Condition on Discharge
                      </label>
                      <select
                        name="patient_form_record[form_data][condition_on_discharge]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
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
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Investigation Requested
                      </label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][investigation]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="e.g. Chest X-Ray, Abdominal Ultrasound"
                      />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Clinical Information
                      </label>
                      <textarea
                        name="patient_form_record[form_data][clinical_info]"
                        rows="3"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Relevant clinical information and indication..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">Urgency</label>
                      <select
                        name="patient_form_record[form_data][urgency]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
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
                      <label class="block text-sm font-medium text-gray-700 mb-1">Medications</label>
                      <textarea
                        name="patient_form_record[form_data][medications]"
                        rows="5"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Drug name, dose, frequency, duration (one per line)..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Special Instructions
                      </label>
                      <textarea
                        name="patient_form_record[form_data][instructions]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Any special instructions for the patient..."
                      ></textarea>
                    </div>
                  </div>
                <% "sick_leave" -> %>
                  <div class="space-y-4">
                    <div class="grid grid-cols-2 gap-4">
                      <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">Start Date</label>
                        <input
                          type="date"
                          name="patient_form_record[form_data][start_date]"
                          class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        />
                      </div>
                      <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">End Date</label>
                        <input
                          type="date"
                          name="patient_form_record[form_data][end_date]"
                          class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        />
                      </div>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Diagnosis / Reason
                      </label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][diagnosis]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Medical reason for sick leave"
                      />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Fit for Return to Work After Rest
                      </label>
                      <select
                        name="patient_form_record[form_data][fitness]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
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
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Procedure Name
                      </label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][procedure]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Name of surgical procedure"
                      />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Surgeon / Clinician
                      </label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][surgeon]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Surgeon's name"
                      />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Risks Explained
                      </label>
                      <textarea
                        name="patient_form_record[form_data][risks_explained]"
                        rows="3"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Risks explained to patient..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Date of Procedure
                      </label>
                      <input
                        type="date"
                        name="patient_form_record[form_data][procedure_date]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                      />
                    </div>
                  </div>
                <% "blood_transfusion_consent" -> %>
                  <div class="space-y-4">
                    <div class="grid grid-cols-2 gap-4">
                      <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">
                          Blood Group
                        </label>
                        <input
                          type="text"
                          name="patient_form_record[form_data][blood_type]"
                          class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                          placeholder="e.g. O+, A-, B+"
                        />
                      </div>
                      <div>
                        <label class="block text-sm font-medium text-gray-700 mb-1">
                          Units Requested
                        </label>
                        <input
                          type="text"
                          name="patient_form_record[form_data][units]"
                          class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                          placeholder="Number of units"
                        />
                      </div>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Indication for Transfusion
                      </label>
                      <textarea
                        name="patient_form_record[form_data][indication]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Clinical reason for transfusion..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Risks and Alternatives Explained
                      </label>
                      <textarea
                        name="patient_form_record[form_data][risks_explained]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                      ></textarea>
                    </div>
                  </div>
                <% "hiv_testing_consent" -> %>
                  <div class="space-y-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Pre-Test Counseling Notes
                      </label>
                      <textarea
                        name="patient_form_record[form_data][pre_test_counseling]"
                        rows="3"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Summary of pre-test counseling provided..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">Counselor</label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][counselor]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Name of counselor"
                      />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Date of Consent
                      </label>
                      <input
                        type="date"
                        name="patient_form_record[form_data][consent_date]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                      />
                    </div>
                  </div>
                <% "medical_report" -> %>
                  <div class="space-y-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Purpose of Report
                      </label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][purpose]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="e.g. Insurance, Fitness, Legal"
                      />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Clinical Findings
                      </label>
                      <textarea
                        name="patient_form_record[form_data][findings]"
                        rows="4"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Clinical examination findings and diagnosis..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Recommendation
                      </label>
                      <textarea
                        name="patient_form_record[form_data][recommendation]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Medical recommendation or conclusion..."
                      ></textarea>
                    </div>
                  </div>
                <% "patient_referral" -> %>
                  <div class="space-y-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Referred To (Facility / Specialist)
                      </label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][referred_to]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Receiving facility or specialist name"
                      />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">Urgency</label>
                      <select
                        name="patient_form_record[form_data][urgency]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                      >
                        <option value="routine">Routine</option>
                        <option value="urgent">Urgent</option>
                        <option value="emergency">Emergency</option>
                      </select>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Reason for Referral
                      </label>
                      <textarea
                        name="patient_form_record[form_data][reason]"
                        rows="3"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Clinical reason for referral..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Current Management
                      </label>
                      <textarea
                        name="patient_form_record[form_data][current_management]"
                        rows="2"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="Treatments initiated before referral..."
                      ></textarea>
                    </div>
                  </div>
                <% "payment_receipt" -> %>
                  <div class="space-y-4">
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Services Rendered
                      </label>
                      <textarea
                        name="patient_form_record[form_data][services]"
                        rows="4"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="List services and their costs..."
                      ></textarea>
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">Total Amount</label>
                      <input
                        type="text"
                        name="patient_form_record[form_data][total_amount]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
                        placeholder="e.g. GHS 250.00"
                      />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-gray-700 mb-1">
                        Payment Method
                      </label>
                      <select
                        name="patient_form_record[form_data][payment_method]"
                        class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
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
                    <label class="block text-sm font-medium text-gray-700 mb-1">Notes</label>
                    <textarea
                      name="patient_form_record[form_data][notes]"
                      rows="4"
                      class="w-full rounded-lg border border-gray-300 p-2 text-sm focus:border-[#6667ab] outline-none"
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
          <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
            <h2 class="text-sm font-semibold text-gray-700 mb-4">Select a Form to Fill</h2>
            <div class="grid grid-cols-2 sm:grid-cols-3 gap-3">
              <%= for {key, label} <- PatientFormRecord.form_types() do %>
                <button
                  phx-click="select_form_type"
                  phx-value-form_type={key}
                  class="text-left border border-gray-200 rounded-lg p-3 hover:border-[#6667ab] hover:bg-indigo-50 transition-colors group"
                >
                  <div class="text-sm font-medium text-gray-900 group-hover:text-[#6667ab]">
                    {label}
                  </div>
                </button>
              <% end %>
            </div>
          </div>
        <% end %>

        <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-4">
          <h2 class="text-sm font-semibold text-gray-700 mb-4">Form Records</h2>
          <%= if @forms == [] do %>
            <p class="text-gray-500 text-sm">No forms saved for this patient yet.</p>
          <% else %>
            <ul class="divide-y divide-gray-100">
              <%= for record <- @forms do %>
                <li class="py-3">
                  <.link
                    navigate={form_record_path(@patient.id, record.id)}
                    class="block rounded-lg px-3 py-3 -mx-3 hover:bg-gray-50 transition-colors"
                  >
                    <div class="flex items-start justify-between gap-3">
                      <div>
                        <p class="font-medium text-gray-900 text-sm">
                          {PatientFormRecord.form_label(record.form_type)}
                        </p>
                        <p class="text-xs text-[#373896] mt-1">View saved fields and print</p>
                      </div>
                      <span class="text-xs text-gray-400 whitespace-nowrap">
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
