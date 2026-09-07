defmodule MedcampWeb.ReceptionsPagePatientLive.EachPatientPaymentsIndex do
  use MedcampWeb, :reception_each_patient_live_view

  alias Medcamp.Mpesas
  alias Medcamp.Patients
  alias Medcamp.Postal
  alias Medcamp.PatientVisits
  alias Medcamp.RoomAllocations
  alias Medcamp.DrugAllocations

  alias Medcamp.LabResults
  alias Medcamp.NurseProcedures
  alias Medcamp.RadiologyResults
  alias Medcamp.AdmissionRequests
  alias Medcamp.DoctorProcedures
  alias Medcamp.PatientCharges
  alias Medcamp.Procedures

  @per_page 10

  @impl true
  def mount(%{"patient_id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :payments)
     |> assign(:show_email_modal, false)
     |> assign(:show_combined_modal, false)
     |> assign(:show_combined_preview, false)
     |> assign(:combined_receipt_items, [])
     |> assign(:patient, Patients.get_patient!(id))
     |> assign(:page, 1)
     |> assign(:per_page, @per_page)
     |> load_payments()}
  end

  defp load_payments(socket) do
    patient_id = socket.assigns.patient.id
    total_count = Mpesas.count_successful_payments_by_patient(patient_id)
    total_pages = Medcamp.Pagination.total_pages(total_count, socket.assigns.per_page)
    page = min(max(1, socket.assigns.page || 1), total_pages)

    payments =
      Mpesas.list_successful_payments_by_patient_paginated(
        patient_id,
        page,
        socket.assigns.per_page
      )

    socket
    |> assign(:page, page)
    |> assign(:total_count, total_count)
    |> assign(:total_pages, total_pages)
    |> assign(:payments, payments)
    |> select_all_payments()
  end

  # Every payment on the page starts selected, so combining receipts is one
  # click and de-selecting is the exception rather than the rule.
  defp select_all_payments(socket) do
    selected =
      socket.assigns.payments
      |> Enum.map(&Integer.to_string(&1.id))
      |> MapSet.new()

    assign(socket, :selected_payment_ids, selected)
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply,
     socket
     |> assign(:page, max(1, String.to_integer(page)))
     |> load_payments()}
  end

  @impl true
  def handle_event(
        "send_receipt_to_patient",
        %{
          "actionable_type" => actionable_type,
          "actionable_id" => actionable_id,
          "mpesa_id" => mpesa_id
        },
        socket
      ) do
    mpesa = Mpesas.get_mpesa!(mpesa_id)

    case safe_send_receipt_email(
           actionable_type,
           actionable_id,
           mpesa,
           socket.assigns.patient.email
         ) do
      {:ok, _} ->
        {:noreply, put_flash(socket, :info, "Receipt email sent successfully.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to send receipt: #{reason}")}
    end
  end

  def handle_event(
        "send_receipt_to_other",
        %{
          "actionable_type" => actionable_type,
          "actionable_id" => actionable_id,
          "mpesa_id" => mpesa_id,
          "email" => email
        },
        socket
      ) do
    mpesa = Mpesas.get_mpesa!(mpesa_id)

    spawn(fn ->
      safe_send_receipt_email(actionable_type, actionable_id, mpesa, email)
    end)

    {:noreply,
     socket
     |> put_flash(:info, "Receipt email sent successfully to #{email}.")
     |> assign(:show_email_modal, false)}
  end

  def handle_event(
        "show_email_modal",
        %{
          "actionable_type" => actionable_type,
          "actionable_id" => actionable_id,
          "mpesa_id" => mpesa_id
        },
        socket
      ) do
    {:noreply,
     socket
     |> assign(:actionable_type, actionable_type)
     |> assign(:actionable_id, actionable_id)
     |> assign(:mpesa_id, mpesa_id)
     |> assign(:show_email_modal, true)}
  end

  def handle_event("close_email_modal", _, socket) do
    {:noreply, assign(socket, :show_email_modal, false)}
  end

  def handle_event("toggle_payment_selection", %{"mpesa_id" => mpesa_id}, socket) do
    selected = socket.assigns.selected_payment_ids

    updated =
      if MapSet.member?(selected, mpesa_id) do
        MapSet.delete(selected, mpesa_id)
      else
        MapSet.put(selected, mpesa_id)
      end

    {:noreply, assign(socket, :selected_payment_ids, updated)}
  end

  def handle_event("show_combined_modal", _, socket) do
    if MapSet.size(socket.assigns.selected_payment_ids) < 2 do
      {:noreply, put_flash(socket, :error, "Please select at least 2 payments to combine.")}
    else
      {:noreply, assign(socket, :show_combined_modal, true)}
    end
  end

  def handle_event("close_combined_modal", _, socket) do
    {:noreply, assign(socket, :show_combined_modal, false)}
  end

  def handle_event("clear_selection", _, socket) do
    {:noreply, assign(socket, :selected_payment_ids, MapSet.new())}
  end

  def handle_event("select_all", _, socket) do
    {:noreply, select_all_payments(socket)}
  end

  def handle_event("view_combined_receipt", _, socket) do
    if MapSet.size(socket.assigns.selected_payment_ids) < 2 do
      {:noreply, put_flash(socket, :error, "Please select at least 2 payments to combine.")}
    else
      items =
        socket.assigns.selected_payment_ids
        |> Enum.map(fn id ->
          int_id = if is_binary(id), do: String.to_integer(id), else: id
          Mpesas.get_mpesa!(int_id)
        end)
        |> Enum.map(fn mpesa ->
          case build_receipt_data(mpesa.actionable_type, mpesa.actionable_id, mpesa) do
            {:ok, data} -> data
            {:error, _} -> nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      {:noreply,
       socket
       |> assign(:combined_receipt_items, items)
       |> assign(:show_combined_preview, true)}
    end
  end

  def handle_event("close_combined_preview", _, socket) do
    {:noreply, assign(socket, :show_combined_preview, false)}
  end

  def handle_event("send_combined_receipt", %{"email" => email}, socket) do
    selected_ids = socket.assigns.selected_payment_ids

    receipts =
      selected_ids
      |> Enum.map(fn id ->
        int_id = if is_binary(id), do: String.to_integer(id), else: id
        Mpesas.get_mpesa!(int_id)
      end)
      |> Enum.map(fn mpesa ->
        case build_receipt_data(mpesa.actionable_type, mpesa.actionable_id, mpesa) do
          {:ok, data} -> data
          {:error, _} -> nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    if receipts == [] do
      {:noreply, put_flash(socket, :error, "Could not build receipt data for selected payments.")}
    else
      spawn(fn -> Postal.deliver_combined_receipt(email, receipts) end)

      {:noreply,
       socket
       |> put_flash(:info, "Combined receipt sent to #{email}.")
       |> assign(:show_combined_modal, false)
       |> select_all_payments()}
    end
  end

  defp safe_send_receipt_email(actionable_type, actionable_id, mpesa, email) do
    case build_receipt_data(actionable_type, actionable_id, mpesa) do
      {:ok, receipt_data} ->
        Postal.deliver_purchase_receipt(email, receipt_data)
        {:ok, :sent}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  defp build_receipt_data(actionable_type, actionable_id, mpesa) do
    {_title, service_details, _patient_id, visit_reference} =
      get_service_details(actionable_type, actionable_id)

    {:ok,
     %{
       service_details: service_details,
       amount: mpesa.amount,
       receipt_number: mpesa.receipt,
       transaction_date: mpesa.transactiondate,
       phone_number: mpesa.account_number,
       visit_reference: visit_reference
     }}
  rescue
    e -> {:error, Exception.message(e)}
  end

  defp get_service_details("create_patient_visit", id) do
    patient_visit = PatientVisits.get_patient_visit!(id)

    {"Patient Visit", patient_visit_service_details(patient_visit), patient_visit.patient_id,
     patient_visit.id}
  end

  defp get_service_details("create_patient_visit_for_triage", id) do
    patient_visit = PatientVisits.get_patient_visit!(id)
    {"Patient Visit", "Triage", patient_visit.patient_id, patient_visit.id}
  end

  defp get_service_details("create_patient_visit_subsidized", id) do
    patient_visit = PatientVisits.get_patient_visit!(id)

    {"Patient Visit", "Subsidized Doctor Consultation for Students", patient_visit.patient_id,
     patient_visit.id}
  end

  defp get_service_details("create_admission_request", id) do
    admission = AdmissionRequests.get_admission_request!(id)

    detail =
      if admission.date do
        "Hospital Admission (#{Calendar.strftime(admission.date, "%d %b %Y")})"
      else
        "Hospital Admission"
      end

    {"Hospital Admission", detail, admission.patient_id, admission.id}
  end

  defp get_service_details("admission_line_item", id) do
    line_item = AdmissionRequests.get_line_item_with_admission!(id)
    admission = line_item.admission_request
    type_label = AdmissionRequests.LineItem.item_type_label(line_item.item_type)

    detail =
      if admission.date do
        "Hospital Admission \u2013 #{type_label} (#{Calendar.strftime(admission.date, "%d %b %Y")})"
      else
        "Hospital Admission \u2013 #{type_label}"
      end

    {"Hospital Admission", detail, admission.patient_id, admission.id}
  end

  defp get_service_details("create_room_allocation", id) do
    allocation = RoomAllocations.get_room_allocation!(id)

    {"Room Allocation", "#{allocation.ward_name} - #{allocation.bed_number}",
     allocation.patient_id, allocation.id}
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

    {"Nursing Procedure", Procedures.service_name(procedure, "Nursing Procedure"),
     procedure.patient_id, procedure.id}
  end

  defp get_service_details("create_doctor_procedure", id) do
    procedure = DoctorProcedures.get_doctor_procedure!(id)

    {"Doctor Procedure", Procedures.service_name(procedure, "Doctor Procedure"),
     procedure.patient_id, procedure.id}
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

  defp get_service_details(type, id) do
    {"Payment", "#{type} ##{id}", nil, nil}
  end

  defp patient_visit_service_details(%{visit_type: "Full"}), do: "General Consultation"
  defp patient_visit_service_details(%{visit_type: nil}), do: "General Consultation"
  defp patient_visit_service_details(%{visit_type: ""}), do: "General Consultation"
  defp patient_visit_service_details(%{visit_type: visit_type}), do: visit_type

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-[100%]">
      <div>
        <.header>
          Listing All Successful Payments
        </.header>

        <%= if @payments != [] do %>
          <div class="flex items-center gap-3 mb-4 p-3 bg-blue-50 border border-blue-200 rounded-lg">
            <span class="text-sm text-blue-800 font-medium">
              {MapSet.size(@selected_payment_ids)} payment(s) selected
            </span>
            <button
              phx-click="view_combined_receipt"
              class="inline-flex items-center px-3 py-1.5 text-sm font-medium text-white bg-purple-600 rounded-md hover:bg-purple-700"
            >
              <.icon name="hero-eye" class="h-4 w-4 mr-1" /> View Combined Receipt
            </button>
            <button
              phx-click="show_combined_modal"
              class="inline-flex items-center px-3 py-1.5 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700"
            >
              <.icon name="hero-envelope" class="h-4 w-4 mr-1" /> Send Combined Receipt
            </button>
            <button
              :if={MapSet.size(@selected_payment_ids) < length(@payments)}
              phx-click="select_all"
              class="text-sm text-blue-600 hover:underline"
            >
              Select all
            </button>
            <button
              :if={MapSet.size(@selected_payment_ids) > 0}
              phx-click="clear_selection"
              class="text-sm text-blue-600 hover:underline"
            >
              Clear selection
            </button>
          </div>
        <% end %>

        <.table id="payments" rows={@payments} row_id={&"payment-#{&1.id}"}>
          <:col :let={payment} label="">
            <input
              type="checkbox"
              checked={MapSet.member?(@selected_payment_ids, Integer.to_string(payment.id))}
              phx-click="toggle_payment_selection"
              phx-value-mpesa_id={payment.id}
              aria-label="Select this payment"
              class="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
            />
          </:col>
          <:col :let={payment} label="Patient">
            {[
              payment.patient.first_name,
              payment.patient.middle_name,
              payment.patient.last_name
            ]
            |> Enum.filter(&(&1 != nil))
            |> Enum.join(" ")}
          </:col>
          <:col :let={payment} label="Amount">{payment.amount} KES /=</:col>
          <:col :let={payment} label="Phone Number">{payment.account_number}</:col>
          <:col :let={payment} label="Reason">
            {payment.actionable_label || payment.actionable_type}
          </:col>
          <:col :let={payment} label="Prompter">{payment.prompter.name}</:col>
          <:col :let={payment} label="Date">
            {format_datetime(payment.inserted_at)}
          </:col>

          <:col :let={payment}>
            <div class="flex flex-wrap gap-2">
              <%= if payment.receipt do %>
                <a
                  href={"/payment/#{payment.receipt}"}
                  target="_blank"
                  class="inline-flex items-center text-purple-600 hover:text-purple-800 text-sm"
                >
                  <.icon name="hero-eye" class="h-4 w-4 mr-1" /> View
                </a>
              <% end %>

              <button
                phx-click="send_receipt_to_patient"
                phx-value-actionable_type={payment.actionable_type}
                phx-value-actionable_id={payment.actionable_id}
                phx-value-mpesa_id={payment.id}
                class="inline-flex items-center text-blue-600 hover:text-blue-800 text-sm"
              >
                <.icon name="hero-envelope" class="h-4 w-4 mr-1" /> Send to Patient
              </button>

              <button
                phx-click="show_email_modal"
                phx-value-actionable_type={payment.actionable_type}
                phx-value-actionable_id={payment.actionable_id}
                phx-value-mpesa_id={payment.id}
                class="inline-flex items-center text-green-600 hover:text-green-800 text-sm"
              >
                <.icon name="hero-share" class="h-4 w-4 mr-1" /> Send to Other
              </button>
            </div>
          </:col>
        </.table>
        <.pagination
          page={@page}
          total_pages={@total_pages}
          total_count={@total_count}
          per_page={@per_page}
        />
      </div>
      
    <!-- Send to Other Email Modal -->
      <div
        :if={@show_email_modal}
        class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      >
        <div class="bg-white rounded-lg p-6 w-96 max-w-md mx-4" phx-click-away="close_email_modal">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-semibold">Send Receipt to Email</h3>
            <button phx-click="close_email_modal" class="text-gray-400 hover:text-gray-600">
              <.icon name="hero-x-mark" class="h-5 w-5" />
            </button>
          </div>

          <form phx-submit="send_receipt_to_other">
            <div class="mb-4">
              <label for="email" class="block text-sm font-medium text-gray-700 mb-2">
                Email Address
              </label>
              <input
                type="email"
                id="email"
                name="email"
                required
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Enter email address"
              />

              <input type="hidden" name="actionable_type" value={@actionable_type} />
              <input type="hidden" name="actionable_id" value={@actionable_id} />
              <input type="hidden" name="mpesa_id" value={@mpesa_id} />
            </div>

            <div class="flex justify-end space-x-3">
              <button
                type="button"
                phx-click="close_email_modal"
                class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700"
              >
                <.icon name="hero-envelope" class="h-4 w-4 mr-2" /> Send Receipt
              </button>
            </div>
          </form>
        </div>
      </div>
      
    <!-- Combined Receipt Preview Modal -->
      <div
        :if={@show_combined_preview}
        class="fixed inset-0 bg-black bg-opacity-60 flex items-start justify-center z-50 overflow-y-auto py-8"
      >
        <div class="bg-white rounded-lg shadow-2xl w-full max-w-2xl mx-4">
          <!-- Preview header bar -->
          <div class="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-gray-50 rounded-t-lg">
            <h3 class="text-lg font-semibold text-gray-800">Combined Receipt Preview</h3>
            <div class="flex items-center gap-3">
              <button
                phx-click="show_combined_modal"
                class="inline-flex items-center px-3 py-1.5 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700"
              >
                <.icon name="hero-envelope" class="h-4 w-4 mr-1" /> Send by Email
              </button>
              <button
                onclick="window.print()"
                class="px-3 py-1.5 text-sm font-medium text-white bg-green-600 rounded-md hover:bg-green-700"
              >
                <.icon name="hero-printer" class="h-4 w-4 mr-1" /> Print
              </button>
              <button
                phx-click="close_combined_preview"
                class="text-gray-400 hover:text-gray-600 text-xl leading-none"
              >
                <.icon name="hero-x-mark" class="h-5 w-5" />
              </button>
            </div>
          </div>
          
    <!-- Receipt content -->
          <div id="combined-receipt-print" class="p-8">
            <!-- Receipt header -->
            <div class="bg-[#373896] rounded-t-lg px-6 py-5">
              <div class="flex justify-between items-center">
                <div>
                  <h1 class="text-white text-2xl font-bold">Combined Payment Receipt</h1>
                  <p class="text-blue-200 text-sm mt-1">Glocal Health Centre</p>
                </div>
                <div class="text-right">
                  <p class="text-white text-sm">{format_datetime(DateTime.utc_now())}</p>
                  <span class="inline-block mt-1 bg-green-500 text-white text-xs font-semibold px-3 py-1 rounded-full">
                    PAID
                  </span>
                </div>
              </div>
            </div>
            
    <!-- Patient info -->
            <div class="bg-[#f0f0ff] border border-[#e7e7ff] px-6 py-4">
              <p class="text-sm text-gray-600">
                Patient:
                <span class="font-semibold text-[#373896]">
                  {[
                    @patient.first_name,
                    @patient.middle_name,
                    @patient.last_name
                  ]
                  |> Enum.filter(&(&1 != nil))
                  |> Enum.join(" ")}
                </span>
              </p>
            </div>
            
    <!-- Payments table -->
            <div class="border border-[#e7e7ff] rounded-b-lg overflow-hidden">
              <table class="w-full text-sm">
                <thead>
                  <tr class="bg-[#373896] text-white">
                    <th class="px-4 py-3 text-left font-medium">#</th>
                    <th class="px-4 py-3 text-left font-medium">Service</th>
                    <th class="px-4 py-3 text-left font-medium">Receipt No.</th>
                    <th class="px-4 py-3 text-left font-medium">Phone</th>
                    <th class="px-4 py-3 text-right font-medium">Amount</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for {item, idx} <- Enum.with_index(@combined_receipt_items, 1) do %>
                    <tr class={"border-b border-[#e7e7ff] #{if rem(idx, 2) == 0, do: "bg-[#f8f8ff]", else: "bg-white"}"}>
                      <td class="px-4 py-3 text-gray-500">{idx}</td>
                      <td class="px-4 py-3 text-gray-900 font-medium">{item.service_details}</td>
                      <td class="px-4 py-3 font-mono text-gray-600 text-xs">
                        {item.receipt_number || "—"}
                      </td>
                      <td class="px-4 py-3 text-gray-600">{item.phone_number || "—"}</td>
                      <td class="px-4 py-3 text-right font-semibold text-[#373896]">
                        KES {item.amount}
                      </td>
                    </tr>
                  <% end %>
                </tbody>
                <tfoot>
                  <tr class="bg-[#e7e7ff]">
                    <td colspan="4" class="px-4 py-4 font-bold text-[#373896] text-base">Total</td>
                    <td class="px-4 py-4 text-right font-bold text-[#373896] text-xl">
                      KES {@combined_receipt_items
                      |> Enum.reduce(0, fn item, acc ->
                        case item.amount do
                          a when is_float(a) ->
                            acc + a

                          a when is_integer(a) ->
                            acc + a

                          a when is_binary(a) ->
                            case Float.parse(a) do
                              {f, _} -> acc + f
                              :error -> acc
                            end

                          _ ->
                            acc
                        end
                      end)
                      |> then(fn t ->
                        if is_float(t),
                          do: :erlang.float_to_binary(t, decimals: 2),
                          else: "#{t}.00"
                      end)}
                    </td>
                  </tr>
                </tfoot>
              </table>
            </div>
            
    <!-- Footer note -->
            <p class="text-center text-xs text-gray-400 mt-6">
              &copy; {Date.utc_today().year} Glocal Health Centre · This receipt was generated automatically.
            </p>
          </div>
        </div>
      </div>
      
    <!-- Print styles -->
      <style>
        @media print {
          body * { visibility: hidden; }
          #combined-receipt-print, #combined-receipt-print * { visibility: visible; }
          #combined-receipt-print { position: absolute; left: 0; top: 0; width: 100%; }
        }
      </style>
      
    <!-- Combined Receipt Modal -->
      <div
        :if={@show_combined_modal}
        class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
      >
        <div class="bg-white rounded-lg p-6 w-96 max-w-md mx-4" phx-click-away="close_combined_modal">
          <div class="flex justify-between items-center mb-4">
            <h3 class="text-lg font-semibold">Send Combined Receipt</h3>
            <button phx-click="close_combined_modal" class="text-gray-400 hover:text-gray-600">
              <.icon name="hero-x-mark" class="h-5 w-5" />
            </button>
          </div>

          <p class="text-sm text-gray-600 mb-4">
            A single email with all {MapSet.size(@selected_payment_ids)} selected payments will be sent.
          </p>

          <form phx-submit="send_combined_receipt">
            <div class="mb-4">
              <label for="combined_email" class="block text-sm font-medium text-gray-700 mb-2">
                Recipient Email
              </label>
              <input
                type="email"
                id="combined_email"
                name="email"
                required
                value={@patient.email}
                class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="Enter email address"
              />
            </div>

            <div class="flex justify-end space-x-3">
              <button
                type="button"
                phx-click="close_combined_modal"
                class="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 rounded-md hover:bg-gray-200"
              >
                Cancel
              </button>
              <button
                type="submit"
                class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700"
              >
                <.icon name="hero-envelope" class="h-4 w-4 mr-2" /> Send Combined Receipt
              </button>
            </div>
          </form>
        </div>
      </div>
    </div>
    """
  end

  def format_datetime(datetime) do
    datetime
    |> DateTime.shift_zone!("Africa/Nairobi")
    |> Timex.format!("{Mfull} {D}, {YYYY} at {h12}:{m} {AM}")
  end
end
