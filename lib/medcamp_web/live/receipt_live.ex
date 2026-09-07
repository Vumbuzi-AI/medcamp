defmodule MedcampWeb.ReceiptLive.Index do
  use MedcampWeb, :live_view

  alias Medcamp.Mpesas
  alias Medcamp.PatientVisits
  alias Medcamp.RoomAllocations
  alias Medcamp.DrugAllocations

  alias Medcamp.LabResults
  alias Medcamp.NurseProcedures
  alias Medcamp.RadiologyResults
  alias Medcamp.AdmissionRequests
  alias Medcamp.PatientCharges

  @impl true
  def mount(%{"receipt" => receipt} = _params, _session, socket) do
    payment = Mpesas.get_mpesa_by_receipt(receipt)

    case payment do
      nil ->
        {:ok,
         socket
         |> put_flash(:error, "Receipt not found")
         |> assign(:payment, nil)
         |> assign(:receipt_number, receipt)}

      payment ->
        {service_details, _service_details, _patient_id, _visit_reference} =
          get_service_details(payment.actionable_type, payment.actionable_id)

        {:ok,
         socket
         |> assign(:payment, payment)
         |> assign(:service_details, service_details)
         |> assign(:receipt_number, receipt)}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-[#f8f8ff] flex flex-col">
      <div class="flex-1 flex items-center justify-center p-4">
        <%= if @payment do %>
          <!-- Receipt Display -->
          <div class="w-full max-w-2xl bg-white rounded-lg shadow-lg border border-gray-100 overflow-hidden">
            <!-- Header -->
            <div class="bg-[#373896] px-6 py-4">
              <div class="flex justify-between items-center">
                <div>
                  <h1 class="text-white text-2xl font-bold">Payment Receipt</h1>
                  <p class="text-blue-100 text-sm">Glocal Health Centre</p>
                </div>
                <div class="text-right">
                  <div class="text-white text-sm">
                    {format_datetime(@payment.inserted_at)}
                  </div>
                  <div class=" text-white text-xs px-3 py-1 rounded-full text-end text- font-medium mt-1">
                    PAID
                  </div>
                </div>
              </div>
            </div>
            
    <!-- Main Content -->
            <div class="p-6">
              <!-- Success Message -->
              <div class="bg-green-50 border border-green-200 rounded-lg p-4 mb-6">
                <div class="flex items-center">
                  <svg
                    class="h-5 w-5 text-green-400 mr-2"
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
                  <p class="text-green-800 font-medium">Payment Successfully Processed</p>
                </div>
                <p class="text-green-700 text-sm mt-1">
                  Your payment has been confirmed and your service has been processed.
                </p>
              </div>
              
    <!-- Receipt Details -->
              <div class="bg-[#f0f0ff] border border-[#e7e7ff] rounded-lg p-6 mb-6">
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div class="space-y-4">
                    <div>
                      <label class="text-sm text-gray-500 block mb-1">Receipt Number</label>
                      <p class="text-[#373896] font-semibold text-lg">
                        {@payment.receipt}
                      </p>
                    </div>

                    <div>
                      <label class="text-sm text-gray-500 block mb-1">Service Type</label>
                      <p class="text-gray-900 font-medium">
                        {@service_details}
                      </p>
                    </div>

                    <div>
                      <label class="text-sm text-gray-500 block mb-1">Payment Method</label>
                      <div class="flex items-center">
                        <span class="bg-green-600 text-white px-2 py-1 rounded text-xs font-medium mr-2">
                          M-PESA
                        </span>
                        <span class="text-gray-700">
                          {format_phone(@payment.account_number)}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div class="space-y-4">
                    <div>
                      <label class="text-sm text-gray-500 block mb-1">Amount Paid</label>
                      <p class="text-[#373896] font-bold text-2xl">
                        KES {@payment.amount}
                      </p>
                    </div>

                    <div>
                      <label class="text-sm text-gray-500 block mb-1">Transaction Date</label>
                      <p class="text-gray-900 font-medium">
                        {format_datetime(@payment.inserted_at)}
                      </p>
                    </div>

                    <div>
                      <label class="text-sm text-gray-500 block mb-1">M-PESA Code</label>
                      <p class="text-gray-900 font-mono text-sm bg-gray-100 px-2 py-1 rounded">
                        {@payment.receipt || "N/A"}
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              <div class="bg-gray-50 rounded-lg p-4">
                <h3 class="text-sm font-medium text-gray-900 mb-2">Need Help?</h3>
                <p class="text-sm text-gray-600 mb-3">
                  If you have any questions about this payment or need assistance, please contact our support team.
                </p>
                <div class="flex flex-col sm:flex-row gap-4 text-sm">
                  <a
                    href="tel:+254700000000"
                    class="text-[#373896] hover:text-[#6667ab] flex items-center"
                  >
                    <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"
                      />
                    </svg>
                    +254 700 000 000
                  </a>
                  <a
                    href="mailto:info@glocalhealthcentre.org"
                    class="text-[#373896] hover:text-[#6667ab] flex items-center"
                  >
                    <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                      />
                    </svg>
                    info@glocalhealthcentre.org
                  </a>
                </div>
              </div>
            </div>
            
    <!-- Footer -->
            <div class="bg-[#f8f8ff] px-6 py-4 border-t border-gray-100">
              <div class="text-center text-sm text-gray-500">
                <p>&copy; {Date.utc_today().year} Glocal Health Centre. All Rights Reserved.</p>
                <p class="mt-1">
                  This receipt was generated automatically and is valid for your records.
                </p>
              </div>
            </div>
          </div>
        <% else %>
          <!-- Receipt Not Found -->
          <div class="w-full max-w-md bg-white rounded-lg shadow-lg border border-gray-100 p-8 text-center">
            <div class="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-red-100 mb-4">
              <svg class="h-8 w-8 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z"
                />
              </svg>
            </div>

            <h2 class="text-xl font-semibold text-gray-900 mb-2">Receipt Not Found</h2>
            <p class="text-gray-600 mb-6">
              The receipt with number
              <span class="font-mono bg-gray-100 px-2 py-1 rounded text-sm">{@receipt_number}</span>
              could not be found in our system.
            </p>

            <div class="space-y-3">
              <p class="text-sm text-gray-500">This could happen if:</p>
              <ul class="text-left text-sm text-gray-500 space-y-1">
                <li>• The receipt number is incorrect</li>
                <li>• The payment is still being processed</li>
                <li>• The receipt has expired</li>
              </ul>
            </div>

            <div class="mt-6 pt-4 border-t border-gray-200">
              <p class="text-sm text-gray-600 mb-3">Need assistance?</p>
              <a
                href="mailto:info@glocalhealthcentre.org"
                class="inline-flex items-center px-4 py-2 bg-[#373896] text-white text-sm font-medium rounded-md hover:bg-[#2d2d7a] transition-colors"
              >
                <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                  />
                </svg>
                Contact Support
              </a>
            </div>
          </div>
        <% end %>
      </div>
    </div>

    <!-- Print Styles -->
    <style>
      @media print {
        body * {
          visibility: hidden;
        }
        .receipt-content, .receipt-content * {
          visibility: visible;
        }
        .receipt-content {
          position: absolute;
          left: 0;
          top: 0;
          width: 100%;
        }
        .no-print {
          display: none !important;
        }
      }
    </style>

    <!-- JavaScript for additional functionality -->
    <script>
      function downloadReceipt() {
        // This would integrate with a PDF generation service
        // For now, we'll just print
        window.print();
      }
    </script>
    """
  end

  # Helper functions
  def format_datetime(datetime) do
    shifted_datetime = Timex.shift(datetime, hours: 3)
    Timex.format!(shifted_datetime, "{Mfull} {D}, {YYYY} at {h12}:{m} {AM}")
  end

  defp format_phone(phone) when is_binary(phone) do
    # Format phone number (e.g., +254712345678 -> +254 712 345 678)
    case String.length(phone) do
      13 ->
        "+#{String.slice(phone, 1, 3)} #{String.slice(phone, 4, 3)} #{String.slice(phone, 7, 3)} #{String.slice(phone, 10, 3)}"

      _ ->
        phone
    end
  end

  defp format_phone(_phone), do: "N/A"

  defp get_service_details("create_patient_visit", id) do
    patient_visit = PatientVisits.get_patient_visit!(id)
    service_details = patient_visit_service_details(patient_visit)
    {"Patient Visit", service_details, patient_visit.patient_id, patient_visit.id}
  end

  defp get_service_details("create_patient_visit_for_triage", id) do
    patient_visit = PatientVisits.get_patient_visit!(id)
    service_details = "Triage"
    {"Patient Visit", service_details, patient_visit.patient_id, patient_visit.id}
  end

  defp get_service_details("create_patient_visit_subsidized", id) do
    patient_visit = PatientVisits.get_patient_visit!(id)
    service_details = "Subsidized Doctor Consultation for Students"
    {"Patient Visit", service_details, patient_visit.patient_id, patient_visit.id}
  end

  defp get_service_details("create_admission_request", id) do
    admission = AdmissionRequests.get_admission_request!(id)

    detail =
      if admission.date, do: Calendar.strftime(admission.date, "%d %b %Y"), else: "Admission"

    {"Hospital Admission", detail, admission.patient_id, admission.id}
  end

  defp get_service_details("admission_line_item", id) do
    line_item = AdmissionRequests.get_line_item_with_admission!(id)
    admission = line_item.admission_request
    type_label = AdmissionRequests.LineItem.item_type_label(line_item.item_type)

    detail =
      if admission.date do
        "Hospital Admission – #{type_label} (#{Calendar.strftime(admission.date, "%d %b %Y")})"
      else
        "Hospital Admission – #{type_label}"
      end

    {"Hospital Admission", detail, admission.patient_id, admission.id}
  end

  defp get_service_details("create_room_allocation", id) do
    allocation = RoomAllocations.get_room_allocation!(id)
    room_details = "#{allocation.ward_name} - #{allocation.bed_number}"
    {"Room Allocation", room_details, allocation.patient_id, allocation.id}
  end

  defp get_service_details("create_lab_result", id) do
    lab = LabResults.get_lab_result!(id)
    {"Laboratory Test", "Lab Tests", lab.patient_id, lab.id}
  end

  defp get_service_details("create_radiology_result", id) do
    radiology = RadiologyResults.get_radiology_result!(id)

    {"Radiology Service", "Radiology Service", radiology.patient_id, radiology.id}
  end

  defp get_service_details("create_nurse_procedure", id) do
    procedure = NurseProcedures.get_nurse_procedure!(id)

    {"Nursing Procedure", procedure.procedure_type, procedure.patient_id, procedure.id}
  end

  defp get_service_details("create_drug_allocation", id) do
    allocation = DrugAllocations.get_drug_allocation!(id)

    {"Pharmacy", "Drugs Allocated", allocation.patient_id, allocation.id}
  end

  defp get_service_details("create_wallet_deposit", id) do
    wallet_deposit = Medcamp.WalletDeposits.get_wallet_deposit!(id)

    {"Wallet Deposit", "Wallet Deposit", wallet_deposit.patient_id, nil}
  end

  defp get_service_details("patient_charge_batch", id) do
    batch = PatientCharges.get_patient_charge_batch!(id)

    {"Emergency Nursing Charges", PatientCharges.charge_batch_service_label(batch),
     batch.patient_id, batch.id}
  end

  defp patient_visit_service_details(%{visit_type: "Full"}), do: "General Consultation"
  defp patient_visit_service_details(%{visit_type: nil}), do: "General Consultation"
  defp patient_visit_service_details(%{visit_type: ""}), do: "General Consultation"
  defp patient_visit_service_details(%{visit_type: visit_type}), do: visit_type
end
