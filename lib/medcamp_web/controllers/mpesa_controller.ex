defmodule MedcampWeb.MpesaController do
  use MedcampWeb, :controller
  alias Phoenix.PubSub
  alias Medcamp.Mpesas
  alias Medcamp.PatientVisits
  alias Medcamp.RoomAllocations
  alias Medcamp.DrugAllocations
  alias Medcamp.LabResults
  alias Medcamp.NurseProcedures
  alias Medcamp.RadiologyResults
  alias Medcamp.AdmissionRequests
  alias Medcamp.Postal
  alias Medcamp.Patients
  alias Medcamp.DoctorProcedures
  alias Medcamp.PatientCharges
  alias Medcamp.WalletDeposits
  alias Medcamp.Procedures

  @spec create(Plug.Conn.t(), nil | maybe_improper_list() | map()) :: Plug.Conn.t()
  def create(conn, params) do
    body = params["Body"]

    case body do
      %{"stkCallback" => %{"ResultCode" => 0}} ->
        {:ok, mpesa} = handle_success(body)

        PubSub.broadcast(
          Medcamp.PubSub,
          "confirm_payment_for:#{body["stkCallback"]["CheckoutRequestID"]}",
          {:payment_confirmed, mpesa}
        )

      %{"stkCallback" => _params} ->
        {:ok, mpesa} = handle_failure(body)

        PubSub.broadcast(
          Medcamp.PubSub,
          "confirm_payment_for:#{body["stkCallback"]["CheckoutRequestID"]}",
          {:payment_failed, mpesa}
        )
    end

    conn
    |> Plug.Conn.put_resp_content_type("application/json")
    |> Plug.Conn.send_resp(200, Jason.encode!(%{message: "Success"}))
  end

  def handle_success_with_receipt(receipt) do
    mpesa = Mpesas.get_mpesa_by_receipt(receipt)

    {:ok, mpesa} =
      Mpesas.update_mpesa(mpesa, %{
        "payment_pending" => false,
        "is_successful" => true,
        "receipt" => receipt,
        "description" => "Payment successful",
        "result_code" => 0
      })

    # Process the payment in respective modules
    handle_after_action(mpesa.actionable_type, mpesa.actionable_id, mpesa)

    # Get patient details and send email receipt
    send_receipt_email(mpesa.actionable_type, mpesa.actionable_id, mpesa)

    {:ok, mpesa}
  end

  def handle_success(body) do
    mpesa = Mpesas.get_mpesa_by_checkout_request_id(body["stkCallback"]["CheckoutRequestID"])

    transaction_date =
      extract_value(body, "TransactionDate")
      |> Integer.to_string()

    receipt =
      extract_value(body, "MpesaReceiptNumber")

    account_number =
      extract_value(body, "PhoneNumber")
      |> Integer.to_string()

    {:ok, mpesa} =
      Mpesas.update_mpesa(mpesa, %{
        "payment_pending" => false,
        "is_successful" => true,
        "transactiondate" => transaction_date,
        "receipt" => receipt,
        "account_number" => account_number,
        "description" => body["ResultDesc"],
        "result_code" => body["ResultCode"]
      })

    # Process the payment in respective modules
    handle_after_action(mpesa.actionable_type, mpesa.actionable_id, mpesa)

    # Get patient details and send email receipt
    send_receipt_email(mpesa.actionable_type, mpesa.actionable_id, mpesa)

    {:ok, mpesa}
  end

  def handle_failure(body) do
    mpesa = Mpesas.get_mpesa_by_checkout_request_id(body["stkCallback"]["CheckoutRequestID"])

    {:ok, mpesa} =
      Mpesas.update_mpesa(mpesa, %{
        "payment_pending" => false,
        "description" => body["stkCallback"]["ResultDesc"],
        "result_code" => body["stkCallback"]["ResultCode"]
      })

    {:ok, mpesa}
  end

  def apply_query_result(checkout_request_id, response) do
    mpesa = Mpesas.get_mpesa_by_checkout_request_id(checkout_request_id)

    cond do
      is_nil(mpesa) ->
        {:error, :not_found}

      query_successful?(response) ->
        Mpesas.update_mpesa(mpesa, %{
          "payment_pending" => false,
          "is_successful" => true,
          "description" => query_description(response),
          "result_code" => query_result_code(response),
          "merchant_request_id" => response["MerchantRequestID"] || mpesa.merchant_request_id,
          "checkout_request_id" => response["CheckoutRequestID"] || mpesa.checkout_request_id
        })

      true ->
        Mpesas.update_mpesa(mpesa, %{
          "payment_pending" => false,
          "description" => query_description(response),
          "result_code" => query_result_code(response),
          "merchant_request_id" => response["MerchantRequestID"] || mpesa.merchant_request_id,
          "checkout_request_id" => response["CheckoutRequestID"] || mpesa.checkout_request_id
        })
    end
  end

  def mark_linked_record_paid(mpesa) do
    status = Mpesas.actionable_payment_status(mpesa)

    cond do
      mpesa.is_successful != true ->
        {:error, :mpesa_not_successful}

      status.paid ->
        {:ok, :already_paid}

      true ->
        handle_after_action(mpesa.actionable_type, mpesa.actionable_id, mpesa)
        {:ok, :marked_paid}
    end
  end

  defp query_successful?(response), do: query_result_code(response) == 0

  defp query_result_code(response) do
    response
    |> Map.get("ResultCode", response["result_code"])
    |> normalize_result_code()
  end

  defp normalize_result_code(code) when is_integer(code), do: code

  defp normalize_result_code(code) when is_binary(code) do
    case Integer.parse(code) do
      {value, ""} -> value
      _ -> nil
    end
  end

  defp normalize_result_code(_code), do: nil

  defp query_description(response) do
    response["ResultDesc"] || response["errorMessage"] || response["ResponseDescription"] ||
      "M-Pesa query completed"
  end

  defp extract_value(body, key) do
    body["stkCallback"]["CallbackMetadata"]["Item"]
    |> Enum.find(fn item -> item["Name"] == key end)
    |> Map.get("Value")
  end

  # Send receipt email based on payment type (M-Pesa)
  defp send_receipt_email(actionable_type, actionable_id, mpesa) do
    {_title, service_details, patient_id, visit_reference} =
      get_service_details(actionable_type, actionable_id)

    patient = Patients.get_patient!(patient_id)

    receipt_data = %{
      service_details: service_details,
      amount: mpesa.amount,
      receipt_number: mpesa.receipt,
      transaction_date: mpesa.transactiondate,
      phone_number: mpesa.account_number,
      visit_reference: visit_reference
    }

    Postal.deliver_purchase_receipt(patient.email, receipt_data)
  end

  # Send receipt email for wallet-paid admission (and other wallet payables if needed)
  defp send_wallet_receipt_email("create_admission_request", actionable_id, amount) do
    send_wallet_receipt_for_actionable("create_admission_request", actionable_id, amount)
  end

  defp send_wallet_receipt_email("admission_line_item", actionable_id, amount) do
    send_wallet_receipt_for_actionable("admission_line_item", actionable_id, amount)
  end

  defp send_wallet_receipt_email("patient_charge_batch", actionable_id, amount) do
    send_wallet_receipt_for_actionable("patient_charge_batch", actionable_id, amount)
  end

  defp send_wallet_receipt_email(_actionable_type, _actionable_id, _amount), do: :ok

  defp send_wallet_receipt_for_actionable(actionable_type, actionable_id, amount) do
    {_title, service_details, patient_id, _ref} =
      get_service_details(actionable_type, actionable_id)

    patient = Patients.get_patient!(patient_id)
    ts = System.system_time(:second)

    receipt_data = %{
      service_details: service_details,
      amount: amount,
      receipt_number: "WALLET-#{actionable_type}-#{actionable_id}-#{ts}",
      transaction_date: Integer.to_string(ts),
      phone_number: "N/A",
      payment_method: "Wallet"
    }

    Postal.deliver_purchase_receipt(patient.email, receipt_data)
  end

  # Helper to get service details for the receipt
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

  defp patient_visit_service_details(%{visit_type: "Full"}), do: "General Consultation"
  defp patient_visit_service_details(%{visit_type: nil}), do: "General Consultation"
  defp patient_visit_service_details(%{visit_type: ""}), do: "General Consultation"
  defp patient_visit_service_details(%{visit_type: visit_type}), do: visit_type

  def handle_after_action_for_wallet(actionable_type, actionable_id, price) do
    mpesa = %{amount: price}

    case actionable_type do
      "create_patient_visit" ->
        handle_after_action("create_patient_visit", actionable_id, mpesa)

      "create_patient_visit_for_triage" ->
        handle_after_action("create_patient_visit_for_triage", actionable_id, mpesa)

      "create_patient_visit_subsidized" ->
        handle_after_action("create_patient_visit_subsidized", actionable_id, mpesa)

      "create_admission_request" ->
        handle_after_action("create_admission_request", actionable_id, mpesa)
        send_wallet_receipt_email(actionable_type, actionable_id, price)

      "admission_line_item" ->
        handle_after_action("admission_line_item", actionable_id, mpesa)
        send_wallet_receipt_email(actionable_type, actionable_id, price)

      "create_room_allocation" ->
        handle_after_action("create_room_allocation", actionable_id, mpesa)

      "create_lab_result" ->
        handle_after_action("create_lab_result", actionable_id, mpesa)

      "create_radiology_result" ->
        handle_after_action("create_radiology_result", actionable_id, mpesa)

      "create_nurse_procedure" ->
        handle_after_action("create_nurse_procedure", actionable_id, mpesa)

      "create_doctor_procedure" ->
        handle_after_action("create_doctor_procedure", actionable_id, mpesa)

      "create_wallet_deposit" ->
        handle_after_action("create_wallet_deposit", actionable_id, mpesa)

      "create_drug_allocation" ->
        handle_after_action("create_drug_allocation", actionable_id, mpesa)

      "patient_charge_batch" ->
        handle_after_action("patient_charge_batch", actionable_id, mpesa)
        send_wallet_receipt_email(actionable_type, actionable_id, price)

      _ ->
        :ok
    end
  end

  # Existing handle_after_action functions
  def handle_after_action("create_patient_visit", id, mpesa) do
    patient_visit = PatientVisits.get_patient_visit!(id)

    PatientVisits.update_patient_visit(patient_visit, %{
      "has_paid" => true,
      "total_amount_paid" => mpesa.amount
    })
  end

  def handle_after_action("create_patient_visit_for_triage", id, mpesa) do
    patient_visit = PatientVisits.get_patient_visit!(id)

    PatientVisits.update_patient_visit(patient_visit, %{
      "has_paid" => true,
      "total_amount_paid" => mpesa.amount
    })
  end

  def handle_after_action("create_patient_visit_subsidized", id, mpesa) do
    patient_visit = PatientVisits.get_patient_visit!(id)

    PatientVisits.update_patient_visit(patient_visit, %{
      "has_paid" => true,
      "total_amount_paid" => mpesa.amount
    })
  end

  def handle_after_action("create_admission_request", id, mpesa) do
    admission_request = AdmissionRequests.get_admission_request!(id)
    total_due = AdmissionRequests.total_line_items_amount(id)
    prev_paid = admission_request.total_amount_paid || 0
    new_total = prev_paid + mpesa.amount
    fully_paid = total_due == 0 or new_total >= total_due

    AdmissionRequests.update_admission_request(admission_request, %{
      "has_paid" => true,
      "total_amount_paid" => new_total,
      "fully_paid" => fully_paid
    })
  end

  def handle_after_action("admission_line_item", id, mpesa) do
    AdmissionRequests.add_line_item_payment(id, mpesa.amount)
  end

  def handle_after_action("create_room_allocation", id, mpesa) do
    room_allocation = RoomAllocations.get_room_allocation!(id)

    RoomAllocations.update_room_allocation(room_allocation, %{
      "has_paid" => true,
      "total_amount_paid" => mpesa.amount
    })
  end

  def handle_after_action("create_lab_result", id, mpesa) do
    lab_result = LabResults.get_lab_result!(id)

    LabResults.update_lab_result(lab_result, %{
      "has_paid" => true,
      "total_amount_paid" => mpesa.amount
    })
  end

  def handle_after_action("create_radiology_result", id, mpesa) do
    radiology_result = RadiologyResults.get_radiology_result!(id)

    RadiologyResults.update_radiology_result(radiology_result, %{
      "has_paid" => true,
      "total_amount_paid" => mpesa.amount
    })
  end

  def handle_after_action("create_nurse_procedure", id, mpesa) do
    nurse_procedure = NurseProcedures.get_nurse_procedure!(id)

    NurseProcedures.update_nurse_procedure(nurse_procedure, %{
      "has_paid" => true,
      "total_amount_paid" => mpesa.amount
    })
  end

  def handle_after_action("create_doctor_procedure", id, mpesa) do
    doctor_procedure = DoctorProcedures.get_doctor_procedure!(id)

    DoctorProcedures.update_doctor_procedure(doctor_procedure, %{
      "has_paid" => true,
      "total_amount_paid" => mpesa.amount
    })
  end

  def handle_after_action("create_wallet_deposit", id, mpesa) do
    wallet_deposit = Medcamp.WalletDeposits.get_wallet_deposit!(id)

    WalletDeposits.update_wallet_deposit(wallet_deposit, %{
      "has_been_paid" => true,
      "amount" => mpesa.amount
    })

    :ok
  end

  def handle_after_action("create_drug_allocation", id, mpesa) do
    drug_allocation = DrugAllocations.get_drug_allocation!(id)

    DrugAllocations.update_drug_allocation(drug_allocation, %{
      has_been_assigned: true,
      total_amount_paid: mpesa.amount,
      has_paid: true
    })
  end

  def handle_after_action("patient_charge_batch", id, _mpesa) do
    batch = PatientCharges.get_patient_charge_batch!(id)
    PatientCharges.mark_batch_paid(batch)
  end
end
