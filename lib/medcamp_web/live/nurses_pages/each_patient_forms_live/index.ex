defmodule MedcampWeb.NursesPages.EachPatientFormsIndex do
  use MedcampWeb, :nurse_each_patient_live_view

  alias Medcamp.Patients
  alias Medcamp.PatientFormRecords
  alias Medcamp.PatientFormRecords.PatientFormRecord

  @impl true
  def mount(%{"patient_id" => patient_id}, _session, socket) do
    patient = Patients.get_patient!(patient_id)
    records = PatientFormRecords.list_by_patient(patient_id)

    {:ok,
     socket
     |> assign(:patient, patient)
     |> assign(:active_tab, :forms)
     |> assign(:records, records)
     |> assign(:show_record_modal, false)
     |> assign(:selected_form_type, nil)}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("open_record_modal", %{"form_type" => form_type}, socket) do
    {:noreply,
     socket
     |> assign(:show_record_modal, true)
     |> assign(:selected_form_type, form_type)}
  end

  def handle_event("close_record_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:show_record_modal, false)
     |> assign(:selected_form_type, nil)}
  end

  def handle_event(
        "save_record",
        %{"form_type" => form_type, "notes" => notes},
        socket
      ) do
    patient = socket.assigns.patient

    attrs = %{
      form_type: form_type,
      notes: notes,
      patient_id: patient.id,
      recorded_by_id: socket.assigns.current_user.id
    }

    case PatientFormRecords.create(attrs) do
      {:ok, _record} ->
        records = PatientFormRecords.list_by_patient(patient.id)

        {:noreply,
         socket
         |> assign(:records, records)
         |> assign(:show_record_modal, false)
         |> assign(:selected_form_type, nil)
         |> put_flash(:info, "Form recorded successfully")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to record form")}
    end
  end

  def handle_event("delete_record", %{"id" => id}, socket) do
    record = PatientFormRecords.get!(id)
    {:ok, _} = PatientFormRecords.delete(record)
    records = PatientFormRecords.list_by_patient(socket.assigns.patient.id)

    {:noreply,
     socket
     |> assign(:records, records)
     |> put_flash(:info, "Record removed")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <%!-- Patient context banner --%>
      <div class="bg-[#f0f0ff] border border-[#e7e7ff] rounded-lg p-4 flex items-center gap-3">
        <div class="h-9 w-9 rounded-full bg-[#373896] flex items-center justify-center text-white font-semibold text-sm shrink-0">
          {String.first(@patient.first_name || "P")}
        </div>
        <div>
          <p class="font-semibold text-[#373896]">
            {[@patient.first_name, @patient.middle_name, @patient.last_name]
            |> Enum.filter(&(&1 != nil))
            |> Enum.join(" ")}
          </p>
          <p class="text-xs text-gray-500">GSRN: {@patient.gsrn}</p>
        </div>
        <div class="ml-auto text-xs text-gray-500">
          Forms will be recorded for this patient
        </div>
      </div>

      <%!-- Form listing --%>
      <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-5">
        <h2 class="text-base font-semibold text-[#373896] mb-4 flex items-center gap-2">
          <Heroicons.icon name="clipboard-document-list" type="outline" class="h-5 w-5" />
          Available Forms
        </h2>

        <div class="space-y-8">
          <.form_section title="Clinical" icon="heart">
            <.form_card
              title="Discharge Against Medical Advice"
              subtitle="DAMA Form"
              form_type="dama"
              patient_id={@patient.id}
              color="rose"
            />
            <.form_card
              title="Discharge Summary"
              subtitle="GHC Discharge Summary"
              form_type="discharge_summary"
              patient_id={@patient.id}
              color="green"
            />
            <.form_card
              title="Patient Referral Form"
              subtitle="GHC Referral"
              form_type="patient_referral"
              patient_id={@patient.id}
              color="blue"
            />
          </.form_section>

          <.form_section title="Investigations" icon="beaker">
            <.form_card
              title="Laboratory Request Form"
              subtitle="GHC Lab Request"
              form_type="lab_request"
              patient_id={@patient.id}
              color="blue"
            />
            <.form_card
              title="Radiology Request Form"
              subtitle="GHC Radiology Request"
              form_type="radiology_request"
              patient_id={@patient.id}
              color="purple"
            />
          </.form_section>

          <.form_section title="Consent Forms" icon="shield-check">
            <.form_card
              title="Surgical Consent Form"
              subtitle="GHC Consent"
              form_type="surgical_consent"
              patient_id={@patient.id}
              color="rose"
            />
            <.form_card
              title="Blood Transfusion Consent"
              subtitle="GHC Consent"
              form_type="blood_transfusion_consent"
              patient_id={@patient.id}
              color="red"
            />
            <.form_card
              title="HIV Testing Consent"
              subtitle="GHC Consent"
              form_type="hiv_testing_consent"
              patient_id={@patient.id}
              color="teal"
            />
          </.form_section>

          <.form_section title="Clinical Documents" icon="document-text">
            <.form_card
              title="Medical Report"
              subtitle="GHC Medical Report"
              form_type="medical_report"
              patient_id={@patient.id}
              color="purple"
            />
            <.form_card
              title="Prescription Sheet"
              subtitle="GHC Prescription"
              form_type="prescription_sheet"
              patient_id={@patient.id}
              color="amber"
            />
            <.form_card
              title="Sick Leave Sheet"
              subtitle="GHC Sick Leave"
              form_type="sick_leave"
              patient_id={@patient.id}
              color="green"
            />
          </.form_section>

          <.form_section title="Administrative" icon="banknotes">
            <.form_card
              title="Payment Receipt"
              subtitle="GHC Receipt"
              form_type="payment_receipt"
              patient_id={@patient.id}
              color="amber"
            />
          </.form_section>
        </div>
      </div>

      <%!-- Recorded forms for this patient --%>
      <div class="bg-white rounded-lg shadow-sm border border-gray-100 p-5">
        <h2 class="text-base font-semibold text-[#373896] mb-4 flex items-center gap-2">
          <Heroicons.icon name="document-check" type="outline" class="h-5 w-5" />
          Forms Recorded for This Patient
          <span class="ml-auto text-xs font-normal text-gray-500">
            {length(@records)} form(s)
          </span>
        </h2>

        <%= if Enum.empty?(@records) do %>
          <div class="text-center py-8 bg-gray-50 rounded-lg border border-dashed border-gray-300">
            <Heroicons.icon
              name="clipboard-document-list"
              type="outline"
              class="mx-auto h-10 w-10 text-gray-400"
            />
            <p class="mt-2 text-sm text-gray-500">No forms recorded yet for this patient.</p>
            <p class="text-xs text-gray-400 mt-1">
              Open a form above and click "Record Submission" to save.
            </p>
          </div>
        <% else %>
          <div class="divide-y divide-gray-100">
            <%= for record <- @records do %>
              <div class="flex items-start justify-between py-3">
                <div class="flex items-start gap-3">
                  <div class="h-8 w-8 rounded-lg bg-[#e7e7ff] flex items-center justify-center shrink-0">
                    <Heroicons.icon
                      name="document-check"
                      type="outline"
                      class="h-4 w-4 text-[#373896]"
                    />
                  </div>
                  <div>
                    <p class="font-medium text-gray-900 text-sm">
                      {PatientFormRecord.form_label(record.form_type)}
                    </p>
                    <%= if record.notes && record.notes != "" do %>
                      <p class="text-xs text-gray-500 mt-0.5">{record.notes}</p>
                    <% end %>
                    <p class="text-xs text-gray-400 mt-0.5">
                      Recorded by {if record.recorded_by, do: record.recorded_by.name, else: "Unknown"} · {Calendar.strftime(
                        record.inserted_at,
                        "%b %d, %Y %H:%M"
                      )}
                    </p>
                  </div>
                </div>
                <button
                  phx-click="delete_record"
                  phx-value-id={record.id}
                  data-confirm="Remove this record?"
                  class="text-red-400 hover:text-red-600 text-xs"
                >
                  Remove
                </button>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>

    <%!-- Record submission modal --%>
    <.modal
      :if={@show_record_modal}
      id="record-form-modal"
      show
      on_cancel={JS.push("close_record_modal")}
    >
      <div>
        <h3 class="text-lg font-semibold text-[#373896] mb-1">Record Form Submission</h3>
        <p class="text-sm text-gray-500 mb-4">
          Recording:
          <span class="font-medium">{PatientFormRecord.form_label(@selected_form_type)}</span>
        </p>

        <form phx-submit="save_record">
          <input type="hidden" name="form_type" value={@selected_form_type} />
          <div class="mb-4">
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Notes <span class="text-gray-400 font-normal">(optional)</span>
            </label>
            <textarea
              name="notes"
              rows="3"
              class="w-full border border-gray-300 rounded-lg p-2 text-sm focus:border-[#373896] focus:ring-1 focus:ring-[#373896] outline-none"
              placeholder="Any notes about this form submission..."
            ></textarea>
          </div>
          <div class="flex justify-end gap-2">
            <button
              type="button"
              phx-click="close_record_modal"
              class="px-4 py-2 text-sm text-gray-600 border border-gray-300 rounded-lg hover:bg-gray-50"
            >
              Cancel
            </button>
            <button
              type="submit"
              class="px-4 py-2 text-sm bg-[#373896] text-white rounded-lg hover:bg-[#2d2d7a]"
            >
              Save Record
            </button>
          </div>
        </form>
      </div>
    </.modal>
    """
  end

  defp form_section(assigns) do
    ~H"""
    <div>
      <div class="flex items-center gap-2 mb-3">
        <Heroicons.icon name={@icon} type="outline" class="h-4 w-4 text-[#373896]" />
        <h3 class="text-xs font-bold text-gray-500 uppercase tracking-wider">{@title}</h3>
        <div class="flex-1 h-px bg-gray-100"></div>
      </div>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp form_card(assigns) do
    ~H"""
    <div class={[
      "border rounded-xl p-4 group transition-all duration-200",
      @color == "rose" && "border-rose-100 bg-rose-50/30",
      @color == "red" && "border-red-100 bg-red-50/30",
      @color == "blue" && "border-blue-100 bg-blue-50/30",
      @color == "green" && "border-green-100 bg-green-50/30",
      @color == "purple" && "border-purple-100 bg-slate-50/30",
      @color == "amber" && "border-amber-100 bg-amber-50/30",
      @color == "teal" && "border-teal-100 bg-teal-50/30"
    ]}>
      <p class="text-xs text-gray-400 uppercase tracking-wide mb-0.5">{@subtitle}</p>
      <p class="font-medium text-gray-800 text-sm leading-tight mb-3">{@title}</p>
      <div class="flex gap-2">
        <a
          href={"/forms/#{@form_type}"}
          target="_blank"
          class="flex-1 text-center py-1.5 px-2 text-xs font-medium text-[#373896] border border-[#373896] rounded-lg hover:bg-[#373896] hover:text-white transition-colors"
        >
          Open Form
        </a>
        <button
          type="button"
          phx-click="open_record_modal"
          phx-value-form_type={@form_type}
          class="flex-1 text-center py-1.5 px-2 text-xs font-medium bg-[#373896] text-white rounded-lg hover:bg-[#2d2d7a] transition-colors"
        >
          Record Submission
        </button>
      </div>
    </div>
    """
  end
end
