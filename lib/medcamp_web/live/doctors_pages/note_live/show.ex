defmodule MedcampWeb.DoctorsPagePatientLive.DoctorNoteShow do
  use MedcampWeb, :each_patient_live_view
  require Logger
  alias Medcamp.Patients
  alias Medcamp.DoctorNotes
  alias Medcamp.LabResults
  alias Medcamp.LabTestTemplates
  alias Medcamp.LabResults.LabResult
  alias Medcamp.DrugAllocations.DrugAllocation
  alias Medcamp.RadiologyResults.RadiologyResult
  alias Medcamp.DrugAllocations
  alias Medcamp.Referrals
  alias Medcamp.AdmissionRequests
  alias Medcamp.PatientCharges
  alias Medcamp.RadiologyResults
  alias Medcamp.Inpatient
  alias Medcamp.AIDocReviewer

  @admission_detail_live_actions [
    :new_continuation,
    :new_treatment,
    :edit_treatment,
    :new_vitals,
    :new_discharge,
    :new_cadex,
    :edit_cadex
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :doctor_notes)
     |> assign(:current_tab, "overview")
     |> assign(:inpatient_subtab, "admission")
     |> assign(:note_path, nil)
     |> assign(:view_lab_report_entry, nil)
     |> assign(:view_lab_report_template, nil)
     |> assign(:view_lab_report_lab_result, nil)
     |> assign(:view_lab_report_patient, nil)
     |> assign(:view_lab_report_doctor, nil)
     |> assign(:show_sub_note_modal, false)
     |> assign(:sub_note_form, nil)
     |> assign(:expanded_sub_note_ids, [])
     |> assign(:main_note_expanded, true)
     |> assign(:patient_charge_batch, nil)
     |> assign(:ai_review_loading, false)
     |> stream(:doctor_notes, DoctorNotes.list_doctor_notes())}
  end

  @impl true
  def handle_params(%{"id" => id, "note_id" => note_id} = params, _url, socket) do
    patient = Patients.get_patient!(id)
    doctor_note = DoctorNotes.get_doctor_note!(note_id)

    if doctor_note.patient_id != patient.id do
      {:noreply,
       socket
       |> put_flash(:error, "That note could not be found for this patient.")
       |> push_navigate(to: "/doctor/patients/#{patient.id}/notes")}
    else
      handle_valid_params(patient, doctor_note, params, socket)
    end
  end

  defp handle_valid_params(patient, doctor_note, params, socket) do
    note_path = "/doctor/patients/#{patient.id}/notes/#{doctor_note.id}"
    current_tab = valid_tab(params["tab"])
    inpatient_subtab = valid_inpatient_subtab(params["subtab"])
    live_action = socket.assigns.live_action

    needs_current_admission? =
      current_tab == "inpatient" or live_action in @admission_detail_live_actions

    current_admission =
      if needs_current_admission?, do: Inpatient.get_current_admission(patient.id), else: nil

    {view_entry, view_template, view_lab_result, view_patient, view_doctor} =
      resolve_view_lab_report(params, doctor_note, patient)

    {:noreply,
     socket
     |> assign(:patient, patient)
     |> assign(:note_path, note_path)
     |> assign(:view_lab_report_entry, view_entry)
     |> assign(:view_lab_report_template, view_template)
     |> assign(:view_lab_report_lab_result, view_lab_result)
     |> assign(:view_lab_report_patient, view_patient)
     |> assign(:view_lab_report_doctor, view_doctor)
     |> assign(
       :admission_requests,
       tab_dataset(current_tab, "admission", fn ->
         AdmissionRequests.list_admission_requests_by_doctor_note_id(doctor_note.id)
       end)
     )
     |> assign(
       :radiology_results,
       tab_dataset(current_tab, "radiology", fn ->
         RadiologyResults.list_radiology_results_by_doctor_note_id(doctor_note.id)
       end)
     )
     |> assign(
       :patient_charges,
       tab_dataset(current_tab, "charges", fn ->
         PatientCharges.list_patient_charges_for_doctor_note(doctor_note.id)
       end)
     )
     |> assign(
       :patient_charge_summary,
       tab_dataset(
         current_tab,
         "charges",
         fn -> PatientCharges.charge_summary_for_doctor_note(doctor_note.id) end,
         empty_charge_summary()
       )
     )
     |> assign(
       :referrals,
       tab_dataset(current_tab, "referral", fn ->
         Referrals.list_referrals_for_a_doctor_note(doctor_note.id)
       end)
     )
     |> assign(
       :drug_allocations,
       tab_dataset(current_tab, "medication", fn ->
         DrugAllocations.list_drug_allocations_for_a_doctor_note(doctor_note.id)
       end)
     )
     |> assign(
       :lab_results,
       tab_dataset(current_tab, "lab_work", fn ->
         LabResults.list_lab_results_for_doctor_note(doctor_note.id)
       end)
     )
     |> assign(:current_admission, current_admission)
     |> assign(
       :admission_notes,
       inpatient_dataset(current_tab, inpatient_subtab, "admission", fn ->
         Inpatient.list_admission_notes_for_patient(patient.id)
       end)
     )
     |> assign(
       :continuation_notes,
       inpatient_dataset(current_tab, inpatient_subtab, "continuation", fn ->
         continuation_notes_for(current_admission)
       end)
     )
     |> assign(
       :treatment_sheets,
       inpatient_dataset(current_tab, inpatient_subtab, "treatment", fn ->
         treatment_sheets_for(current_admission)
       end)
     )
     |> assign(
       :vital_records,
       inpatient_dataset(current_tab, inpatient_subtab, "vitals", fn ->
         vital_records_for(current_admission)
       end)
     )
     |> assign(
       :discharge_summary,
       inpatient_dataset(
         current_tab,
         inpatient_subtab,
         "discharge",
         fn -> discharge_summary_for(current_admission) end,
         nil
       )
     )
     |> assign(
       :cadex_notes,
       inpatient_dataset(current_tab, inpatient_subtab, "cadex", fn ->
         cadex_notes_for(current_admission)
       end)
     )
     |> assign_new(:form, fn -> to_form(DoctorNotes.change_doctor_note(doctor_note)) end)
     |> assign(:doctor_note, doctor_note)
     |> assign(:child_notes, DoctorNotes.get_child_notes_for_note(doctor_note.id))
     |> assign(:current_tab, current_tab)
     |> assign(:inpatient_subtab, inpatient_subtab)
     |> apply_action(live_action, params)
     |> then(fn s ->
       assign(s, :note_path_with_params, build_note_path_with_params(s.assigns))
     end)}
  end

  defp resolve_view_lab_report(%{"view_lab_report" => entry_id}, doctor_note, patient) do
    entry =
      try do
        LabTestTemplates.get_entry!(entry_id)
      rescue
        Ecto.NoResultsError -> nil
      end

    cond do
      entry == nil ->
        {nil, nil, nil, nil, nil}

      entry.lab_result == nil ->
        {nil, nil, nil, nil, nil}

      entry.lab_result.doctor_note_id != doctor_note.id ->
        {nil, nil, nil, nil, nil}

      entry.lab_result.patient_id != patient.id ->
        {nil, nil, nil, nil, nil}

      true ->
        lab_result = entry.lab_result
        template = entry.template
        {entry, template, lab_result, lab_result.patient, lab_result.doctor}
    end
  end

  defp resolve_view_lab_report(_params, _doctor_note, _patient), do: {nil, nil, nil, nil, nil}

  defp tab_dataset(current_tab, target_tab, fetch_fun, default \\ []) do
    if current_tab == target_tab, do: fetch_fun.(), else: default
  end

  defp inpatient_dataset(current_tab, inpatient_subtab, subtab_name, fetch_fun, default \\ []) do
    if current_tab == "inpatient" and inpatient_subtab == subtab_name do
      fetch_fun.()
    else
      default
    end
  end

  defp continuation_notes_for(nil), do: []

  defp continuation_notes_for(admission),
    do: Inpatient.list_continuation_notes_for_admission(admission.id)

  defp treatment_sheets_for(nil), do: []

  defp treatment_sheets_for(admission),
    do: Inpatient.list_treatment_sheets_for_admission(admission.id)

  defp vital_records_for(nil), do: []
  defp vital_records_for(admission), do: Inpatient.list_vital_records_for_admission(admission.id)

  defp discharge_summary_for(nil), do: nil

  defp discharge_summary_for(admission),
    do: Inpatient.get_discharge_summary_for_admission(admission.id)

  defp cadex_notes_for(nil), do: []

  defp cadex_notes_for(admission),
    do: Medcamp.CadexNotes.list_cadex_notes_for_admission(admission.id)

  defp empty_charge_summary do
    %{
      total_count: 0,
      pending_review_count: 0,
      approved_count: 0,
      approved_unpaid_count: 0,
      approved_unpaid_total: 0,
      paid_count: 0,
      paid_total: 0,
      waived_count: 0
    }
  end

  defp valid_tab(nil), do: "overview"

  defp valid_tab(tab)
       when tab in ~w(overview ai_review charges lab_work radiology medication inpatient admission referral),
       do: tab

  defp valid_tab(_), do: "overview"

  defp valid_inpatient_subtab(nil), do: "admission"

  defp valid_inpatient_subtab(st)
       when st in ~w(admission continuation treatment vitals discharge cadex),
       do: st

  defp valid_inpatient_subtab(_), do: "admission"

  defp build_note_path_with_params(assigns) do
    base = Map.get(assigns, :note_path)
    tab = Map.get(assigns, :current_tab) || "overview"
    subtab = Map.get(assigns, :inpatient_subtab) || "admission"
    if base, do: base <> "?tab=#{tab}&subtab=#{subtab}", else: "#"
  end

  # ... (keep existing apply_action functions) ...

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Add Doctor notes")
    |> assign(:admission_request_for_line_items, nil)
    |> assign(:admission_request_trigger_payment, nil)
    |> assign(:line_item_for_trigger, nil)
  end

  defp apply_action(socket, :after_create, _params) do
    socket |> assign(:page_title, "Listing Doctor notes") |> assign(:live_action, :after_create)
  end

  defp apply_action(socket, :request_lab, _params) do
    socket |> assign(:page_title, "Listing Doctor notes") |> assign(:live_action, :request_lab)
  end

  defp apply_action(socket, :request_radiology_test, _params) do
    socket
    |> assign(:page_title, "Request radiology test")
    |> assign(:live_action, :request_radiology_test)
  end

  defp apply_action(socket, :prescribe_drug, _params) do
    socket |> assign(:page_title, "Listing Doctor notes") |> assign(:live_action, :prescribe_drug)
  end

  defp apply_action(socket, :refer_patient, _params) do
    socket |> assign(:page_title, "Refer Patient") |> assign(:live_action, :refer_patient)
  end

  defp apply_action(socket, :admit_patient, _params) do
    socket |> assign(:page_title, "Admit Patient") |> assign(:live_action, :admit_patient)
  end

  defp apply_action(socket, :line_items, %{"admission_id" => admission_id}) do
    admission_request = AdmissionRequests.get_admission_request!(admission_id)
    admission_request = Medcamp.Repo.preload(admission_request, :line_items)

    socket
    |> assign(:page_title, "Line items / costs")
    |> assign(:live_action, :line_items)
    |> assign(:admission_request_for_line_items, admission_request)
  end

  defp apply_action(socket, :line_items, _params), do: apply_action(socket, :index, nil)

  defp apply_action(socket, :trigger_payment, %{"admission_id" => admission_id}) do
    admission_request = AdmissionRequests.get_admission_request_with_line_items!(admission_id)

    socket
    |> assign(:page_title, "Prompt payment – Admission")
    |> assign(:live_action, :trigger_payment)
    |> assign(:admission_request_trigger_payment, admission_request)
    |> assign(:line_item_for_trigger, nil)
  end

  defp apply_action(socket, :trigger_payment, _params), do: apply_action(socket, :index, nil)

  defp apply_action(socket, :trigger_payment_line_item, %{
         "admission_id" => _aid,
         "line_item_id" => line_item_id
       }) do
    line_item = AdmissionRequests.get_line_item_with_admission!(line_item_id)

    socket
    |> assign(
      :page_title,
      "Prompt payment – #{AdmissionRequests.LineItem.item_type_label(line_item.item_type)}"
    )
    |> assign(:live_action, :trigger_payment_line_item)
    |> assign(:line_item_for_trigger, line_item)
    |> assign(:admission_request_trigger_payment, nil)
  end

  defp apply_action(socket, :trigger_payment_line_item, _params),
    do: apply_action(socket, :index, nil)

  defp apply_action(socket, :trigger_patient_charge_payment, _params) do
    case PatientCharges.prepare_payment_batch_for_doctor_note(
           socket.assigns.doctor_note.id,
           socket.assigns.current_user.id
         ) do
      {:ok, patient_charge_batch} ->
        socket
        |> assign(:page_title, "Prompt payment – Emergency Nursing Charges")
        |> assign(:live_action, :trigger_patient_charge_payment)
        |> assign(:patient_charge_batch, patient_charge_batch)

      {:error, :no_approved_charges} ->
        socket
        |> put_flash(:error, "No approved emergency nursing charges are ready for payment.")
        |> assign(:patient_charge_batch, nil)
        |> assign(:live_action, :index)

      {:error, _reason} ->
        socket
        |> put_flash(:error, "Unable to prepare emergency nursing charges for payment right now.")
        |> assign(:patient_charge_batch, nil)
        |> assign(:live_action, :index)
    end
  end

  # NEW: Inpatient actions
  defp apply_action(socket, :new_admission, _params) do
    socket
    |> assign(:page_title, "New Admission")
    |> assign(:admission_note, %Medcamp.Inpatient.AdmissionNote{})
    |> assign(:live_action, :new_admission)
  end

  defp apply_action(socket, :new_continuation, _params) do
    socket
    |> assign(:page_title, "Add Continuation Note")
    |> assign(:continuation_note, %Medcamp.Inpatient.ContinuationNote{})
    |> assign(:live_action, :new_continuation)
  end

  defp apply_action(socket, :new_treatment, _params) do
    socket
    |> assign(:page_title, "Add Treatment")
    |> assign(:treatment_sheet, %Medcamp.Inpatient.TreatmentSheet{})
    |> assign(:live_action, :new_treatment)
  end

  defp apply_action(socket, :edit_treatment, %{"treatment_id" => treatment_id}) do
    treatment_sheet = Inpatient.get_treatment_sheet!(treatment_id)

    socket
    |> assign(:page_title, "Edit Treatment")
    |> assign(:treatment_sheet, treatment_sheet)
    |> assign(:live_action, :edit_treatment)
  end

  defp apply_action(socket, :new_vitals, _params) do
    socket
    |> assign(:page_title, "Record Vitals")
    |> assign(:vital_record, %Medcamp.Inpatient.VitalRecord{})
    |> assign(:live_action, :new_vitals)
  end

  defp apply_action(socket, :new_discharge, _params) do
    socket
    |> assign(:page_title, "Create Discharge Summary")
    |> assign(:discharge_summary_form, %Medcamp.Inpatient.DischargeSummary{})
    |> assign(:live_action, :new_discharge)
  end

  defp apply_action(socket, :new_cadex, _params) do
    socket
    |> assign(:page_title, "Add CaDex Note")
    |> assign(:cadex_note, %Medcamp.CadexNotes.CadexNote{})
    |> assign(:live_action, :new_cadex)
  end

  defp apply_action(socket, :edit_cadex, %{"cadex_id" => cadex_id}) do
    cadex_note = Medcamp.CadexNotes.get_cadex_note!(cadex_id)

    socket
    |> assign(:page_title, "Edit CaDex Note")
    |> assign(:cadex_note, cadex_note)
    |> assign(:live_action, :edit_cadex)
  end

  defp apply_action(socket, :assign_new_drug, %{"drug_allocation_id" => drug_allocation_id}) do
    drug_allocation = DrugAllocations.get_drug_allocation!(drug_allocation_id)

    socket
    |> assign(:page_title, "Add Drug")
    |> assign(:drug_allocation, drug_allocation)
    |> assign(:live_action, :assign_new_drug)
  end

  # ... (keep other existing apply_action functions) ...

  @impl true
  def handle_event("validate", %{"doctor_note" => doctor_note_params}, socket) do
    params = maybe_fill_diagnosis_from_icd(doctor_note_params)
    changeset = DoctorNotes.change_doctor_note(socket.assigns.doctor_note, params)
    {:noreply, socket |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("change-tab", %{"tab" => tab}, socket) do
    tab = valid_tab(tab)
    subtab = if tab == "inpatient", do: socket.assigns.inpatient_subtab, else: "admission"
    path = "#{socket.assigns.note_path}?tab=#{tab}&subtab=#{subtab}"
    {:noreply, push_patch(socket, to: path)}
  end

  def handle_event("change-inpatient-subtab", %{"subtab" => subtab}, socket) do
    subtab = valid_inpatient_subtab(subtab)
    path = "#{socket.assigns.note_path}?tab=inpatient&subtab=#{subtab}"
    {:noreply, push_patch(socket, to: path)}
  end

  def handle_event("refresh-interpretation", %{"id" => id}, socket) do
    case LabResults.refresh_lab_result_interpretation(String.to_integer(id)) do
      {:ok, _lab_result} ->
        lab_results =
          LabResults.list_lab_results_for_doctor_note(socket.assigns.doctor_note.id)

        {:noreply,
         socket
         |> assign(:lab_results, lab_results)
         |> put_flash(:info, "AI analysis regenerated")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Could not regenerate the analysis right now")}
    end
  end

  def handle_event("run_ai_review", _params, socket) do
    doctor_note = socket.assigns.doctor_note

    cond do
      socket.assigns.ai_review_loading ->
        {:noreply, socket}

      not has_ai_review_source_data?(doctor_note) ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "Add complaints, clinical notes, past medical history, impression, management, or investigations before running an AI review."
         )}

      true ->
        ai_client = ai_doc_reviewer_client()

        {:noreply,
         socket
         |> assign(:ai_review_loading, true)
         |> start_async(:run_ai_review, fn ->
           AIDocReviewer.refresh_doctor_note_review(doctor_note, ai_client)
         end)}
    end
  end

  # ... (keep all existing handle_event functions) ...

  def handle_event("save", %{"doctor_note" => doctor_note_params}, socket) do
    doctor_note_params =
      doctor_note_params
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> Map.put("doctor_id", socket.assigns.current_user.id)

    case DoctorNotes.update_doctor_note(socket.assigns.doctor_note, doctor_note_params) do
      {:ok, _doctor_note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Doctor note created successfully")
         |> push_event("draft_saved", %{})}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event(
        "delete_drug_assigned",
        %{"id" => id, "drug_allocation_id" => drug_allocation_id},
        socket
      ) do
    drug_allocation = DrugAllocations.get_drug_allocation!(drug_allocation_id)

    case DrugAllocations.remove_drug_assigned(drug_allocation, id) do
      {:ok, _updated_allocation} ->
        drug_allocations =
          DrugAllocations.list_drug_allocations_for_a_doctor_note(socket.assigns.doctor_note.id)

        {:noreply,
         socket
         |> assign(:drug_allocations, drug_allocations)
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

  def handle_event("delete_referral", %{"id" => id}, socket) do
    referral = Referrals.get_referral!(id)
    {:ok, _} = Referrals.delete_referral(referral)

    {:noreply,
     socket
     |> assign(
       :referrals,
       Referrals.list_referrals_for_a_doctor_note(socket.assigns.doctor_note.id)
     )
     |> put_flash(:info, "Referral deleted successfully")}
  end

  def handle_event("toggle_main_note", _params, socket) do
    {:noreply, assign(socket, :main_note_expanded, !socket.assigns.main_note_expanded)}
  end

  def handle_event("open_add_sub_note", _params, socket) do
    sub_note_changeset = DoctorNotes.change_doctor_note(%Medcamp.DoctorNotes.DoctorNote{})

    {:noreply,
     socket
     |> assign(:show_sub_note_modal, true)
     |> assign(:sub_note_form, to_form(sub_note_changeset, as: :sub_doctor_note))}
  end

  def handle_event("close_sub_note_modal", _params, socket) do
    {:noreply, assign(socket, :show_sub_note_modal, false)}
  end

  def handle_event("validate_sub_note", %{"sub_doctor_note" => params}, socket) do
    changeset = DoctorNotes.change_doctor_note(%Medcamp.DoctorNotes.DoctorNote{}, params)

    {:noreply,
     assign(socket, :sub_note_form, to_form(changeset, action: :validate, as: :sub_doctor_note))}
  end

  def handle_event("save_sub_note", %{"sub_doctor_note" => params}, socket) do
    attrs =
      params
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> Map.put("doctor_id", socket.assigns.current_user.id)
      |> Map.put("parent_id", socket.assigns.doctor_note.id)

    case DoctorNotes.create_child_doctor_note(attrs) do
      {:ok, _child_note} ->
        {:noreply,
         socket
         |> assign(:show_sub_note_modal, false)
         |> assign(
           :child_notes,
           DoctorNotes.get_child_notes_for_note(socket.assigns.doctor_note.id)
         )
         |> put_flash(:info, "Sub-note added successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :sub_note_form, to_form(changeset, as: :sub_doctor_note))}
    end
  end

  def handle_event("toggle_sub_note", %{"id" => id}, socket) do
    id = String.to_integer(id)
    expanded = socket.assigns.expanded_sub_note_ids

    new_expanded =
      if id in expanded do
        List.delete(expanded, id)
      else
        [id | expanded]
      end

    {:noreply, assign(socket, :expanded_sub_note_ids, new_expanded)}
  end

  def handle_event("delete_radiology", %{"id" => id}, socket) do
    radiology_result = RadiologyResults.get_radiology_result!(id)
    {:ok, _} = RadiologyResults.delete_radiology_result(radiology_result)

    {:noreply,
     socket
     |> assign(
       :radiology_results,
       RadiologyResults.list_radiology_results_by_doctor_note_id(socket.assigns.doctor_note.id)
     )
     |> put_flash(:info, "Radiology result deleted successfully")}
  end

  def handle_event("mark_admission_discharged", %{"id" => id}, socket) do
    admission_request = AdmissionRequests.get_admission_request!(id)

    case AdmissionRequests.update_admission_request(admission_request, %{
           "discharged" => true,
           "discharge_date" => Date.utc_today()
         }) do
      {:ok, _} ->
        admission_requests =
          AdmissionRequests.list_admission_requests_by_doctor_note_id(
            socket.assigns.doctor_note.id
          )

        {:noreply,
         socket
         |> assign(:admission_requests, admission_requests)
         |> put_flash(:info, "Admission marked as discharged")}

      {:error, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to mark as discharged")}
    end
  end

  def handle_event("delete_admission", %{"id" => id}, socket) do
    admission_request = AdmissionRequests.get_admission_request!(id)
    {:ok, _} = AdmissionRequests.delete_admission_request(admission_request)

    admission_requests =
      AdmissionRequests.list_admission_requests_by_doctor_note_id(socket.assigns.doctor_note.id)

    {:noreply,
     socket
     |> assign(:admission_requests, admission_requests)
     |> put_flash(:info, "Admission request deleted successfully")}
  end

  def handle_event("approve_patient_charge", %{"id" => id}, socket) do
    charge = PatientCharges.get_patient_charge!(id)

    case PatientCharges.approve_patient_charge(charge, socket.assigns.current_user.id) do
      {:ok, _charge} ->
        {:noreply,
         socket
         |> reload_patient_charges()
         |> put_flash(:info, "Charge approved for payment")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Unable to approve this charge")}
    end
  end

  def handle_event("waive_patient_charge", %{"id" => id}, socket) do
    charge = PatientCharges.get_patient_charge!(id)

    case PatientCharges.waive_patient_charge(charge, socket.assigns.current_user.id) do
      {:ok, _charge} ->
        {:noreply,
         socket
         |> reload_patient_charges()
         |> put_flash(:info, "Charge waived")}

      {:error, _reason} ->
        {:noreply, put_flash(socket, :error, "Unable to waive this charge")}
    end
  end

  defp ai_doc_reviewer_client do
    Application.get_env(:medcamp, :ai_doc_reviewer_client, Medcamp.ArtificialIntelligence.OpenAI)
  end

  @impl true
  def handle_async(:run_ai_review, {:ok, {:ok, doctor_note}}, socket) do
    {:noreply,
     socket
     |> assign(:ai_review_loading, false)
     |> assign(:doctor_note, doctor_note)
     |> put_flash(:info, "AI review generated")}
  end

  def handle_async(:run_ai_review, {:ok, {:error, reason}}, socket) do
    Logger.error(
      "AI review failed for doctor_note=#{socket.assigns.doctor_note.id}: #{inspect(reason)}"
    )

    {:noreply,
     socket
     |> assign(:ai_review_loading, false)
     |> put_flash(:error, "Could not generate the AI review right now")}
  end

  def handle_async(:run_ai_review, {:exit, reason}, socket) do
    Logger.error(
      "AI review task crashed for doctor_note=#{socket.assigns.doctor_note.id}: #{inspect(reason)}"
    )

    {:noreply,
     socket
     |> assign(:ai_review_loading, false)
     |> put_flash(:error, "Could not generate the AI review right now")}
  end

  defp maybe_fill_diagnosis_from_icd(params) do
    case Map.get(params, "diagnosis_icd_code") do
      nil ->
        params

      "" ->
        params

      code ->
        title = Medcamp.Icd11.list() |> Enum.find_value(fn {c, t} -> if c == code, do: t end)
        if title, do: Map.put(params, "diagnosis", title), else: params
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="w-full flex justify-between items-center mb-4">
        <.link
          navigate={"/doctor/patients/#{@patient.id}/notes"}
          class="flex gap-2 cursor-pointer text-[#373896] font-semibold items-center hover:text-[#6667ab] transition-colors"
        >
          <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" />
          <p>Back to Doctor's Notes</p>
        </.link>
      </div>

      <.doctor_note_tabs
        current_tab={@current_tab}
        tabs={[
          %{id: "overview", label: "Overview", icon_name: "document-text"},
          %{id: "charges", label: "Charges", icon_name: "banknotes"},
          %{id: "lab_work", label: "Lab Work", icon_name: "beaker"},
          %{id: "ai_review", label: "AI Review", icon_name: "sparkles"},
          %{id: "radiology", label: "Radiology", icon_name: "photo"},
          %{
            id: "medication",
            label: "Medication",
            icon_markup: "<i class=\"fa fa-diamond\" aria-hidden=\"true\"></i>",
            icon_name: nil
          },
          %{id: "inpatient", label: "Inpatient", icon_name: "home-modern"},
          %{id: "admission", label: "Admission Requests", icon_name: "clipboard-document-list"},
          %{id: "referral", label: "Referrals", icon_name: "user-group"}
        ]}
      />

      <div :if={@current_tab == "overview"}>
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 mb-4 overflow-hidden">
          <button
            type="button"
            phx-click="toggle_main_note"
            class="w-full flex items-center justify-between px-6 py-4 hover:bg-gray-50 transition-colors text-left"
          >
            <div class="flex items-center gap-2">
              <Heroicons.icon name="document-text" type="outline" class="h-5 w-5 text-[#6667ab]" />
              <span class="text-base font-semibold text-[#373896]">
                Consultation Details — Dr. {@doctor_note.doctor.name}
              </span>
              <span class="text-xs text-gray-500 ml-1">
                {@doctor_note.date} at {@doctor_note.time}
              </span>
            </div>
            <Heroicons.icon
              name={if @main_note_expanded, do: "chevron-up", else: "chevron-down"}
              type="outline"
              class="h-5 w-5 text-gray-400 flex-shrink-0"
            />
          </button>
          <div :if={@main_note_expanded} class="border-t border-gray-100 px-2 py-2">
            <.doctor_notes_form
              patient={@patient}
              show_lab_imaging_request={true}
              form={@form}
              draft_key={"doctor_note:#{@patient.id}:#{@doctor_note.id}"}
            />
          </div>
        </div>
      </div>

      <div :if={@current_tab == "ai_review"}>
        <div class="bg-white rounded-lg shadow-sm border border-gray-200 mb-4 overflow-hidden">
          <div class="flex items-center justify-between px-6 py-4 border-b border-gray-100">
            <div class="flex items-center gap-2">
              <Heroicons.icon name="sparkles" type="outline" class="h-5 w-5 text-[#6667ab]" />
              <span class="text-base font-semibold text-[#373896]">AI Review</span>
            </div>
            <button
              :if={has_ai_review_source_data?(@doctor_note)}
              type="button"
              phx-click="run_ai_review"
              phx-disable-with="Reviewing..."
              disabled={@ai_review_loading}
              class="inline-flex items-center gap-1.5 rounded-lg bg-[#6667ab] px-3 py-1.5 text-sm font-medium text-white hover:bg-[#5556a0] disabled:opacity-60 disabled:cursor-not-allowed"
            >
              {if @doctor_note.ai_review_status == "completed",
                do: "Regenerate",
                else: "Run AI Review"}
            </button>
          </div>

          <div class="px-6 py-4">
            <%= cond do %>
              <% @ai_review_loading -> %>
                <div class="flex flex-col items-center justify-center gap-3 py-10 text-center">
                  <div class="h-8 w-8 animate-spin rounded-full border-2 border-[#6667ab] border-t-transparent">
                  </div>
                  <p class="text-sm text-gray-500">
                    Generating your AI review — this can take a few seconds...
                  </p>
                </div>
              <% !has_ai_review_source_data?(@doctor_note) -> %>
                <p class="text-sm text-gray-500">
                  Add complaints, clinical notes, past medical history, impression, management,
                  or investigations to enable an AI review.
                </p>
              <% @doctor_note.ai_review_status != "completed" -> %>
                <p class="text-sm text-gray-500">
                  Run an AI review to get an independent second opinion on this case — a tailored,
                  case-specific reference lookup, not a replacement for your own judgement.
                </p>
              <% Map.get(@doctor_note.ai_review_payload, "schema_version") != "2.0" -> %>
                <p class="text-sm text-gray-500">
                  This review was generated by an earlier version of the AI Review format.
                  Regenerate to see it in the current format.
                </p>
              <% true -> %>
                <% payload = @doctor_note.ai_review_payload %>
                <% data_quality = Map.get(payload, "data_quality", %{}) %>
                <% urgency = Map.get(payload, "urgency", %{}) %>
                <% impression = Map.get(payload, "independent_impression", %{}) %>
                <% medication_review = Map.get(payload, "medication_review", %{}) %>
                <% medication_options = Map.get(medication_review, "options_to_consider", []) %>
                <% medication_concerns =
                  Map.get(medication_review, "allergy_conflicts", []) ++
                    Map.get(medication_review, "interaction_warnings", []) ++
                    Map.get(medication_review, "existing_medication_concerns", []) %>
                <% closeness = Map.get(payload, "closeness", %{}) %>
                <div class="space-y-5">
                  <div
                    :if={Map.get(data_quality, "sufficient_for_review", true) == false}
                    class="rounded-lg border border-amber-200 bg-amber-50 p-3"
                  >
                    <h4 class="text-sm font-semibold text-amber-900">
                      Complete the clinical picture
                    </h4>
                    <ul class="mt-1 list-disc space-y-0.5 pl-5">
                      <li
                        :for={
                          item <-
                            Map.get(data_quality, "missing_critical_information", []) |> Enum.take(3)
                        }
                        class="text-sm text-amber-800"
                      >
                        {item}
                      </li>
                    </ul>
                  </div>

                  <div class="rounded-lg border border-gray-200 bg-gray-50 p-4">
                    <div class="flex flex-wrap items-center gap-2">
                      <h4 class="text-sm font-semibold text-gray-900">Clinical impression</h4>
                      <span class={[
                        "px-2 py-0.5 text-xs rounded-full font-medium",
                        urgency_badge_class(Map.get(urgency, "level"))
                      ]}>
                        {Map.get(urgency, "level", "routine") |> to_string() |> String.capitalize()} priority
                      </span>
                      <span class="rounded-full bg-white px-2 py-0.5 text-xs font-medium text-gray-600 ring-1 ring-gray-200">
                        {Map.get(impression, "evidence_strength", "weak") |> String.capitalize()} evidence
                      </span>
                      <span
                        :if={Map.get(closeness, "status") == "computed"}
                        class="rounded-full bg-[#f0f0ff] px-2 py-0.5 text-xs font-medium text-[#373896]"
                      >
                        {Map.get(closeness, "score")}% diagnosis alignment
                      </span>
                    </div>
                    <p class="mt-2 text-sm text-gray-700">{Map.get(impression, "summary")}</p>
                    <p
                      :if={Map.get(closeness, "status") == "computed" and closeness["explanation"]}
                      class="mt-1 text-xs text-gray-500"
                    >
                      {closeness["explanation"]}
                    </p>

                    <div
                      :if={Map.get(urgency, "red_flags", []) != []}
                      class="mt-3 border-t border-gray-200 pt-3"
                    >
                      <p class="mb-1 text-xs font-semibold uppercase tracking-wide text-red-700">
                        Red flags
                      </p>
                      <ul class="space-y-1.5">
                        <li
                          :for={flag <- Map.get(urgency, "red_flags", []) |> Enum.take(3)}
                          class="text-sm text-red-800"
                        >
                          <span class="font-medium">{flag["finding"]}</span>
                          <span :if={flag["suggested_action"]}>— {flag["suggested_action"]}</span>
                        </li>
                      </ul>
                    </div>
                  </div>

                  <div class="grid gap-5 lg:grid-cols-2">
                    <div :if={Map.get(payload, "differential_diagnoses", []) != []}>
                      <h4 class="mb-2 text-sm font-semibold text-gray-900">Top differentials</h4>
                      <ol class="space-y-2">
                        <li
                          :for={
                            {dx, index} <-
                              Map.get(payload, "differential_diagnoses", [])
                              |> Enum.take(3)
                              |> Enum.with_index(1)
                          }
                          class="flex gap-2 text-sm text-gray-700"
                        >
                          <span class="font-semibold text-gray-400">{index}.</span>
                          <div>
                            <div class="flex flex-wrap items-center gap-1.5">
                              <span class="font-medium">{dx["condition"]}</span>
                              <span class={[
                                "rounded-full px-2 py-0.5 text-xs font-medium",
                                likelihood_badge_class(dx["likelihood"])
                              ]}>
                                {String.replace(dx["likelihood"] || "possible", "_", " ")
                                |> String.capitalize()}
                              </span>
                            </div>
                            <p :if={dx["rationale"]} class="mt-0.5 text-xs text-gray-500">
                              {dx["rationale"]}
                            </p>
                          </div>
                        </li>
                      </ol>
                    </div>

                    <div :if={Map.get(payload, "recommended_next_steps", []) != []}>
                      <h4 class="mb-2 text-sm font-semibold text-gray-900">Priority actions</h4>
                      <ul class="space-y-2">
                        <li
                          :for={
                            step <-
                              Map.get(payload, "recommended_next_steps", []) |> Enum.take(4)
                          }
                          class="flex items-start gap-2 text-sm text-gray-700"
                        >
                          <span class={[
                            "mt-0.5 rounded-full px-2 py-0.5 text-xs font-medium",
                            urgency_badge_class(step["priority"])
                          ]}>
                            {String.capitalize(step["priority"] || "routine")}
                          </span>
                          <span class="font-medium">{step["action"]}</span>
                        </li>
                      </ul>
                    </div>
                  </div>

                  <div
                    :if={medication_options != []}
                    class="rounded-lg border border-indigo-200 bg-indigo-50 p-4"
                  >
                    <div class="mb-2 flex items-center gap-2">
                      <Heroicons.icon name="beaker" type="outline" class="h-4 w-4 text-indigo-700" />
                      <h4 class="text-sm font-semibold text-indigo-950">
                        Suggested medications
                      </h4>
                    </div>
                    <ul class="grid gap-3 lg:grid-cols-3">
                      <li
                        :for={option <- Enum.take(medication_options, 3)}
                        class="rounded-md border border-indigo-100 bg-white p-3 text-sm"
                      >
                        <p class="font-semibold text-gray-900">{option["generic_name"]}</p>
                        <p :if={option["dose"]} class="font-medium text-indigo-800">
                          {option["dose"]}
                        </p>
                        <p :if={option["indication"]} class="mt-1 text-xs text-gray-600">
                          For {option["indication"]}
                        </p>
                        <p
                          :if={Map.get(option, "contraindications_or_cautions", []) != []}
                          class="mt-1 text-xs text-amber-700"
                        >
                          Caution: {option["contraindications_or_cautions"]
                          |> Enum.take(2)
                          |> Enum.join("; ")}
                        </p>
                      </li>
                    </ul>
                    <p class="mt-2 text-xs text-indigo-700">
                      Confirm allergies, contraindications, interactions, and patient-specific dosing before prescribing.
                    </p>
                  </div>

                  <div
                    :if={medication_concerns != [] or Map.get(payload, "safety_netting", []) != []}
                    class="grid gap-3 lg:grid-cols-2"
                  >
                    <div
                      :if={medication_concerns != []}
                      class="rounded-lg border border-red-200 bg-red-50 p-3"
                    >
                      <h4 class="text-sm font-semibold text-red-900">Medication warnings</h4>
                      <ul class="mt-1 list-disc space-y-0.5 pl-5">
                        <li
                          :for={warning <- Enum.take(medication_concerns, 3)}
                          class="text-sm text-red-800"
                        >
                          {warning}
                        </li>
                      </ul>
                    </div>

                    <div
                      :if={Map.get(payload, "safety_netting", []) != []}
                      class="rounded-lg border border-amber-200 bg-amber-50 p-3"
                    >
                      <h4 class="text-sm font-semibold text-amber-900">Escalate if</h4>
                      <ul class="mt-1 space-y-1">
                        <li
                          :for={item <- Map.get(payload, "safety_netting", []) |> Enum.take(3)}
                          class="text-sm text-amber-800"
                        >
                          <span class="font-medium">{item["trigger"]}:</span> {item["action"]}
                        </li>
                      </ul>
                    </div>
                  </div>

                  <p class="text-xs text-gray-400 border-t border-gray-100 pt-3">
                    {Map.get(payload, "disclaimer")}
                    <span :if={@doctor_note.ai_review_generated_at}>
                      · Generated {format_datetime(@doctor_note.ai_review_generated_at)}
                    </span>
                  </p>
                </div>
            <% end %>
          </div>
        </div>
      </div>

      <div :if={@current_tab == "overview"}>
        <.child_doctor_notes_section
          child_notes={@child_notes}
          parent_note_id={@doctor_note.id}
          current_user={@current_user}
          expanded_ids={@expanded_sub_note_ids}
        />
      </div>

      <div :if={@current_tab == "charges"}>
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
          <div class="rounded-xl border border-amber-200 bg-amber-50 p-4">
            <p class="text-xs font-semibold uppercase tracking-wide text-amber-700">Pending Review</p>
            <p class="mt-2 text-2xl font-semibold text-amber-900">
              {@patient_charge_summary.pending_review_count}
            </p>
          </div>

          <div class="rounded-xl border border-indigo-200 bg-indigo-50 p-4">
            <p class="text-xs font-semibold uppercase tracking-wide text-indigo-700">
              Approved Unpaid
            </p>
            <p class="mt-2 text-2xl font-semibold text-indigo-900">
              {@patient_charge_summary.approved_unpaid_count}
            </p>
          </div>

          <div class="rounded-xl border border-emerald-200 bg-emerald-50 p-4">
            <p class="text-xs font-semibold uppercase tracking-wide text-emerald-700">Paid</p>
            <p class="mt-2 text-2xl font-semibold text-emerald-900">
              {@patient_charge_summary.paid_count}
            </p>
          </div>

          <div class="rounded-xl border border-slate-200 bg-slate-50 p-4">
            <p class="text-xs font-semibold uppercase tracking-wide text-slate-600">
              Approved Amount
            </p>
            <p class="mt-2 text-2xl font-semibold text-slate-900">
              KSh {format_currency(@patient_charge_summary.approved_unpaid_total)}
            </p>
          </div>
        </div>

        <div class="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
          <div class="flex items-center justify-between px-6 py-4 border-b border-slate-100">
            <div>
              <h3 class="text-lg font-semibold text-slate-900">Emergency Nursing Charges</h3>
              <p class="text-sm text-slate-500">
                Charges created from patient-linked nursing allocation usage on this note.
              </p>
            </div>

            <%= if @patient_charge_summary.approved_unpaid_count > 0 do %>
              <.link patch={"#{@note_path}/charges/trigger_payment?tab=charges&subtab=#{@inpatient_subtab}"}>
                <.button class="bg-[#373896] hover:bg-[#2d2f80]">
                  Prompt Payment
                </.button>
              </.link>
            <% end %>
          </div>

          <%= if Enum.empty?(@patient_charges) do %>
            <div class="px-6 py-10 text-center text-sm text-slate-500">
              No emergency nursing charges have been recorded for this doctor note.
            </div>
          <% else %>
            <div class="divide-y divide-slate-100">
              <%= for charge <- @patient_charges do %>
                <div class="px-6 py-4">
                  <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                    <div class="space-y-2">
                      <div class="flex flex-wrap items-center gap-2">
                        <h4 class="text-sm font-semibold text-slate-900">{charge.description}</h4>
                        <span class={[
                          "inline-flex rounded-full px-2.5 py-1 text-xs font-medium",
                          charge_status_badge_class(charge.status)
                        ]}>
                          {charge_status_label(charge.status)}
                        </span>
                      </div>

                      <div class="text-sm text-slate-600 space-y-1">
                        <p>
                          Quantity: {charge.quantity} | Unit Price: KSh {format_currency(
                            charge.unit_price
                          )} | Total: KSh {format_currency(charge.total_price)}
                        </p>
                        <p :if={charge.nursing_consumable}>
                          Recorded on {charge.nursing_consumable.date} from nursing usage #{charge.nursing_consumable.id}
                        </p>
                        <p :if={charge.created_by}>
                          Logged by {charge.created_by.name}
                        </p>
                      </div>
                    </div>

                    <div class="flex flex-wrap items-center gap-2 lg:justify-end">
                      <%= if charge.status == "pending_review" do %>
                        <button
                          type="button"
                          phx-click="approve_patient_charge"
                          phx-value-id={charge.id}
                          class="inline-flex items-center rounded-lg bg-emerald-600 px-3 py-2 text-sm font-medium text-white hover:bg-emerald-700"
                        >
                          Approve
                        </button>
                        <button
                          type="button"
                          phx-click="waive_patient_charge"
                          phx-value-id={charge.id}
                          class="inline-flex items-center rounded-lg bg-slate-200 px-3 py-2 text-sm font-medium text-slate-700 hover:bg-slate-300"
                        >
                          Waive
                        </button>
                      <% else %>
                        <span class="text-xs text-slate-500">
                          <%= case charge.status do %>
                            <% "approved" -> %>
                              Ready for payment
                            <% "paid" -> %>
                              Paid on {format_datetime(charge.paid_at)}
                            <% "waived" -> %>
                              Waived
                            <% _ -> %>
                          <% end %>
                        </span>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <.lab_results_card
        :if={@current_tab == "lab_work"}
        lab_results={@lab_results}
        patient={@patient}
        doctor_note={@doctor_note}
        note_path={@note_path}
        regenerate={true}
      />

      <.drug_allocations_section
        :if={@current_tab == "medication"}
        drug_allocations={@drug_allocations}
        patient={@patient}
        doctor_note={@doctor_note}
      />

      <.referrals_card
        :if={@current_tab == "referral"}
        patient={@patient}
        doctor_note={@doctor_note}
        referrals={@referrals}
      />

      <.radiology_results_card
        :if={@current_tab == "radiology"}
        patient={@patient}
        doctor_note={@doctor_note}
        radiology_results={@radiology_results}
      />

      <.admission_requests_card
        :if={@current_tab == "admission"}
        patient={@patient}
        doctor_note={@doctor_note}
        admission_requests={@admission_requests}
        note_path={@note_path}
      />
      
    <!-- NEW: Inpatient Section -->
      <.inpatient_section
        :if={@current_tab == "inpatient"}
        patient={@patient}
        doctor_note={@doctor_note}
        current_user={@current_user}
        current_admission={@current_admission}
        admission_notes={@admission_notes}
        continuation_notes={@continuation_notes}
        treatment_sheets={@treatment_sheets}
        vital_records={@vital_records}
        cadex_notes={@cadex_notes}
        discharge_summary={@discharge_summary}
        inpatient_subtab={@inpatient_subtab}
        note_path={@note_path}
      />
      
    <!-- Keep all existing modals... -->
      <.modal
        :if={@live_action in [:after_create]}
        id="patient-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={MedcampWeb.AfterCreateNoteComponent}
          id={:new}
          title={@page_title}
          action={@live_action}
          patient={@patient}
          doctor_note={@doctor_note}
          patch={@note_path_with_params}
        />
      </.modal>

      <.modal
        :if={@live_action in [:request_lab, :prescribe_drug]}
        id="patient-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={
            if @live_action == :request_lab,
              do: MedcampWeb.RequestLabComponent,
              else: MedcampWeb.PrescribeMedicineComponent
          }
          id={:request_lab}
          title={@page_title}
          lab_result={%LabResult{}}
          drug_allocation={%DrugAllocation{}}
          action={@live_action}
          current_user={@current_user}
          patient={@patient}
          return_url={@note_path_with_params}
          doctor_note={@doctor_note}
          patch={@note_path_with_params}
        />
      </.modal>

      <.modal
        :if={@live_action in [:request_radiology_test]}
        id="patient-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={MedcampWeb.RequestRadiologyComponent}
          id={:request_lab}
          title={@page_title}
          radiology_result={%RadiologyResult{}}
          drug_allocation={%DrugAllocation{}}
          action={@live_action}
          current_user={@current_user}
          patient={@patient}
          return_url={@note_path_with_params}
          doctor_note={@doctor_note}
          patch={@note_path_with_params}
        />
      </.modal>

      <.modal
        :if={@live_action in [:admit_patient]}
        id="patient-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={MedcampWeb.AdmitPatientComponent}
          id={:request_lab}
          title={@page_title}
          admission_request={%Medcamp.AdmissionRequests.AdmissionRequest{}}
          action={@live_action}
          current_user={@current_user}
          patient={@patient}
          return_url={@note_path_with_params}
          doctor_note={@doctor_note}
          patch={@note_path_with_params}
        />
      </.modal>

      <.modal
        :if={@live_action in [:line_items] and @admission_request_for_line_items}
        id="line-items-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <div class="px-4 py-2">
          <h3 class="text-lg font-semibold text-gray-900 mb-4">{@page_title}</h3>
          <.live_component
            module={MedcampWeb.NursesPages.AdmissionRequestLineItemsLive}
            id={"line-items-#{@admission_request_for_line_items.id}"}
            admission_request={@admission_request_for_line_items}
            line_item_trigger_prefix={"#{@note_path}/admission_requests/#{@admission_request_for_line_items.id}/line_items"}
          />
          <div class="mt-4 flex justify-end">
            <.link patch={@note_path_with_params} class="text-sm text-[#373896] hover:underline">
              Done
            </.link>
          </div>
        </div>
      </.modal>

      <.modal
        :if={@live_action in [:trigger_payment_line_item] and @line_item_for_trigger}
        id="line-item-trigger-payment-modal"
        show
        on_cancel={
          JS.patch(
            "#{@note_path}/admission_requests/#{@line_item_for_trigger.admission_request.id}/line_items?tab=admission&subtab=#{@inpatient_subtab}"
          )
        }
      >
        <.live_component
          module={MedcampWeb.TriggerPayment}
          id={"line-item-trigger-#{@line_item_for_trigger.id}"}
          title={@page_title}
          action={@live_action}
          action_to_perform="admission_line_item"
          return_url={"#{@note_path}/admission_requests/#{@line_item_for_trigger.admission_request.id}/line_items?tab=admission&subtab=#{@inpatient_subtab}"}
          actionable_type={@line_item_for_trigger}
          patient={@line_item_for_trigger.admission_request.patient}
          current_user={@current_user}
          patient_id={@line_item_for_trigger.admission_request.patient_id}
          patch={"#{@note_path}/admission_requests/#{@line_item_for_trigger.admission_request.id}/line_items?tab=admission&subtab=#{@inpatient_subtab}"}
        />
      </.modal>

      <.modal
        :if={@live_action in [:trigger_patient_charge_payment] and @patient_charge_batch}
        id="patient-charge-trigger-payment-modal"
        show
        on_cancel={JS.patch("#{@note_path}?tab=charges&subtab=#{@inpatient_subtab}")}
      >
        <.live_component
          module={MedcampWeb.TriggerPayment}
          id={"patient-charge-trigger-#{@patient_charge_batch.id}"}
          title={@page_title}
          action={@live_action}
          action_to_perform="patient_charge_batch"
          return_url={"#{@note_path}?tab=charges&subtab=#{@inpatient_subtab}"}
          actionable_type={@patient_charge_batch}
          patient={@patient_charge_batch.patient}
          current_user={@current_user}
          patient_id={@patient_charge_batch.patient_id}
          patch={"#{@note_path}?tab=charges&subtab=#{@inpatient_subtab}"}
        />
      </.modal>

      <.modal
        :if={@live_action in [:assign_new_drug]}
        id="patient-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={MedcampWeb.NewDrugAssignedComponent}
          id={:request_lab}
          title={@page_title}
          drug_allocation={@drug_allocation}
          action={@live_action}
          current_user={@current_user}
          patient={@patient}
          return_url={@note_path_with_params}
          doctor_note={@doctor_note}
          patch={@note_path_with_params}
        />
      </.modal>

      <.modal
        :if={@live_action in [:refer_patient]}
        id="referral-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={MedcampWeb.ReferralLive.FormComponent}
          id={:new}
          title={@page_title}
          action={@live_action}
          current_user={@current_user}
          patient={@patient}
          doctor_note={@doctor_note}
          referral={%Medcamp.Referrals.Referral{}}
          patch={@note_path_with_params}
        />
      </.modal>
      
    <!-- NEW: Inpatient Modals -->
      <.modal
        :if={@live_action in [:new_admission]}
        id="admission-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={MedcampWeb.Inpatient.AdmissionFormComponent}
          id={:new_admission}
          title={@page_title}
          action={@live_action}
          current_user={@current_user}
          patient={@patient}
          doctor_note={@doctor_note}
          admission_note={@admission_note}
          patch={@note_path_with_params}
        />
      </.modal>

      <.modal
        :if={@live_action in [:new_continuation]}
        id="continuation-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={MedcampWeb.Inpatient.ContinuationFormComponent}
          id={:new_continuation}
          title={@page_title}
          action={@live_action}
          current_user={@current_user}
          admission_note={@current_admission}
          continuation_note={@continuation_note}
          patch={@note_path_with_params}
        />
      </.modal>

      <.modal
        :if={@live_action in [:new_treatment, :edit_treatment]}
        id="treatment-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={MedcampWeb.Inpatient.TreatmentFormComponent}
          id={"treatment-#{@treatment_sheet.id || :new}"}
          title={@page_title}
          action={@live_action}
          current_user={@current_user}
          admission_note={@current_admission}
          treatment_sheet={@treatment_sheet}
          patch={@note_path_with_params}
        />
      </.modal>

      <.modal
        :if={@live_action in [:new_vitals]}
        id="vitals-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={MedcampWeb.Inpatient.VitalsFormComponent}
          id={:new_vitals}
          title={@page_title}
          action={@live_action}
          current_user={@current_user}
          admission_note={@current_admission}
          vital_record={@vital_record}
          patch={@note_path_with_params}
        />
      </.modal>

      <.modal
        :if={@live_action in [:new_discharge]}
        id="discharge-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={MedcampWeb.Inpatient.DischargeFormComponent}
          id={:new_discharge}
          title={@page_title}
          action={@live_action}
          current_user={@current_user}
          patient={@patient}
          admission_note={@current_admission}
          discharge_summary={@discharge_summary_form}
          patch={@note_path_with_params}
        />
      </.modal>

      <.modal
        :if={@live_action in [:new_cadex, :edit_cadex]}
        id="cadex-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={MedcampWeb.Inpatient.CadexFormComponent}
          id={"cadex-#{@cadex_note.id || :new}"}
          title={@page_title}
          action={@live_action}
          current_user={@current_user}
          admission_note={@current_admission}
          cadex_note={@cadex_note}
          patch={@note_path_with_params}
        />
      </.modal>

      <.modal
        :if={@show_sub_note_modal}
        id="sub-note-modal"
        show
        on_cancel={JS.push("close_sub_note_modal")}
      >
        <div class="px-2 py-2">
          <div class="flex items-center gap-2 mb-4">
            <Heroicons.icon name="document-plus" type="outline" class="h-5 w-5 text-[#6667ab]" />
            <h3 class="text-lg font-semibold text-[#373896]">Add Sub-note</h3>
          </div>
          <p class="text-sm text-gray-500 mb-4">
            Adding a sub-note to the note started by Dr. {@doctor_note.doctor.name} on {@doctor_note.date}.
          </p>
          <.sub_doctor_note_form form={@sub_note_form} patient={@patient} />
        </div>
      </.modal>

      <.modal
        :if={@view_lab_report_entry}
        id="lab-report-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={MedcampWeb.LabPagesLabResultLive.TestResultDocumentComponent}
          id={:doctor_view_results}
          entry={@view_lab_report_entry}
          template={@view_lab_report_template}
          lab_result={@view_lab_report_lab_result}
          patient={@view_lab_report_patient}
          doctor={@view_lab_report_doctor}
          back_to={@note_path_with_params}
          back_label="Back to Note"
        />
      </.modal>
    </div>
    """
  end

  defp reload_patient_charges(socket) do
    patient_charges =
      PatientCharges.list_patient_charges_for_doctor_note(socket.assigns.doctor_note.id)

    patient_charge_summary =
      PatientCharges.charge_summary_for_doctor_note(socket.assigns.doctor_note.id)

    socket
    |> assign(:patient_charges, patient_charges)
    |> assign(:patient_charge_summary, patient_charge_summary)
  end

  defp has_ai_review_source_data?(doctor_note) do
    [
      doctor_note.reason_for_consulatation,
      doctor_note.clinical_notes,
      doctor_note.past_medical_history,
      doctor_note.impression,
      doctor_note.management,
      doctor_note.investigations
    ]
    |> Enum.any?(fn
      value when is_binary(value) -> String.trim(value) != ""
      _value -> false
    end)
  end

  defp urgency_badge_class("emergency"), do: "bg-red-100 text-red-800"
  defp urgency_badge_class("urgent"), do: "bg-orange-100 text-orange-800"
  defp urgency_badge_class("routine"), do: "bg-green-100 text-green-800"
  defp urgency_badge_class(_), do: "bg-gray-100 text-gray-700"

  defp likelihood_badge_class("most_likely"), do: "bg-[#f0f0ff] text-[#373896]"
  defp likelihood_badge_class("possible"), do: "bg-gray-100 text-gray-700"
  defp likelihood_badge_class("less_likely"), do: "bg-gray-50 text-gray-500"
  defp likelihood_badge_class(_), do: "bg-gray-100 text-gray-700"

  defp format_currency(nil), do: "0"
  defp format_currency(amount), do: Number.Delimit.number_to_delimited(amount)

  defp format_datetime(nil), do: "—"

  defp format_datetime(%NaiveDateTime{} = datetime) do
    Calendar.strftime(datetime, "%d %b %Y %H:%M")
  end

  defp format_datetime(%DateTime{} = datetime) do
    Calendar.strftime(datetime, "%d %b %Y %H:%M")
  end

  defp charge_status_badge_class("pending_review"), do: "bg-amber-100 text-amber-800"
  defp charge_status_badge_class("approved"), do: "bg-indigo-100 text-indigo-800"
  defp charge_status_badge_class("paid"), do: "bg-emerald-100 text-emerald-800"
  defp charge_status_badge_class("waived"), do: "bg-slate-200 text-slate-700"
  defp charge_status_badge_class(_), do: "bg-slate-100 text-slate-700"

  defp charge_status_label("pending_review"), do: "Pending Review"
  defp charge_status_label("approved"), do: "Approved"
  defp charge_status_label("paid"), do: "Paid"
  defp charge_status_label("waived"), do: "Waived"
  defp charge_status_label(_), do: "Unknown"
end
