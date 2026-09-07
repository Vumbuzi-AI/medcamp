defmodule MedcampWeb.NursesPages.EachPatientDoctorNoteShow do
  use MedcampWeb, :nurse_each_patient_live_view

  alias Medcamp.Patients
  alias Medcamp.DoctorNotes
  alias Medcamp.LabResults
  alias Medcamp.LabResults.LabResult
  alias Medcamp.DrugAllocations.DrugAllocation
  alias Medcamp.RadiologyResults.RadiologyResult
  alias Medcamp.DrugAllocations
  alias Medcamp.Referrals
  alias Medcamp.AdmissionRequests
  alias Medcamp.RadiologyResults
  alias Medcamp.Inpatient

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:active_tab, :doctor_notes)
     |> assign(:current_tab, "overview")
     |> assign(:inpatient_subtab, "admission")
     |> assign(:note_path, nil)
     |> stream(:doctor_notes, DoctorNotes.list_doctor_notes())}
  end

  @impl true
  def handle_params(%{"patient_id" => id, "note_id" => note_id} = params, _url, socket) do
    patient = Patients.get_patient!(id)
    doctor_note = DoctorNotes.get_doctor_note!(note_id)
    note_path = "/nurse/#{id}/doctor_notes/#{note_id}"

    lab_results = LabResults.list_lab_results_for_doctor_note(note_id)
    drug_allocations = DrugAllocations.list_drug_allocations_for_a_doctor_note(note_id)
    radiology_results = RadiologyResults.list_radiology_results_by_doctor_note_id(note_id)
    admission_requests = AdmissionRequests.list_admission_requests_by_doctor_note_id(note_id)

    current_admission = Inpatient.get_current_admission(String.to_integer(id))
    admission_notes = Inpatient.list_admission_notes_for_patient(String.to_integer(id))

    {:noreply,
     socket
     |> assign(:patient, patient)
     |> assign(:note_path, note_path)
     |> assign(:admission_requests, admission_requests)
     |> assign(:radiology_results, radiology_results)
     |> assign(:referrals, Referrals.list_referrals_for_a_doctor_note(doctor_note.id))
     |> assign(:drug_allocations, drug_allocations)
     |> assign(:lab_results, lab_results)
     |> assign(:current_admission, current_admission)
     |> assign(:admission_notes, admission_notes)
     |> assign(
       :continuation_notes,
       if(current_admission,
         do: Inpatient.list_continuation_notes_for_admission(current_admission.id),
         else: []
       )
     )
     |> assign(
       :treatment_sheets,
       if(current_admission,
         do: Inpatient.list_treatment_sheets_for_admission(current_admission.id),
         else: []
       )
     )
     |> assign(
       :vital_records,
       if(current_admission,
         do: Inpatient.list_vital_records_for_admission(current_admission.id),
         else: []
       )
     )
     |> assign(
       :discharge_summary,
       if(current_admission,
         do: Inpatient.get_discharge_summary_for_admission(current_admission.id),
         else: nil
       )
     )
     |> assign(
       :cadex_notes,
       if(current_admission,
         do: Medcamp.CadexNotes.list_cadex_notes_for_admission(current_admission.id),
         else: []
       )
     )
     |> assign(:current_tab, valid_tab(params["tab"]))
     |> assign(:inpatient_subtab, valid_inpatient_subtab(params["subtab"]))
     |> assign_new(:form, fn -> to_form(DoctorNotes.change_doctor_note(doctor_note)) end)
     |> assign(:doctor_note, doctor_note)
     |> then(fn s ->
       assign(s, :note_path_with_params, build_note_path_with_params(s.assigns))
     end)
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp valid_tab(nil), do: "overview"

  defp valid_tab(tab)
       when tab in ~w(overview lab_work radiology medication inpatient admission referral),
       do: tab

  defp valid_tab(_), do: "overview"

  defp valid_inpatient_subtab(nil), do: "admission"

  defp valid_inpatient_subtab(st)
       when st in ~w(admission continuation treatment vitals discharge cadex),
       do: st

  defp valid_inpatient_subtab(_), do: "admission"

  defp build_note_path_with_params(assigns) do
    base = Map.get(assigns, :note_path)
    tab = Map.get(assigns, :current_tab, "overview")
    subtab = Map.get(assigns, :inpatient_subtab, "admission")
    if tab == "inpatient", do: "#{base}?tab=#{tab}&subtab=#{subtab}", else: "#{base}?tab=#{tab}"
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Add Doctor notes")
  end

  defp apply_action(socket, :after_create, _params) do
    socket
    |> assign(:page_title, "Listing Doctor notes")
    |> assign(:live_action, :after_create)
  end

  defp apply_action(socket, :request_lab, _params) do
    socket
    |> assign(:page_title, "Listing Doctor notes")
    |> assign(:live_action, :request_lab)
  end

  defp apply_action(socket, :request_radiology_test, _params) do
    socket
    |> assign(:page_title, "Request radiology test")
    |> assign(:live_action, :request_radiology_test)
  end

  defp apply_action(socket, :prescribe_drug, _params) do
    socket
    |> assign(:page_title, "Listing Doctor notes")
    |> assign(:live_action, :prescribe_drug)
  end

  defp apply_action(socket, :refer_patient, _params) do
    socket
    |> assign(:page_title, "Refer Patient")
    |> assign(:live_action, :refer_patient)
  end

  defp apply_action(socket, :admit_patient, _params) do
    socket
    |> assign(:page_title, "Admit Patient")
    |> assign(:live_action, :admit_patient)
  end

  defp apply_action(socket, :assign_new_drug, %{"drug_allocation_id" => drug_allocation_id}) do
    drug_allocation = DrugAllocations.get_drug_allocation!(drug_allocation_id)

    socket
    |> assign(:page_title, "Add Drug")
    |> assign(:drug_allocation, drug_allocation)
    |> assign(:live_action, :assign_new_drug)
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

  defp apply_action(socket, :new_continuation, _params) do
    socket
    |> assign(:page_title, "Add Continuation Note")
    |> assign(:continuation_note, %Medcamp.Inpatient.ContinuationNote{})
    |> assign(:live_action, :new_continuation)
  end

  defp apply_action(socket, :new_admission, _params) do
    socket
    |> assign(:page_title, "New Admission")
    |> assign(:admission_note, %Medcamp.Inpatient.AdmissionNote{})
    |> assign(:live_action, :new_admission)
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

  @impl true
  def handle_event("validate", %{"doctor_note" => doctor_note_params}, socket) do
    changeset = DoctorNotes.change_doctor_note(socket.assigns.doctor_note, doctor_note_params)

    {:noreply,
     socket
     |> assign(:form, to_form(changeset, action: :validate))}
  end

  def handle_event("change-tab", %{"tab" => tab}, socket) do
    tab = valid_tab(tab)
    subtab = if tab == "inpatient", do: socket.assigns.inpatient_subtab, else: "admission"
    path = "#{socket.assigns.note_path}?tab=#{tab}"
    path = if tab == "inpatient", do: "#{path}&subtab=#{subtab}", else: path
    {:noreply, push_patch(socket, to: path)}
  end

  def handle_event("change-inpatient-subtab", %{"subtab" => subtab}, socket) do
    subtab = valid_inpatient_subtab(subtab)
    path = "#{socket.assigns.note_path}?tab=inpatient&subtab=#{subtab}"
    {:noreply, push_patch(socket, to: path)}
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

  def handle_event("save", %{"doctor_note" => doctor_note_params}, socket) do
    doctor_note_params =
      doctor_note_params
      |> Map.put("patient_id", socket.assigns.patient.id)
      |> Map.put("doctor_id", socket.assigns.current_user.id)

    case DoctorNotes.update_doctor_note(socket.assigns.doctor_note, doctor_note_params) do
      {:ok, _doctor_note} ->
        {:noreply,
         socket
         |> put_flash(:info, "Doctor note created successfully")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
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

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="w-full flex justify-between items-center mb-4">
        <.link
          navigate={"/nurse/#{@patient.id}/doctor_notes"}
          class="flex gap-2 cursor-pointer text-[#373896] font-semibold items-center hover:text-[#6667ab] transition-colors"
        >
          <Heroicons.icon name="arrow-left" type="outline" class="h-4 w-4" />
          <p>
            Back to Doctor Notes
          </p>
        </.link>
      </div>

      <.doctor_note_tabs
        current_tab={@current_tab}
        tabs={[
          %{id: "overview", label: "Overview", icon_name: "document-text"},
          %{id: "lab_work", label: "Lab Work", icon_name: "beaker"},
          %{id: "radiology", label: "Radiology", icon_name: "photo"},
          %{
            id: "medication",
            label: "Medication",
            icon_markup: "<i class=\"fa fa-diamond\" aria-hidden=\"true\"></i>",
            icon_name: nil
          },
          %{id: "inpatient", label: "Inpatient", icon_name: "home-modern"},
          %{id: "admission", label: "Admission", icon_name: "home-modern"},
          %{id: "referral", label: "Referrals", icon_name: "user-group"}
        ]}
      />

      <.doctor_notes_form_for_nurse
        :if={@current_tab == "overview"}
        patient={@patient}
        show_lab_imaging_request={true}
        form={@form}
      />

      <.lab_results_card_for_nurse
        :if={@current_tab == "lab_work"}
        lab_results={@lab_results}
        patient={@patient}
        doctor_note={@doctor_note}
      />

      <.drug_allocations_section_for_nurse
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
      <.radiology_results_card_for_nurse
        :if={@current_tab == "radiology"}
        patient={@patient}
        doctor_note={@doctor_note}
        radiology_results={@radiology_results}
      />
      <.admission_requests_card_for_nurse
        :if={@current_tab == "admission"}
        patient={@patient}
        doctor_note={@doctor_note}
        admission_requests={@admission_requests}
      />

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
            if @live_action == :request_lab do
              MedcampWeb.RequestLabComponent
            else
              MedcampWeb.PrescribeMedicineComponent
            end
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
        :if={@live_action in [:trigger_payment]}
        id="room_allocation-modal"
        show
        on_cancel={JS.patch(@note_path_with_params)}
      >
        <.live_component
          module={MedcampWeb.TriggerPayment}
          id={@lab_result.id || :new}
          title={@page_title}
          action={@live_action}
          action_to_perform="create_lab_result"
          return_url={@note_path_with_params}
          actionable_type={@lab_result}
          current_user={@current_user}
          patient_id={@lab_result.patient_id}
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
    </div>
    """
  end
end
