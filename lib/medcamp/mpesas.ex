defmodule Medcamp.Mpesas do
  @moduledoc """
  The Mpesas context.
  """

  import Ecto.Query, warn: false
  alias Medcamp.Repo

  alias Medcamp.Mpesas.Mpesa
  alias Medcamp.PatientVisits
  alias Medcamp.RoomAllocations
  alias Medcamp.NurseProcedures
  alias Medcamp.AdmissionRequests
  alias Medcamp.DoctorProcedures
  alias Medcamp.PatientCharges
  alias Medcamp.DrugAllocations
  alias Medcamp.LabResults
  alias Medcamp.RadiologyResults
  alias Medcamp.WalletDeposits
  alias Medcamp.Procedures

  @doc """
  Returns the list of mpesas.

  ## Examples

      iex> list_mpesas()
      [%Mpesa{}, ...]

  """
  def list_mpesas do
    Repo.all(Mpesa)
  end

  def get_mpesa_by_receipt(receipt) do
    Repo.get_by(Mpesa, receipt: receipt)
  end

  def get_mpesa_by_checkout_request_id(checkout_request_id) do
    Repo.get_by(Mpesa, checkout_request_id: checkout_request_id)
  end

  def get_mpesa_reconciliation_result(term) when is_binary(term) do
    search = String.trim(term)

    Mpesa
    |> where(
      [m],
      m.receipt == ^search or m.checkout_request_id == ^search or
        m.merchant_request_id == ^search
    )
    |> limit(1)
    |> Repo.one()
    |> preload_payment_details()
  end

  def get_mpesa_reconciliation_result(_term), do: nil

  def get_mpesa_reconciliation_result_by_id(id) do
    id
    |> get_mpesa!()
    |> preload_payment_details()
  end

  def list_mpesa_reconciliation_results(term, limit \\ 10)

  def list_mpesa_reconciliation_results(term, limit) when is_binary(term) do
    search = String.trim(term)
    phone_terms = normalize_phone_search_terms(search)

    Mpesa
    |> where(^reconciliation_search_dynamic(search, phone_terms))
    |> order_by([m], desc: m.inserted_at)
    |> limit(^limit)
    |> Repo.all()
    |> preload_payment_details()
  end

  def list_mpesa_reconciliation_results(_term, _limit), do: []

  defp normalize_phone_search_terms(search) do
    digits = String.replace(search, ~r/\D/, "")

    if String.length(digits) >= 7 do
      digits
      |> phone_search_variants()
      |> Enum.uniq()
    else
      []
    end
  end

  defp phone_search_variants("0" <> rest = digits) do
    [digits, rest, "254" <> rest]
  end

  defp phone_search_variants("254" <> rest = digits) do
    [digits, rest, "0" <> rest]
  end

  defp phone_search_variants(digits) when byte_size(digits) == 9 do
    [digits, "254" <> digits, "0" <> digits]
  end

  defp phone_search_variants(digits), do: [digits]

  defp reconciliation_search_dynamic(search, phone_terms) do
    base =
      dynamic(
        [m],
        m.receipt == ^search or m.checkout_request_id == ^search or
          m.merchant_request_id == ^search or
          ilike(m.phone, ^"%#{search}%") or
          ilike(m.account_number, ^"%#{search}%")
      )

    Enum.reduce(phone_terms, base, fn term, dynamic ->
      dynamic(
        [m],
        ^dynamic or ilike(m.phone, ^"%#{term}%") or ilike(m.account_number, ^"%#{term}%")
      )
    end)
  end

  def get_mpesa_search_results(search_term) do
    Repo.all(
      from(u in Mpesa,
        where:
          fragment("? LIKE ?", u.account_number, ^"%#{search_term}%") or
            fragment("? LIKE ?", u.amount, ^"%#{search_term}%") or
            fragment("? LIKE ?", u.confirmed, ^"%#{search_term}%") or
            fragment("? LIKE ?", u.description, ^"%#{search_term}%") or
            fragment("? LIKE ?", u.phone, ^"%#{search_term}%") or
            fragment("? LIKE ?", u.receipt, ^"%#{search_term}%") or
            fragment("? LIKE ?", u.transactiondate, ^"%#{search_term}%")
      )
    )
  end

  @doc """
  Gets a single mpesa.

  Raises `Ecto.NoResultsError` if the Mpesa does not exist.

  ## Examples

      iex> get_mpesa!(123)
      %Mpesa{}

      iex> get_mpesa!(456)
      ** (Ecto.NoResultsError)

  """
  def get_mpesa!(id), do: Repo.get!(Mpesa, id)

  def list_successful_payments do
    successful_payments_query()
    |> Repo.all()
    |> preload_successful_payments()
  end

  def list_successful_payments_paginated(page \\ 1, per_page \\ 20, search \\ "") do
    successful_payments_query()
    |> apply_payment_search(search)
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> preload_successful_payments()
  end

  def count_successful_payments(search \\ "") do
    successful_payments_query()
    |> apply_payment_search(search)
    |> exclude(:order_by)
    |> select([u], count(u.id))
    |> Repo.one()
  end

  defp apply_payment_search(query, ""), do: query

  defp apply_payment_search(query, search) do
    term = "%#{search}%"

    query
    |> join(:left, [u], p in assoc(u, :patient))
    |> where(
      [u, p],
      ilike(u.account_number, ^term) or
        ilike(u.receipt, ^term) or
        ilike(p.first_name, ^term) or
        ilike(p.last_name, ^term)
    )
  end

  defp add_actionable_label(payment) do
    label = actionable_display_label(payment.actionable_type, payment.actionable_id)
    Map.put(payment, :actionable_label, label)
  end

  @doc """
  Returns a human-readable display label for a payment's actionable_type + actionable_id.
  Used in dashboards to show e.g. "Hospital Admission (12 Jan 2026)" instead of "create_admission_request #123".
  """
  def actionable_display_label(actionable_type, actionable_id)
      when is_binary(actionable_type) and is_integer(actionable_id) do
    case do_actionable_display_label(actionable_type, actionable_id) do
      {:ok, label} -> label
      _ -> format_fallback(actionable_type, actionable_id)
    end
  end

  def actionable_display_label(actionable_type, actionable_id),
    do: format_fallback(actionable_type, actionable_id)

  defp format_fallback(type, id), do: "#{type} ##{id}"

  defp do_actionable_display_label("create_patient_visit", id) do
    PatientVisits.get_patient_visit!(id)
    {:ok, "General Consultation"}
  rescue
    Ecto.NoResultsError -> :error
  end

  defp do_actionable_display_label("create_patient_visit_for_triage", id) do
    PatientVisits.get_patient_visit!(id)
    {:ok, "Triage"}
  rescue
    Ecto.NoResultsError -> :error
  end

  defp do_actionable_display_label("create_admission_request", id) do
    admission = AdmissionRequests.get_admission_request!(id)

    label =
      if admission.date,
        do: "Hospital Admission (#{Calendar.strftime(admission.date, "%d %b %Y")})",
        else: "Hospital Admission"

    {:ok, label}
  rescue
    Ecto.NoResultsError -> :error
  end

  defp do_actionable_display_label("admission_line_item", id) do
    line_item = AdmissionRequests.get_line_item_with_admission!(id)
    admission = line_item.admission_request
    type_label = AdmissionRequests.LineItem.item_type_label(line_item.item_type)

    label =
      if admission && admission.date,
        do: "Admission – #{type_label} (#{Calendar.strftime(admission.date, "%d %b %Y")})",
        else: "Admission – #{type_label}"

    {:ok, label}
  rescue
    Ecto.NoResultsError -> :error
  end

  defp do_actionable_display_label("create_room_allocation", id) do
    allocation = RoomAllocations.get_room_allocation!(id)
    {:ok, "#{allocation.ward_name} - #{allocation.bed_number}"}
  rescue
    Ecto.NoResultsError -> :error
  end

  defp do_actionable_display_label("create_lab_result", _id) do
    {:ok, "Laboratory Test"}
  rescue
    Ecto.NoResultsError -> :error
  end

  defp do_actionable_display_label("create_radiology_result", _id) do
    {:ok, "Radiology Service"}
  rescue
    Ecto.NoResultsError -> :error
  end

  defp do_actionable_display_label("create_nurse_procedure", id) do
    np = NurseProcedures.get_nurse_procedure!(id)
    name = Procedures.service_name(np, "Nursing Procedure")
    {:ok, "Nursing – #{name}"}
  rescue
    Ecto.NoResultsError -> :error
  end

  defp do_actionable_display_label("create_doctor_procedure", id) do
    dp = DoctorProcedures.get_doctor_procedure!(id)
    name = Procedures.service_name(dp, "Doctor Procedure")
    {:ok, "Doctor – #{name}"}
  rescue
    Ecto.NoResultsError -> :error
  end

  defp do_actionable_display_label("create_drug_allocation", _id) do
    {:ok, "Pharmacy / Drugs"}
  rescue
    Ecto.NoResultsError -> :error
  end

  defp do_actionable_display_label("create_wallet_deposit", _id) do
    {:ok, "Wallet Deposit"}
  rescue
    Ecto.NoResultsError -> :error
  end

  defp do_actionable_display_label("patient_charge_batch", id) do
    batch = PatientCharges.get_patient_charge_batch!(id)
    {:ok, PatientCharges.charge_batch_service_label(batch)}
  rescue
    Ecto.NoResultsError -> :error
  end

  defp do_actionable_display_label(_type, _id), do: :error

  def actionable_payment_status(%Mpesa{} = mpesa) do
    do_actionable_payment_status(mpesa.actionable_type, mpesa.actionable_id)
  rescue
    Ecto.NoResultsError ->
      %{
        label: actionable_display_label(mpesa.actionable_type, mpesa.actionable_id),
        paid: false,
        amount_paid: nil,
        detail: "Linked record was not found"
      }
  end

  defp do_actionable_payment_status("create_patient_visit", id) do
    visit = PatientVisits.get_patient_visit!(id)
    status_from_record("Patient Visit", visit.has_paid, visit.total_amount_paid)
  end

  defp do_actionable_payment_status("create_patient_visit_for_triage", id) do
    visit = PatientVisits.get_patient_visit!(id)
    status_from_record("Triage Visit", visit.has_paid, visit.total_amount_paid)
  end

  defp do_actionable_payment_status("create_patient_visit_subsidized", id) do
    visit = PatientVisits.get_patient_visit!(id)
    status_from_record("Subsidized Visit", visit.has_paid, visit.total_amount_paid)
  end

  defp do_actionable_payment_status("create_admission_request", id) do
    admission = AdmissionRequests.get_admission_request!(id)

    %{
      label: "Hospital Admission",
      paid: admission.has_paid == true,
      amount_paid: admission.total_amount_paid,
      detail: if(admission.fully_paid, do: "Fully paid", else: "Partially paid or unpaid")
    }
  end

  defp do_actionable_payment_status("admission_line_item", id) do
    line_item = AdmissionRequests.get_line_item_with_admission!(id)
    paid = (line_item.amount_paid || 0) >= (line_item.price || 0)

    %{
      label: "Admission - #{AdmissionRequests.LineItem.item_type_label(line_item.item_type)}",
      paid: paid,
      amount_paid: line_item.amount_paid,
      detail: "Line item price: #{line_item.price || 0} KES"
    }
  end

  defp do_actionable_payment_status("create_room_allocation", id) do
    allocation = RoomAllocations.get_room_allocation!(id)
    status_from_record("Room Allocation", allocation.has_paid, allocation.total_amount_paid)
  end

  defp do_actionable_payment_status("create_lab_result", id) do
    lab_result = LabResults.get_lab_result!(id)
    status_from_record("Laboratory Test", lab_result.has_paid, lab_result.total_amount_paid)
  end

  defp do_actionable_payment_status("create_radiology_result", id) do
    radiology_result = RadiologyResults.get_radiology_result!(id)

    status_from_record(
      "Radiology Service",
      radiology_result.has_paid,
      radiology_result.total_amount_paid
    )
  end

  defp do_actionable_payment_status("create_nurse_procedure", id) do
    procedure = NurseProcedures.get_nurse_procedure!(id)
    status_from_record("Nursing Procedure", procedure.has_paid, procedure.total_amount_paid)
  end

  defp do_actionable_payment_status("create_doctor_procedure", id) do
    procedure = DoctorProcedures.get_doctor_procedure!(id)
    status_from_record("Doctor Procedure", procedure.has_paid, procedure.total_amount_paid)
  end

  defp do_actionable_payment_status("create_drug_allocation", id) do
    allocation = DrugAllocations.get_drug_allocation!(id)
    status_from_record("Pharmacy / Drugs", allocation.has_paid, allocation.total_amount_paid)
  end

  defp do_actionable_payment_status("create_wallet_deposit", id) do
    deposit = WalletDeposits.get_wallet_deposit!(id)
    status_from_record("Wallet Deposit", deposit.has_been_paid, deposit.amount)
  end

  defp do_actionable_payment_status("patient_charge_batch", id) do
    batch = PatientCharges.get_patient_charge_batch!(id)

    %{
      label: PatientCharges.charge_batch_service_label(batch),
      paid: batch.status == "paid",
      amount_paid: batch.total_amount,
      detail: "Batch status: #{batch.status}"
    }
  end

  defp do_actionable_payment_status(type, id) do
    %{
      label: actionable_display_label(type, id),
      paid: false,
      amount_paid: nil,
      detail: "No linked payment status reader for #{type}"
    }
  end

  defp status_from_record(label, paid, amount_paid) do
    %{
      label: label,
      paid: paid == true,
      amount_paid: amount_paid,
      detail: if(paid == true, do: "Marked paid", else: "Not marked paid")
    }
  end

  def total_successful_payments do
    Repo.one(from u in Mpesa, where: u.is_successful == true, select: sum(u.amount))
  end

  def list_successful_payments_by_patient(patient_id) do
    Repo.all(
      from u in Mpesa,
        where: u.is_successful == true and u.patient_id == ^patient_id,
        order_by: [desc: u.inserted_at]
    )
    |> Repo.preload(:patient)
    |> Repo.preload(:prompter)
    |> Enum.map(&add_actionable_label/1)
  end

  def list_successful_payments_by_patient_paginated(patient_id, page \\ 1, per_page \\ 10) do
    from(u in Mpesa,
      where: u.is_successful == true and u.patient_id == ^patient_id,
      order_by: [desc: u.inserted_at]
    )
    |> Repo.paginate(page: page, page_size: per_page)
    |> Map.get(:entries)
    |> Repo.preload(:patient)
    |> Repo.preload(:prompter)
    |> Enum.map(&add_actionable_label/1)
  end

  def count_successful_payments_by_patient(patient_id) do
    from(u in Mpesa, where: u.is_successful == true and u.patient_id == ^patient_id)
    |> Repo.aggregate(:count, :id)
  end

  @doc """
  Creates a mpesa.

  ## Examples

      iex> create_mpesa(%{field: value})
      {:ok, %Mpesa{}}

      iex> create_mpesa(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_mpesa(attrs \\ %{}) do
    %Mpesa{}
    |> Mpesa.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a successful Mpesa record for a wallet payment.
  Used when payment is completed via "Pay from Wallet" so the payment
  appears in Mpesa reporting (is_successful: true, payment_pending: false).
  Uses placeholder checkout_request_id/merchant_request_id since no STK push occurred.
  """
  def create_mpesa_for_wallet(attrs) do
    uuid = Ecto.UUID.generate()

    base =
      attrs
      |> Map.new()
      |> Map.put("is_successful", true)
      |> Map.put("payment_pending", false)
      |> Map.put("checkout_request_id", "WALLET-#{uuid}")
      |> Map.put("merchant_request_id", "WALLET-#{uuid}")

    create_mpesa(base)
  end

  @doc """
  Updates a mpesa.

  ## Examples

      iex> update_mpesa(mpesa, %{field: new_value})
      {:ok, %Mpesa{}}

      iex> update_mpesa(mpesa, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_mpesa(%Mpesa{} = mpesa, attrs) do
    mpesa
    |> Mpesa.changeset(attrs)
    |> Repo.audited_update()
  end

  defp successful_payments_query do
    from u in Mpesa, where: u.is_successful == true, order_by: [desc: u.inserted_at]
  end

  defp preload_successful_payments(payments) do
    payments
    |> Repo.preload(:patient)
    |> Repo.preload(:prompter)
    |> Enum.map(&add_actionable_label/1)
  end

  defp preload_payment_details(nil), do: nil

  defp preload_payment_details(payments) when is_list(payments) do
    payments
    |> Repo.preload(:patient)
    |> Repo.preload(:prompter)
    |> Enum.map(&add_actionable_label/1)
  end

  defp preload_payment_details(payment) do
    payment
    |> Repo.preload(:patient)
    |> Repo.preload(:prompter)
    |> add_actionable_label()
  end

  @doc """
  Deletes a mpesa.

  ## Examples

      iex> delete_mpesa(mpesa)
      {:ok, %Mpesa{}}

      iex> delete_mpesa(mpesa)
      {:error, %Ecto.Changeset{}}

  """
  def delete_mpesa(%Mpesa{} = mpesa) do
    Repo.delete(mpesa)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking mpesa changes.

  ## Examples

      iex> change_mpesa(mpesa)
      %Ecto.Changeset{data: %Mpesa{}}

  """
  def change_mpesa(%Mpesa{} = mpesa, attrs \\ %{}) do
    Mpesa.changeset(mpesa, attrs)
  end

  def change_trigger_mpesa(%Mpesa{} = mpesa, attrs \\ %{}) do
    Mpesa.trigger_changeset(mpesa, attrs)
  end
end
