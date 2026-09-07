defmodule MedcampWeb.Router do
  use MedcampWeb, :router

  import MedcampWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MedcampWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :supplier_auth do
    plug MedcampWeb.Plugs.RequireProcurementRole, ~w(supplier)
  end

  pipeline :procurement_auth do
    plug MedcampWeb.Plugs.RequireProcurementRole,
         ~w(procurement_officer stores_officer finance_officer admin)
  end

  scope "/", MedcampWeb do
    pipe_through [:browser, :redirect_to_correct_page]

    #     live "/", LandingLive.Index, :index

    live "/", Website.HomeLive, :index
    live "/tibasasa", TibasasaLive.Index, :index
    live "/home", Website.HomeLive, :index
    live "/about", Website.AboutLive, :index
    live "/services", Website.ServicesLive, :index
    live "/services/:slug", Website.ServicesLive, :show
    live "/blog", Website.BlogLive, :index
    live "/blog/blog-template-1", Website.BlogLive, :index
    live "/blog/blog-template-2", Website.BlogLive, :index
    live "/post/:slug", Website.BlogLive, :show
    live "/eachservice", Website.BlogLive, :show
    live "/contact", Website.ContactLive, :index
  end

  scope "/", MedcampWeb do
    pipe_through [:browser]

    live "/community-health-insurance-survey", CommunityHealthSurveyLive.Index, :index
    live "/feedback/417/6161021095728", FeedbackLive.Index, :index
    live "/feedback", FeedbackLive.Index, :index
    live "/8018/:gsrn", PatientGSRNLive.Index, :index
    live "/8017/:gsrn", UserLive.Profile, :index
    live "/414/:gln", RoomGlnLive.Index, :index
    live "/payment/:receipt", ReceiptLive.Index, :index
    post "/8018/:gsrn/medical-camp/session", MedicalCampSessionController, :create
    post "/admin/medical_camp/access/session", AdminMedicalCampPinSessionController, :create
    delete "/admin/medical_camp/access/logout", AdminMedicalCampPinSessionController, :delete

    post "/meals/session", MealEntryPinSessionController, :create
    get "/meals/logout", MealEntryPinSessionController, :logout

    live_session :meal_entry,
      on_mount: [{MedcampWeb.MealEntryAuth, :mount_meal_entry_user}] do
      live "/meals/add", MealEntryLive.Index, :index
    end

    live "/medical-camp/scan", MedicalCampPages.GlobalScan, :index

    live_session :admin_medical_camp_access,
      on_mount: [{MedcampWeb.AdminMedicalCampExternalAuth, :mount_external_admin}] do
      live "/admin/medical_camp/access", AdminMedicalCampAccessLive.Index, :index
    end

    live_session :admin_medical_camp_external,
      on_mount: [{MedcampWeb.AdminMedicalCampExternalAuth, :require_external_admin}] do
      live "/admin/medical_camp/external", AdminMedicalCampExternalLive.Index, :index
      live "/admin/medical_camp/external/report", AdminMedicalCampExternalReportLive.Show, :show
    end

    live_session :medical_camp,
      layout: {MedcampWeb.Layouts, :medical_camp} do
      live "/8018/:gsrn/medical-camp", MedicalCampPages.Home, :index
      live "/8018/:gsrn/medical-camp/triages/new", MedicalCampPages.Home, :new_triage
      live "/8018/:gsrn/medical-camp/scan", MedicalCampPages.Scan, :index
    end

    live_session :medical_camp_authenticated,
      layout: {MedcampWeb.Layouts, :medical_camp},
      on_mount: [{MedcampWeb.MedicalCampAuth, :require_camp_auth}] do
      live "/8018/:gsrn/medical-camp/doctor_notes", MedicalCampPages.DoctorNotes, :index
      live "/8018/:gsrn/medical-camp/doctor_notes/new", MedicalCampPages.DoctorNoteNew, :index

      live "/8018/:gsrn/medical-camp/doctor_notes/:note_id",
           MedicalCampPages.DoctorNoteShow,
           :index
    end
  end

  scope "/", MedcampWeb do
    pipe_through [:browser]

    live "/confirm", ConfirmPaymentLive.Index, :index
  end

  scope "/api", MedcampWeb do
    pipe_through :api
    post "/webhooks/sentry", SentryWebhookController, :create
    post "/mpesa", MpesaController, :create
    post "/create_inventory_received", APIController, :create_inventory_received
    post "/create_batch", APIController, :create_batch
    get "/get_all_suppliers", APIController, :get_all_suppliers
    get "/get_all_rooms", APIController, :get_all_rooms

    post "/drugs_given_scan_out", DrugsGivenController, :scan_out_drug

    post "/drugs_to_be_scanned/",
         DrugsGivenController,
         :get_drugs_to_be_scanned

    post "/drug_allocations/check_verify", DrugsGivenController, :check_verify
    post "/drug_allocations/scan_verify", DrugsGivenController, :scan_verify

    get "/inventory_received_by_gtin/:gtin",
        APIController,
        :get_inventory_received_by_gtin

    post "/community-health-insurance-survey",
         CommunityHealthSurveyApiController,
         :create
  end

  # doctor scopes

  scope "/", MedcampWeb do
    pipe_through [:browser, :require_authenticated_user]

    live "/chat", ChatLive.Index, :index
    live "/telephone_directory", TelephoneDirectoryLive, :index

    get "/patients/:patient_id/documents/:document_type", PatientDocumentController, :show

    live_session :shared_current_user,
      on_mount: [{MedcampWeb.UserAuth, :mount_current_user}] do
      live "/todos", TodosLive.Index, :index
      live "/todos/new", TodosLive.Index, :new
      live "/todos/:id/edit", TodosLive.Index, :edit
      live "/sops", SOPsLive.Index, :index
      live "/duty_rota", DutyRotaLive.Index, :index
    end
  end

  scope "/", MedcampWeb do
    pipe_through [:browser, :require_authenticated_doctor]

    # Voice dictation: browser uploads recorded audio, gets back transcribed text.
    post "/doctor/transcribe", TranscriptionController, :create

    live_session :doctor_current_user,
      on_mount: [
        {MedcampWeb.UserAuth, :mount_current_user},
        {MedcampWeb.Plugs.RequirePanelPermission, :default}
      ] do
      live "/doctor/dashboard", DoctorDashboardLive.Index, :index
      live "/doctor/patient_visits", DoctorsPagePatientLive.VisitsIndex, :index
      live "/doctor/scan", DoctorsPage.ScanIndex, :index
      live "/doctor/medical_camp_scan", DoctorsPage.MedicalCampScanIndex, :index
      live "/doctor/pending_patient_visits", DoctorsPagePatientLive.PendingIndex, :index
      live "/doctor/lab_results", DoctorsPagePatientLive.AllLabResultsLiveIndex, :index
      live "/doctor/patients", DoctorsPagePatientLive.Index, :index
      live "/doctor/appointments", DoctorsPagePatientLive.AllAppointmentsLiveIndex, :index
      live "/doctor/blogs", DoctorBlogLive.Index, :index
      live "/doctor/blogs/new", DoctorBlogLive.Index, :new
      live "/doctor/blogs/:id/edit", DoctorBlogLive.Index, :edit

      live "/doctor/patients/new", DoctorsPagePatientLive.Index, :new
      live "/doctor/patients/:id/edit", DoctorsPagePatientLive.Index, :edit
      live "/doctor/patients/:id", DoctorsPagePatientLive.Show, :index
      live "/doctor/patients/:id/mch", DoctorsPages.EachPatientMchIndex, :index

      live "/doctor/patients/:id/nurse_procedures",
           DoctorsPagePatientLive.NurseProcedureIndex,
           :index

      live "/doctor/patients/:id/triages", DoctorsPagePatientLive.TriageIndex, :index
      live "/doctor/patients/:id/triages/new", DoctorsPagePatientLive.TriageIndex, :new

      live "/doctor/patients/:id/triages/:triage_id/edit",
           DoctorsPagePatientLive.TriageIndex,
           :edit

      live "/doctor/patients/:id/visits", DoctorsPagePatientLive.PatientVisitIndex, :index

      live "/doctor/:patient_id/forms", DoctorsPages.EachPatientFormsLive, :index
      live "/doctor/:patient_id/forms/:record_id", DoctorsPages.EachPatientFormsLive, :show

      live "/doctor/patients/:id/forms", DoctorsPages.EachPatientFormsLive, :index
      live "/doctor/patients/:id/forms/:record_id", DoctorsPages.EachPatientFormsLive, :show

      live "/doctor/patients/:id/notes", DoctorsPagePatientLive.DoctorNoteIndex, :index
      live "/doctor/patients/:id/notes/new", DoctorsPagePatientLive.DoctorNoteNew, :index

      live "/doctor/patients/:id/notes/:note_id/after_create",
           DoctorsPagePatientLive.DoctorNoteShow,
           :after_create

      live "/doctor/patients/:id/notes/:note_id/request_lab",
           DoctorsPagePatientLive.DoctorNoteShow,
           :request_lab

      live "/doctor/patients/:id/notes/:note_id/prescribe_drug",
           DoctorsPagePatientLive.DoctorNoteShow,
           :prescribe_drug

      live "/doctor/patients/:id/notes/:note_id/refer_patient",
           DoctorsPagePatientLive.DoctorNoteShow,
           :refer_patient

      live "/doctor/patients/:id/notes/:note_id/request_radiology_test",
           DoctorsPagePatientLive.DoctorNoteShow,
           :request_radiology_test

      # Inside your doctor scope, add these 5 routes:
      live "/doctor/patients/:id/notes/:note_id/new_admission",
           DoctorsPagePatientLive.DoctorNoteShow,
           :new_admission

      live "/doctor/patients/:id/notes/:note_id/new_continuation",
           DoctorsPagePatientLive.DoctorNoteShow,
           :new_continuation

      live "/doctor/patients/:id/notes/:note_id/new_treatment",
           DoctorsPagePatientLive.DoctorNoteShow,
           :new_treatment

      live "/doctor/patients/:id/notes/:note_id/treatments/:treatment_id/edit",
           DoctorsPagePatientLive.DoctorNoteShow,
           :edit_treatment

      live "/doctor/patients/:id/notes/:note_id/new_vitals",
           DoctorsPagePatientLive.DoctorNoteShow,
           :new_vitals

      live "/doctor/patients/:id/notes/:note_id/new_discharge",
           DoctorsPagePatientLive.DoctorNoteShow,
           :new_discharge

      live "/doctor/patients/:id/notes/:note_id/new_cadex",
           DoctorsPagePatientLive.DoctorNoteShow,
           :new_cadex

      live "/doctor/patients/:id/notes/:note_id/cadex/:cadex_id/edit",
           DoctorsPagePatientLive.DoctorNoteShow,
           :edit_cadex

      live "/doctor/patients/:id/notes/:note_id/admit_patient",
           DoctorsPagePatientLive.DoctorNoteShow,
           :admit_patient

      live "/doctor/patients/:id/notes/:note_id/admission_requests/:admission_id/line_items",
           DoctorsPagePatientLive.DoctorNoteShow,
           :line_items

      live "/doctor/patients/:id/notes/:note_id/admission_requests/:admission_id/line_items/:line_item_id/trigger_payment",
           DoctorsPagePatientLive.DoctorNoteShow,
           :trigger_payment_line_item

      live "/doctor/patients/:id/notes/:note_id/admission_requests/:admission_id/trigger_payment",
           DoctorsPagePatientLive.DoctorNoteShow,
           :trigger_payment

      live "/doctor/patients/:id/notes/:note_id/charges/trigger_payment",
           DoctorsPagePatientLive.DoctorNoteShow,
           :trigger_patient_charge_payment

      live "/doctor/patients/:id/notes/:note_id/assign_new_drug/:drug_allocation_id",
           DoctorsPagePatientLive.DoctorNoteShow,
           :assign_new_drug

      live "/doctor/patients/:id/notes/:note_id", DoctorsPagePatientLive.DoctorNoteShow, :index

      live "/doctor/patients/:id/lab_results", DoctorsPagePatientLive.LabResultIndex, :index

      live "/doctor/patients/:id/lab_results/:lab_result_id",
           DoctorsPagePatientLive.LabResultShow,
           :index

      live "/doctor/patients/:id/drug_allocations",
           DoctorsPagePatientLive.DrugAllocationIndex,
           :index

      live "/doctor/patients/:id/drug_allocations/:drug_allocation_id",
           DoctorsPagePatientLive.DrugAllocationShow,
           :index

      live "/doctor/patients/:id/appointments",
           DoctorsPagePatientLive.AppointmentIndex,
           :index

      live "/doctor/patients/:id/appointments/new",
           DoctorsPagePatientLive.AppointmentIndex,
           :new

      live "/doctor/patients/:id/appointments/:appointment_id/edit",
           DoctorsPagePatientLive.AppointmentIndex,
           :edit

      live "/doctor/patients/:id/referrals", ReferralLive.Index, :index
      live "/doctor/patients/:id/referrals/:referral_id", ReferralLive.Show, :show

      live "/doctor/settings", DoctorSettingsLive.Index, :index

      live "/doctor/shift_handovers", ShiftHandoverLive.Index, :index
      live "/doctor/shift_handovers/new", ShiftHandoverLive.Index, :new
      live "/doctor/shift_handovers/:id/edit", ShiftHandoverLive.Index, :edit
      live "/doctor/shift_handovers/:id", ShiftHandoverLive.Show, :show
      live "/doctor/shift_handovers/:id/show/edit", ShiftHandoverLive.Show, :edit

      live "/doctor/requisitions", RequisitionLive.Index, :index
      live "/doctor/requisitions/new", RequisitionLive.Index, :new
      live "/doctor/requisitions/:id/edit", RequisitionLive.Index, :edit
      live "/doctor/requisitions/:id", RequisitionLive.Show, :show

      live "/doctor/forms", ReceptionsPageFormLive.Index, :index
      live "/doctor/forms/dama", ReceptionsPageFormLive.Dama, :index
      live "/doctor/forms/lab_request", ReceptionsPageFormLive.LabRequest, :index
      live "/doctor/forms/discharge_summary", ReceptionsPageFormLive.DischargeSummary, :index
      live "/doctor/forms/radiology_request", ReceptionsPageFormLive.RadiologyRequest, :index
      live "/doctor/forms/prescription_sheet", ReceptionsPageFormLive.PrescriptionSheet, :index
      live "/doctor/forms/sick_leave", ReceptionsPageFormLive.SickLeave, :index
      live "/doctor/forms/surgical_consent", ReceptionsPageFormLive.SurgicalConsent, :index

      live "/doctor/forms/blood_transfusion_consent",
           ReceptionsPageFormLive.BloodTransfusionConsent,
           :index

      live "/doctor/forms/hiv_testing_consent", ReceptionsPageFormLive.HivTestingConsent, :index
      live "/doctor/forms/medical_report", ReceptionsPageFormLive.MedicalReport, :index
      live "/doctor/forms/patient_referral", ReceptionsPageFormLive.PatientReferral, :index
      live "/doctor/forms/payment_receipt", ReceptionsPageFormLive.PaymentReceipt, :index

      live "/doctor/todos", TodosLive.Index, :index
      live "/doctor/todos/new", TodosLive.Index, :new
      live "/doctor/todos/:id/edit", TodosLive.Index, :edit
    end

    live_session :doctor_procedures_pilot,
      on_mount: [
        {MedcampWeb.UserAuth, :mount_current_user},
        {MedcampWeb.Plugs.RequirePanelPermission, :default}
      ] do
      live "/doctor/doctor_procedures",
           DoctorsPagePatientLive.AllDoctorProcedureIndex,
           :index

      live "/doctor/doctor_procedures/types",
           DoctorsPagePatientLive.AllDoctorProcedureIndex,
           :types

      live "/doctor/doctor_procedures/types/:id",
           DoctorsPagePatientLive.DoctorProcedureTypeShow,
           :show

      live "/doctor/:patient_id/doctor_procedures",
           DoctorsPagePatientLive.EachPatientDoctorProcedureIndex,
           :index

      live "/doctor/:patient_id/doctor_procedures/new",
           DoctorsPagePatientLive.EachPatientDoctorProcedureIndex,
           :new

      live "/doctor/:patient_id/doctor_procedures/:id/edit",
           DoctorsPagePatientLive.EachPatientDoctorProcedureIndex,
           :edit

      live "/doctor/:patient_id/doctor_procedures/:id/trigger_payment",
           DoctorsPagePatientLive.EachPatientDoctorProcedureIndex,
           :trigger_payment
    end
  end

  # receptionist scopes

  scope "/", MedcampWeb do
    pipe_through [:browser, :require_authenticated_reception]

    live_session :reception_current_user,
      on_mount: [
        {MedcampWeb.UserAuth, :mount_current_user},
        {MedcampWeb.Plugs.RequirePanelPermission, :default}
      ] do
      live "/reception/dashboard", ReceptionDashboardLive.Index, :index
      live "/reception/patients", ReceptionsPagePatientLive.Index, :index
      live "/reception/patients/:id/patient_code", ReceptionsPagePatientLive.Index, :patient_code
      live "/reception/scan", ReceptionsPage.ScanIndex, :index
      live "/reception/patients/new", ReceptionsPagePatientLive.Index, :new
      live "/reception/patients/:id/edit", ReceptionsPagePatientLive.Index, :edit

      live "/reception/visits", ReceptionsPagePatientLive.PatientVisitIndex, :index
      live "/reception/visits/new", ReceptionsPagePatientLive.PatientVisitIndex, :new

      live "/reception/visits/:id/edit",
           ReceptionsPagePatientLive.PatientVisitIndex,
           :edit

      live "/reception/visits/:id/trigger_payment",
           ReceptionsPagePatientLive.PatientVisitIndex,
           :trigger_payment

      live "/reception/visits/:id/trigger_payment_subsidized",
           ReceptionsPagePatientLive.PatientVisitIndex,
           :trigger_payment_subsidized

      live "/reception/visits/:id/trigger_payment_triage",
           ReceptionsPagePatientLive.PatientVisitIndex,
           :trigger_payment_triage

      live "/reception/appointments", ReceptionsPagePatientLive.AppointmentIndex, :index
      live "/reception/appointments/new", ReceptionsPagePatientLive.AppointmentIndex, :new
      live "/reception/visitors_books", ReceptionVisitorBookLive.Index, :index
      live "/reception/staff_meals", ReceptionStaffMealLive.Index, :index
      live "/reception/community_health_survey", ReceptionCommunityHealthSurveyLive.Index, :index
      live "/reception/mpesa_reconciliation", ReceptionMpesaReconciliationLive.Index, :index

      live "/reception/appointments/:id/edit",
           ReceptionsPagePatientLive.AppointmentIndex,
           :edit

      live "/reception/:patient_id/visits",
           ReceptionsPagePatientLive.EachPatientVisitIndex,
           :index

      live "/reception/:patient_id/visits/new",
           ReceptionsPagePatientLive.EachPatientVisitIndex,
           :new

      live "/reception/:patient_id/visits/:id/edit",
           ReceptionsPagePatientLive.EachPatientVisitIndex,
           :edit

      live "/reception/:patient_id/visits/:id/trigger_payment",
           ReceptionsPagePatientLive.EachPatientVisitIndex,
           :trigger_payment

      live "/reception/:patient_id/visits/:id/trigger_payment_subsidized",
           ReceptionsPagePatientLive.EachPatientVisitIndex,
           :trigger_payment_subsidized

      live "/reception/:patient_id/visits/:id/trigger_payment_triage",
           ReceptionsPagePatientLive.EachPatientVisitIndex,
           :trigger_payment_triage

      live "/reception/:patient_id/patient_overview",
           ReceptionsPagePatientLive.EachPatientOverviewIndex,
           :index

      live "/reception/:patient_id/appointments",
           ReceptionsPagePatientLive.EachPatientAppointmentIndex,
           :index

      live "/reception/:patient_id/appointments/new",
           ReceptionsPagePatientLive.EachPatientAppointmentIndex,
           :new

      live "/reception/:patient_id/appointments/:id/edit",
           ReceptionsPagePatientLive.EachPatientAppointmentIndex,
           :edit

      live "/reception/:patient_id/payments",
           ReceptionsPagePatientLive.EachPatientPaymentsIndex,
           :index

      live "/reception/:patient_id/wallet_deposits",
           ReceptionsPagePatientLive.EachPatientWalletDepositsIndex,
           :index

      live "/reception/:patient_id/wallet_deposits/trigger_payment",
           ReceptionsPagePatientLive.EachPatientWalletDepositsIndex,
           :trigger_payment

      live "/reception/:patient_id/wallet_deposits/:wallet_deposit_id",
           ReceptionsPagePatientLive.EachPatientWalletDepositsShow,
           :show

      live "/reception/settings", ReceptionSettingsLive.Index, :index

      live "/reception/general_inventory", GeneralInventoryItemLive.Index, :index
      live "/reception/stock_requests", ReceptionStockRequestLive, :index
      live "/reception/general_inventory/new", GeneralInventoryItemLive.Index, :new
      live "/reception/general_inventory/:id/edit", GeneralInventoryItemLive.Index, :edit
      live "/reception/general_inventory/:id", GeneralInventoryItemLive.Show, :show

      live "/reception/general_inventory/:id/transaction/new",
           GeneralInventoryItemLive.Show,
           :new_transaction

      live "/reception/general_inventory/:id/transaction/:transaction_id/edit",
           GeneralInventoryItemLive.Show,
           :edit_transaction

      live "/reception/general_inventory/:id/show/edit",
           GeneralInventoryItemLive.Show,
           :edit

      live "/reception/general_inventory/:id/requisition",
           GeneralInventoryItemLive.Show,
           :new_requisition

      live "/reception/shift_handovers", ShiftHandoverLive.Index, :index
      live "/reception/shift_handovers/new", ShiftHandoverLive.Index, :new
      live "/reception/shift_handovers/:id/edit", ShiftHandoverLive.Index, :edit
      live "/reception/shift_handovers/:id", ShiftHandoverLive.Show, :show
      live "/reception/shift_handovers/:id/show/edit", ShiftHandoverLive.Show, :edit

      live "/reception/requisitions", RequisitionLive.Index, :index
      live "/reception/requisitions/new", RequisitionLive.Index, :new
      live "/reception/requisitions/:id/edit", RequisitionLive.Index, :edit
      live "/reception/requisitions/:id", RequisitionLive.Show, :show

      live "/reception/forms", ReceptionsPageFormLive.Index, :index
      live "/reception/forms/dama", ReceptionsPageFormLive.Dama, :index
      live "/reception/forms/lab_request", ReceptionsPageFormLive.LabRequest, :index
      live "/reception/forms/discharge_summary", ReceptionsPageFormLive.DischargeSummary, :index
      live "/reception/forms/radiology_request", ReceptionsPageFormLive.RadiologyRequest, :index
      live "/reception/forms/prescription_sheet", ReceptionsPageFormLive.PrescriptionSheet, :index
      live "/reception/forms/sick_leave", ReceptionsPageFormLive.SickLeave, :index
      live "/reception/forms/surgical_consent", ReceptionsPageFormLive.SurgicalConsent, :index

      live "/reception/forms/blood_transfusion_consent",
           ReceptionsPageFormLive.BloodTransfusionConsent,
           :index

      live "/reception/forms/hiv_testing_consent",
           ReceptionsPageFormLive.HivTestingConsent,
           :index

      live "/reception/forms/medical_report", ReceptionsPageFormLive.MedicalReport, :index
      live "/reception/forms/patient_referral", ReceptionsPageFormLive.PatientReferral, :index
      live "/reception/forms/payment_receipt", ReceptionsPageFormLive.PaymentReceipt, :index

      live "/reception/todos", TodosLive.Index, :index
      live "/reception/todos/new", TodosLive.Index, :new
      live "/reception/todos/:id/edit", TodosLive.Index, :edit
    end
  end

  # pharmacist scopes
  scope "/", MedcampWeb do
    pipe_through [:browser, :require_authenticated_pharmacist]

    live_session :pharmacist_current_user,
      on_mount: [
        {MedcampWeb.UserAuth, :mount_current_user},
        {MedcampWeb.StockAlertsLive, :assign_stock_alerts},
        {MedcampWeb.Plugs.RequirePanelPermission, :default}
      ] do
      live "/pharmacist/dashboard", PharmacistDashboardLive.Index, :index
      live "/pharmacist/scan", PharmacistsLive.ScanIndex, :index
      live "/pharmacist/patients", PharmacistsLive.PatientsIndex, :index
      live "/pharmacist/drugs", PharmacistsLive.DrugsIndex, :index
      live "/pharmacist/stock_requests", PharmacistStockRequestLive, :index
      live "/pharmacist/drugs/:id", PharmacistsLive.DrugsShow, :index
      live "/pharmacist/drugs/:id/requisition", PharmacistsLive.DrugsShow, :requisition

      live "/pharmacist/pending_drug_batches",
           PharmacistsLive.PendingDrugBatchesIndex,
           :index

      live "/pharmacist/pending_drug_batches/:id/scan",
           PharmacistsLive.PendingDrugBatchesIndex,
           :scan

      live "/pharmacist/drug_allocations", PharmacistsLive.DrugAllocationsIndex, :index

      live "/pharmacist/drug_allocations/report",
           PharmacistsLive.DrugAllocationReportIndex,
           :index

      #  live "/pharmacist/drug_allocations/new", PharmacistsLive.DrugAllocationsIndex, :new
      live "/pharmacist/drug_allocations/:id", PharmacistsLive.DrugAllocationsShow, :index

      live "/pharmacist/drug_allocations/:id/give_drug/:drug_assigned_id",
           PharmacistsLive.DrugAllocationsShow,
           :give_drug

      live "/pharmacist/drug_allocations/:id/new_drug_given",
           PharmacistsLive.DrugAllocationsShow,
           :new

      live "/pharmacist/drug_allocations/:id/confirm",
           PharmacistsLive.DrugAllocationsShow,
           :confirm

      live "/pharmacist/drug_allocations/:id/print_preview/:drug_given_id",
           PharmacistsLive.DrugAllocationsShow,
           :print_preview

      live "/pharmacist/drug_allocations/:id/drugs_given/:drug_given_id/edit",
           PharmacistsLive.DrugAllocationsShow,
           :edit

      ## Each Patient

      live "/pharmacist/:patient_id/drug_allocations",
           PharmacistsLive.EachPatientDrugAllocationsIndex,
           :index

      live "/pharmacist/:patient_id/drug_allocations/new",
           PharmacistsLive.EachPatientDrugAllocationsIndex,
           :new

      live "/pharmacist/settings",
           PharmacistsLive.SettingsIndex,
           :index

      live "/pharmacist/consumption_analysis",
           PharmacistsLive.ConsumptionAnalysisIndex,
           :index

      live "/pharmacist/pharmacy_logs",
           PharmacistsLive.PharmacyLogIndex,
           :index

      live "/pharmacist/pharmacy_logs/:log_type",
           PharmacistsLive.PharmacyLogShow,
           :show

      live "/pharmacist/shift_handovers", ShiftHandoverLive.Index, :index
      live "/pharmacist/shift_handovers/new", ShiftHandoverLive.Index, :new
      live "/pharmacist/shift_handovers/:id/edit", ShiftHandoverLive.Index, :edit
      live "/pharmacist/shift_handovers/:id", ShiftHandoverLive.Show, :show
      live "/pharmacist/shift_handovers/:id/show/edit", ShiftHandoverLive.Show, :edit

      live "/pharmacist/requisitions", RequisitionLive.Index, :index
      live "/pharmacist/requisitions/new", RequisitionLive.Index, :new
      live "/pharmacist/requisitions/:id/edit", RequisitionLive.Index, :edit
      live "/pharmacist/requisitions/:id", RequisitionLive.Show, :show

      live "/pharmacist/forms", ReceptionsPageFormLive.Index, :index
      live "/pharmacist/forms/dama", ReceptionsPageFormLive.Dama, :index
      live "/pharmacist/forms/lab_request", ReceptionsPageFormLive.LabRequest, :index
      live "/pharmacist/forms/discharge_summary", ReceptionsPageFormLive.DischargeSummary, :index
      live "/pharmacist/forms/radiology_request", ReceptionsPageFormLive.RadiologyRequest, :index

      live "/pharmacist/forms/prescription_sheet",
           ReceptionsPageFormLive.PrescriptionSheet,
           :index

      live "/pharmacist/forms/sick_leave", ReceptionsPageFormLive.SickLeave, :index
      live "/pharmacist/forms/surgical_consent", ReceptionsPageFormLive.SurgicalConsent, :index

      live "/pharmacist/forms/blood_transfusion_consent",
           ReceptionsPageFormLive.BloodTransfusionConsent,
           :index

      live "/pharmacist/forms/hiv_testing_consent",
           ReceptionsPageFormLive.HivTestingConsent,
           :index

      live "/pharmacist/forms/medical_report", ReceptionsPageFormLive.MedicalReport, :index
      live "/pharmacist/forms/patient_referral", ReceptionsPageFormLive.PatientReferral, :index
      live "/pharmacist/forms/payment_receipt", ReceptionsPageFormLive.PaymentReceipt, :index

      live "/pharmacist/todos", TodosLive.Index, :index
      live "/pharmacist/todos/new", TodosLive.Index, :new
      live "/pharmacist/todos/:id/edit", TodosLive.Index, :edit
    end

    # Controlled-substance register - grant-by-default per stakeholder
    # direction, revocable per user from the admin panels page.
    live_session :pharmacist_dangerous_drug_registers_permission,
      on_mount: [
        {MedcampWeb.UserAuth, :mount_current_user},
        {MedcampWeb.StockAlertsLive, :assign_stock_alerts},
        {MedcampWeb.Plugs.RequirePanelPermission, :default}
      ] do
      live "/pharmacist/dangerous_drug_registers",
           PharmacistsLive.DangerousDrugRegisterIndex,
           :index

      live "/pharmacist/dangerous_drug_registers/:drug_id",
           PharmacistsLive.DangerousDrugRegisterShow,
           :show
    end
  end

  # lab technician scopes

  scope "/", MedcampWeb do
    pipe_through [:browser, :require_authenticated_lab_technician]

    live_session :lab_current_user,
      on_mount: [
        {MedcampWeb.UserAuth, :mount_current_user},
        {MedcampWeb.Plugs.RequirePanelPermission, :default}
      ] do
      live "/lab/dashboard", LabDashboardLive.Index, :index
      live "/lab/scan", LabPages.ScanIndex, :index
      live "/lab/lab_results", LabPagesLabResultLive.Index, :index
      live "/lab/surveillance", LabPagesLabSurveillanceLive.Index, :index
      live "/lab/lab_results/:id", LabPagesLabResultLive.Show, :index

      live "/lab/lab_results/:id/add_test", LabPagesLabResultLive.Show, :add_test
      live "/lab/lab_results/:id/fill/:entry_id", LabPagesLabResultLive.Show, :fill_results
      live "/lab/lab_results/:id/view/:entry_id", LabPagesLabResultLive.Show, :view_results
      live "/lab/lab_results/:id/print_gsrn", LabPagesLabResultLive.Show, :print_gsrn
      live "/lab/lab_tests", LabPagesLabTestLive.Index, :index

      live "/lab/lab_test_templates", LabPagesLabTestTemplateLive.Index, :index
      live "/lab/lab_test_templates/new", LabPagesLabTestTemplateLive.Index, :new
      live "/lab/lab_test_templates/:id/edit", LabPagesLabTestTemplateLive.Index, :edit
      live "/lab/lab_test_templates/:id/preview", LabPagesLabTestTemplateLive.Index, :preview

      ## Each Patient

      live "/lab/:patient_id/lab_results", LabPagesEachPatientLabResultLive.Index, :index

      live "/lab/:patient_id/lab_results/:id",
           LabPagesEachPatientLabResultLive.Show,
           :index

      live "/lab/:patient_id/lab_results/:id/print_preview",
           LabPagesEachPatientLabResultLive.Show,
           :print_preview

      live "/lab/settings", LabPages.SettingsIndex, :index

      live "/lab/lab_allocations", LabAllocationLive.Index, :index
      live "/lab/stock_requests", LabStockRequestLive, :index
      live "/lab/lab_allocations/new", LabAllocationLive.Index, :new
      live "/lab/lab_allocations/:id/edit", LabAllocationLive.Index, :edit

      live "/lab/lab_allocations/:id", LabAllocationLive.Show, :show
      live "/lab/lab_allocations/:id/consumables/new", LabAllocationLive.Show, :new_consumable

      # Quality Assurance
      live "/lab/quality_assurance", LabPagesQualityAssuranceLive.Index, :index
      live "/lab/quality_assurance/:chart_type", LabPagesQualityAssuranceLive.Show, :show
      live "/lab/lab_allocations/:id/show/edit", LabAllocationLive.Show, :edit

      # Duty Rota
      live "/lab/duty_rota", LabPagesDutyRotaLive.Index, :index

      live "/lab/shift_handovers", ShiftHandoverLive.Index, :index
      live "/lab/shift_handovers/new", ShiftHandoverLive.Index, :new
      live "/lab/shift_handovers/:id/edit", ShiftHandoverLive.Index, :edit
      live "/lab/shift_handovers/:id", ShiftHandoverLive.Show, :show
      live "/lab/shift_handovers/:id/show/edit", ShiftHandoverLive.Show, :edit

      live "/lab/requisitions", RequisitionLive.Index, :index
      live "/lab/requisitions/new", RequisitionLive.Index, :new
      live "/lab/requisitions/:id/edit", RequisitionLive.Index, :edit
      live "/lab/requisitions/:id", RequisitionLive.Show, :show

      live "/lab/forms", ReceptionsPageFormLive.Index, :index
      live "/lab/forms/dama", ReceptionsPageFormLive.Dama, :index
      live "/lab/forms/lab_request", ReceptionsPageFormLive.LabRequest, :index
      live "/lab/forms/discharge_summary", ReceptionsPageFormLive.DischargeSummary, :index
      live "/lab/forms/radiology_request", ReceptionsPageFormLive.RadiologyRequest, :index
      live "/lab/forms/prescription_sheet", ReceptionsPageFormLive.PrescriptionSheet, :index
      live "/lab/forms/sick_leave", ReceptionsPageFormLive.SickLeave, :index
      live "/lab/forms/surgical_consent", ReceptionsPageFormLive.SurgicalConsent, :index

      live "/lab/forms/blood_transfusion_consent",
           ReceptionsPageFormLive.BloodTransfusionConsent,
           :index

      live "/lab/forms/hiv_testing_consent", ReceptionsPageFormLive.HivTestingConsent, :index
      live "/lab/forms/medical_report", ReceptionsPageFormLive.MedicalReport, :index
      live "/lab/forms/patient_referral", ReceptionsPageFormLive.PatientReferral, :index
      live "/lab/forms/payment_receipt", ReceptionsPageFormLive.PaymentReceipt, :index

      live "/lab/todos", TodosLive.Index, :index
      live "/lab/todos/new", TodosLive.Index, :new
      live "/lab/todos/:id/edit", TodosLive.Index, :edit
    end
  end

  scope "/", MedcampWeb do
    pipe_through [:browser, :require_authenticated_radiologist]

    live_session :radiologist_current_user,
      on_mount: [
        {MedcampWeb.UserAuth, :mount_current_user},
        {MedcampWeb.Plugs.RequirePanelPermission, :default}
      ] do
      live "/radiologist/dashboard", RadiologistDashboardLive.Index, :index
      live "/radiologist/scan", RadiologistPages.ScanIndex, :index
      live "/radiologist/radiology_results", RadiologistPages.RadiologyResultLive.Index, :index
      live "/radiologist/radiology_results/:id", RadiologistPages.RadiologyResultLive.Show, :show

      ## Each Patient

      live "/radiologist/:patient_id/radiology_results",
           RadiologistPages.EachPatientRadiologyResultLive.Index,
           :index

      live "/radiologist/settings", RadiologistPages.SettingsIndex, :index

      live "/radiologist/shift_handovers", ShiftHandoverLive.Index, :index
      live "/radiologist/shift_handovers/new", ShiftHandoverLive.Index, :new
      live "/radiologist/shift_handovers/:id/edit", ShiftHandoverLive.Index, :edit
      live "/radiologist/shift_handovers/:id", ShiftHandoverLive.Show, :show
      live "/radiologist/shift_handovers/:id/show/edit", ShiftHandoverLive.Show, :edit

      live "/radiologist/requisitions", RequisitionLive.Index, :index
      live "/radiologist/requisitions/new", RequisitionLive.Index, :new
      live "/radiologist/requisitions/:id/edit", RequisitionLive.Index, :edit
      live "/radiologist/requisitions/:id", RequisitionLive.Show, :show

      live "/radiologist/forms", ReceptionsPageFormLive.Index, :index
      live "/radiologist/forms/dama", ReceptionsPageFormLive.Dama, :index
      live "/radiologist/forms/lab_request", ReceptionsPageFormLive.LabRequest, :index
      live "/radiologist/forms/discharge_summary", ReceptionsPageFormLive.DischargeSummary, :index
      live "/radiologist/forms/radiology_request", ReceptionsPageFormLive.RadiologyRequest, :index

      live "/radiologist/forms/prescription_sheet",
           ReceptionsPageFormLive.PrescriptionSheet,
           :index

      live "/radiologist/forms/sick_leave", ReceptionsPageFormLive.SickLeave, :index
      live "/radiologist/forms/surgical_consent", ReceptionsPageFormLive.SurgicalConsent, :index

      live "/radiologist/forms/blood_transfusion_consent",
           ReceptionsPageFormLive.BloodTransfusionConsent,
           :index

      live "/radiologist/forms/hiv_testing_consent",
           ReceptionsPageFormLive.HivTestingConsent,
           :index

      live "/radiologist/forms/medical_report", ReceptionsPageFormLive.MedicalReport, :index
      live "/radiologist/forms/patient_referral", ReceptionsPageFormLive.PatientReferral, :index
      live "/radiologist/forms/payment_receipt", ReceptionsPageFormLive.PaymentReceipt, :index

      live "/radiologist/todos", TodosLive.Index, :index
      live "/radiologist/todos/new", TodosLive.Index, :new
      live "/radiologist/todos/:id/edit", TodosLive.Index, :edit
    end
  end

  # admin scopes
  scope "/", MedcampWeb do
    pipe_through [:browser, :require_authenticated_admin]

    live_session :admin_current_user,
      on_mount: [
        {MedcampWeb.UserAuth, :mount_current_user},
        {MedcampWeb.StockAlertsLive, :assign_stock_alerts},
        {MedcampWeb.Plugs.RequirePanelPermission, :default}
      ] do
      live "/admin/dashboard", AdminDashboardLive.Index, :index
      live "/admin/doctor-note-quality", AdminDoctorNoteQualityLive.Index, :index
      live "/admin/doctor-note-search", AdminDoctorNoteSearchLive.Index, :index
      live "/admin/patients", AdminPatientsLive.Index, :index
      live "/admin/patients/:id", AdminPatientsLive.Show, :show

      live "/admin/feedback", AdminFeedbackLive.Index, :index
      live "/admin/visitors_books", AdminVisitorBookLive.Index, :index

      live "/admin/payments", AdminPaymentsLive.Index, :index
      live "/admin/mpesa_reconciliation", AdminMpesaReconciliationLive.Index, :index
      get "/admin/payments/export", AdminPaymentsController, :export

      live "/admin/procedure", ProcedureLive.Index, :index
      live "/admin/procedure/new", ProcedureLive.Index, :new
      live "/admin/procedure/:id/edit", ProcedureLive.Index, :edit

      live "/admin/subsidized_procedures", SubsidizedProcedureLive.Index, :index
      live "/admin/subsidized_procedures/new", SubsidizedProcedureLive.Index, :new
      live "/admin/subsidized_procedures/:id/edit", SubsidizedProcedureLive.Index, :edit

      live "/lab_tests", AdminLabTestLive.Index, :index
      live "/lab_tests/new", AdminLabTestLive.Index, :new
      live "/lab_tests/:id/edit", AdminLabTestLive.Index, :edit

      live "/admin/rooms", AdminPages.RoomIndex, :index
      live "/admin/rooms/new", AdminPages.RoomIndex, :new
      live "/admin/rooms/:id/edit", AdminPages.RoomIndex, :edit
      live "/admin/rooms/:id/room_gln", AdminPages.RoomIndex, :room_gln

      live "/admin/rooms/:id/room_equipments",
           RoomEquipmentLive.Index,
           :index

      live "/admin/rooms/:id/room_equipments/new",
           RoomEquipmentLive.Index,
           :new

      live "/admin/rooms/:id/room_equipments/:room_equipment_id/edit",
           RoomEquipmentLive.Index,
           :edit

      live "/admin/radiology_tests", RadiologyTestLive.Index, :index
      live "/admin/radiology_tests/new", RadiologyTestLive.Index, :new
      live "/admin/radiology_tests/:id/edit", RadiologyTestLive.Index, :edit

      live "/admin/costings", CostingLive.Index, :index
      live "/admin/costings/new", CostingLive.Index, :new
      live "/admin/costings/:id/edit", CostingLive.Index, :edit

      live "/admin/settings", AdminSettingsLive.Index, :index

      ## Patiengt Visits

      live "/admin/patient_visits", AdminPatientVisitLive.Index, :index

      live "/admin/appointments", AdminAppointmentLive.Index, :index

      live "/admin/drugs", AdminDrugsLive.Index, :index
      live "/admin/drug_allocations", AdminDrugAllocationReportLive.Index, :index
      live "/admin/lab_allocations", AdminLabAllocationsLive.Index, :index
      live "/admin/nurse_allocations", AdminNurseAllocationsLive.Index, :index

      live "/admin/assigned_tags", AssignedTagLive.Index, :index
      live "/admin/assigned_tags/new", AssignedTagLive.Index, :new
      live "/admin/assigned_tags/:id/edit", AssignedTagLive.Index, :edit
      live "/admin/sentry-webhooks", SentryWebhooksLive.Index, :index

      live "/admin/consumption_analysis", AdminConsumptionAnalysisLive.Index, :index
      live "/admin/reporting", AdminMinistryReportingLive.Index, :index
      live "/admin/lab_surveillance", AdminLabSurveillanceLive.Index, :index

      live "/admin/stock_takes", AdminStockTakeLive.Index, :index
      live "/admin/stock_takes/:id", AdminStockTakeLive.Show, :show
      live "/admin/inventory_disposals", AdminInventoryDisposalLive.Index, :index
      live "/admin/inventory_disposals/:id", AdminInventoryDisposalLive.Show, :show

      live "/admin/insurance", AdminInsuranceLive.Index, :index
      live "/admin/insurance/:patient_id", AdminInsuranceLive.Show, :show
      live "/admin/community_health_survey", AdminCommunityHealthSurveyLive.Index, :index

      get "/admin/users/:email", UsersController, :index

      live "/admin/medical_camp", AdminMedicalCampLive.Index, :index
      live "/admin/medical_camp/report", AdminMedicalCampReportLive.Show, :show
      get "/admin/medical_camp/export/summary", MedicalCampExportController, :summary
      get "/admin/medical_camp/export/patients", MedicalCampExportController, :patients
      get "/admin/medical_camp/export/geography", MedicalCampExportController, :geography
      get "/admin/medical_camp/export/diagnoses", MedicalCampExportController, :diagnoses

      live "/admin/daily_activities", AdminDailyActivityLive.Index, :index

      live "/admin/general_inventory", AdminGeneralInventoryLive.Index, :index
      live "/admin/general_inventory/new", AdminGeneralInventoryLive.Index, :new
      live "/admin/general_inventory/:id/edit", AdminGeneralInventoryLive.Index, :edit
      live "/admin/general_inventory/:id", AdminGeneralInventoryLive.Show, :show

      live "/admin/general_inventory/:id/transaction/new",
           AdminGeneralInventoryLive.Show,
           :new_transaction

      live "/admin/general_inventory/:id/transaction/:transaction_id/edit",
           AdminGeneralInventoryLive.Show,
           :edit_transaction

      live "/admin/general_inventory/:id/show/edit", AdminGeneralInventoryLive.Show, :edit

      live "/admin/general_inventory/:id/requisition",
           AdminGeneralInventoryLive.Show,
           :new_requisition

      live "/admin/shift_handovers", ShiftHandoverLive.Index, :index
      live "/admin/shift_handovers/new", ShiftHandoverLive.Index, :new
      live "/admin/shift_handovers/:id/edit", ShiftHandoverLive.Index, :edit
      live "/admin/shift_handovers/:id", ShiftHandoverLive.Show, :show
      live "/admin/shift_handovers/:id/show/edit", ShiftHandoverLive.Show, :edit

      live "/admin/requisitions", RequisitionLive.Index, :index
      live "/admin/requisitions/new", RequisitionLive.Index, :new
      live "/admin/requisitions/:id/edit", RequisitionLive.Index, :edit
      live "/admin/requisitions/:id", RequisitionLive.Show, :show

      live "/admin/forms", ReceptionsPageFormLive.Index, :index
      live "/admin/forms/dama", ReceptionsPageFormLive.Dama, :index
      live "/admin/forms/lab_request", ReceptionsPageFormLive.LabRequest, :index
      live "/admin/forms/discharge_summary", ReceptionsPageFormLive.DischargeSummary, :index
      live "/admin/forms/radiology_request", ReceptionsPageFormLive.RadiologyRequest, :index
      live "/admin/forms/prescription_sheet", ReceptionsPageFormLive.PrescriptionSheet, :index
      live "/admin/forms/sick_leave", ReceptionsPageFormLive.SickLeave, :index
      live "/admin/forms/surgical_consent", ReceptionsPageFormLive.SurgicalConsent, :index

      live "/admin/forms/blood_transfusion_consent",
           ReceptionsPageFormLive.BloodTransfusionConsent,
           :index

      live "/admin/forms/hiv_testing_consent", ReceptionsPageFormLive.HivTestingConsent, :index
      live "/admin/forms/medical_report", ReceptionsPageFormLive.MedicalReport, :index
      live "/admin/forms/patient_referral", ReceptionsPageFormLive.PatientReferral, :index
      live "/admin/forms/payment_receipt", ReceptionsPageFormLive.PaymentReceipt, :index

      live "/admin/todos", TodosLive.Index, :index
      live "/admin/todos/new", TodosLive.Index, :new
      live "/admin/todos/:id/edit", TodosLive.Index, :edit
    end

    # Superuser-sensitive under DHA Reg 12(b)(iv). Every admin has these by
    # default; revoking them is what stops a non-superuser admin from
    # editing users or reading the audit trail.
    live_session :admin_users_permission,
      on_mount: [
        {MedcampWeb.UserAuth, :mount_current_user},
        {MedcampWeb.StockAlertsLive, :assign_stock_alerts},
        {MedcampWeb.Plugs.RequirePanelPermission, :default}
      ] do
      live "/admin/users", AdminUsersLive.Index, :index
      live "/admin/users/new", AdminUsersLive.Index, :new
      live "/admin/users/:id/edit", AdminUsersLive.Index, :edit
      live "/admin/users/:id/user_code", AdminUsersLive.Index, :user_code
      live "/admin/users/:id/permissions", AdminUsersLive.PermissionsIndex, :index
    end

    live_session :admin_audit_logs_permission,
      on_mount: [
        {MedcampWeb.UserAuth, :mount_current_user},
        {MedcampWeb.StockAlertsLive, :assign_stock_alerts},
        {MedcampWeb.Plugs.RequirePanelPermission, :default}
      ] do
      live "/admin/audit_logs", AuditLogsLive.Index, :index
      live "/admin/login_sessions", LoginSessionsLive.Index, :index
      live "/admin/audit_logs/:id", AuditLogLive.Show, :show
    end
  end

  # nurse scopes
  scope "/", MedcampWeb do
    pipe_through [:browser, :require_authenticated_nurse]

    live_session :nurse_current_user,
      # Nurse patient-specific forms

      on_mount: [
        {MedcampWeb.UserAuth, :mount_current_user},
        {MedcampWeb.Plugs.RequirePanelPermission, :default}
      ] do
      live "/nurse/dashboard", NurseDashboardLive.Index, :index
      live "/nurse/:patient_id/forms", NursesPages.EachPatientFormsLive, :index
      live "/nurse/:patient_id/forms/:record_id", NursesPages.EachPatientFormsLive, :show
      live "/nurse/scan", NursesPages.ScanIndex, :index
      live "/nurse/medical_camp_scan", NursesPages.MedicalCampScanIndex, :index
      live "/nurse/all_procedures", NursesPages.AllNurseProcedureIndex, :index
      live "/nurse/patients", NursesPages.PatientIndex, :index
      live "/nurse/patients/new", NursesPages.PatientIndex, :new
      live "/nurse/visits", NursesPages.PatientVisitIndex, :index
      live "/nurse/visits/new", NursesPages.PatientVisitIndex, :new
      live "/nurse/triages", NursesPages.TriageIndex, :index
      live "/nurse/triages/new", NursesPages.TriageIndex, :new
      live "/nurse/triages/:triage_id/edit", NursesPages.TriageIndex, :edit
      live "/nurse/room_allocations", NursesPages.RoomAllocationIndex, :index
      live "/nurse/room_allocations/new", NursesPages.RoomAllocationIndex, :new
      live "/nurse/room_allocations/:id/edit", NursesPages.RoomAllocationIndex, :edit

      live "/nurse/allocations", NursingAllocationLive.Index, :index
      live "/nurse/stock_requests", NurseStockRequestLive, :index
      live "/nurse/allocations/new", NursingAllocationLive.Index, :new
      live "/nurse/allocations/:id", NursingAllocationLive.Show, :show
      live "/nurse/allocations/:id/consumables/new", NursingAllocationLive.Show, :new_consumable

      live "/nurse/room_allocations/:id/trigger_payment",
           NursesPages.RoomAllocationIndex,
           :trigger_payment

      live "/nurse/nurse_notes", NursesPages.NurseNoteIndex, :index
      live "/nurse/nurse_notes/new", NursesPages.NurseNoteIndex, :new
      live "/nurse/nurse_notes/:id/edit", NursesPages.NurseNoteIndex, :edit

      live "/nurse/nurse_procedures", NurseProcedureLive.Index, :index
      live "/nurse/nurse_procedures/new", NurseProcedureLive.Index, :new
      live "/nurse/nurse_procedures/:id/edit", NurseProcedureLive.Index, :edit

      live "/nurse/nurse_procedures/:id/trigger_payment",
           NurseProcedureLive.Index,
           :trigger_payment

      ## Each Patient

      live "/nurse/:patient_id/patient_overview",
           NursesPages.EachPatientOverviewIndex,
           :index

      live "/nurse/:patient_id/mch",
           NursesPages.EachPatientMchIndex,
           :index

      live "/nurse/:patient_id/triages",
           NursesPages.EachPatientTriageIndex,
           :index

      live "/nurse/:patient_id/triages/new",
           NursesPages.EachPatientTriageIndex,
           :new

      live "/nurse/:patient_id/doctor_notes",
           NursesPages.EachPatientDoctorNoteIndex,
           :index

      live "/nurse/:patient_id/doctor_notes/:note_id",
           NursesPages.EachPatientDoctorNoteShow,
           :index

      live "/nurse/:patient_id/doctor_notes/:note_id/new_treatment",
           NursesPages.EachPatientDoctorNoteShow,
           :new_treatment

      live "/nurse/:patient_id/doctor_notes/:note_id/treatments/:treatment_id/edit",
           NursesPages.EachPatientDoctorNoteShow,
           :edit_treatment

      live "/nurse/:patient_id/doctor_notes/:note_id/new_vitals",
           NursesPages.EachPatientDoctorNoteShow,
           :new_vitals

      live "/nurse/:patient_id/doctor_notes/:note_id/new_continuation",
           NursesPages.EachPatientDoctorNoteShow,
           :new_continuation

      live "/nurse/:patient_id/doctor_notes/:note_id/new_admission",
           NursesPages.EachPatientDoctorNoteShow,
           :new_admission

      live "/nurse/:patient_id/doctor_notes/:note_id/new_discharge",
           NursesPages.EachPatientDoctorNoteShow,
           :new_discharge

      live "/nurse/:patient_id/doctor_notes/:note_id/new_cadex",
           NursesPages.EachPatientDoctorNoteShow,
           :new_cadex

      live "/nurse/:patient_id/doctor_notes/:note_id/cadex/:cadex_id/edit",
           NursesPages.EachPatientDoctorNoteShow,
           :edit_cadex

      live "/nurse/:patient_id/triages/:triage_id/edit",
           NursesPages.EachPatientTriageIndex,
           :edit

      live "/nurse/:patient_id/visits",
           NursesPages.EachPatientVisitIndex,
           :index

      live "/nurse/:patient_id/admission_requests",
           NursesPages.EachPatientAdmissionRequestIndex,
           :index

      live "/nurse/:patient_id/admission_requests/:id/trigger_payment",
           NursesPages.EachPatientAdmissionRequestIndex,
           :trigger_payment

      live "/nurse/:patient_id/admission_requests/:id/line_items",
           NursesPages.EachPatientAdmissionRequestIndex,
           :line_items

      live "/nurse/:patient_id/admission_requests/:id/line_items/:line_item_id/trigger_payment",
           NursesPages.EachPatientAdmissionRequestIndex,
           :trigger_payment_line_item

      live "/nurse/:patient_id/room_allocations",
           NursesPages.EachPatientRoomAllocationIndex,
           :index

      live "/nurse/:patient_id/room_allocations/new",
           NursesPages.EachPatientRoomAllocationIndex,
           :new

      live "/nurse/:patient_id/room_allocations/:id/edit",
           NursesPages.EachPatientRoomAllocationIndex,
           :edit

      live "/nurse/:patient_id/room_allocations/:id/trigger_payment",
           NursesPages.EachPatientRoomAllocationIndex,
           :trigger_payment

      live "/nurse/:patient_id/nurse_notes",
           NursesPages.EachPatientNurseNoteIndex,
           :index

      live "/nurse/:patient_id/nurse_notes/new",
           NursesPages.EachPatientNurseNoteIndex,
           :new

      live "/nurse/:patient_id/nurse_notes/:id/edit",
           NursesPages.EachPatientNurseNoteIndex,
           :edit

      live "/nurse/:patient_id/cadex_notes",
           NursesPages.EachPatientCadexNoteIndex,
           :index

      live "/nurse/:patient_id/cadex_notes/new",
           NursesPages.EachPatientCadexNoteIndex,
           :new

      live "/nurse/:patient_id/cadex_notes/:id/edit",
           NursesPages.EachPatientCadexNoteIndex,
           :edit

      live "/nurse/:patient_id/nurse_procedures",
           NursesPages.EachPatientNurseProcedureIndex,
           :index

      live "/nurse/:patient_id/nurse_procedures/new",
           NursesPages.EachPatientNurseProcedureIndex,
           :new

      live "/nurse/:patient_id/nurse_procedures/:id/edit",
           NursesPages.EachPatientNurseProcedureIndex,
           :edit

      live "/nurse/:patient_id/nurse_procedures/:id/trigger_payment",
           NursesPages.EachPatientNurseProcedureIndex,
           :trigger_payment

      live "/nurse/settings", NurseSettingsLive.Index, :index

      live "/nurse/shift_handovers", ShiftHandoverLive.Index, :index
      live "/nurse/shift_handovers/new", ShiftHandoverLive.Index, :new
      live "/nurse/shift_handovers/:id/edit", ShiftHandoverLive.Index, :edit
      live "/nurse/shift_handovers/:id", ShiftHandoverLive.Show, :show
      live "/nurse/shift_handovers/:id/show/edit", ShiftHandoverLive.Show, :edit

      live "/nurse/requisitions", RequisitionLive.Index, :index
      live "/nurse/requisitions/new", RequisitionLive.Index, :new
      live "/nurse/requisitions/:id/edit", RequisitionLive.Index, :edit
      live "/nurse/requisitions/:id", RequisitionLive.Show, :show

      live "/nurse/forms", ReceptionsPageFormLive.Index, :index
      live "/nurse/forms/dama", ReceptionsPageFormLive.Dama, :index
      live "/nurse/forms/lab_request", ReceptionsPageFormLive.LabRequest, :index
      live "/nurse/forms/discharge_summary", ReceptionsPageFormLive.DischargeSummary, :index
      live "/nurse/forms/radiology_request", ReceptionsPageFormLive.RadiologyRequest, :index
      live "/nurse/forms/prescription_sheet", ReceptionsPageFormLive.PrescriptionSheet, :index
      live "/nurse/forms/sick_leave", ReceptionsPageFormLive.SickLeave, :index
      live "/nurse/forms/surgical_consent", ReceptionsPageFormLive.SurgicalConsent, :index

      live "/nurse/forms/blood_transfusion_consent",
           ReceptionsPageFormLive.BloodTransfusionConsent,
           :index

      live "/nurse/forms/hiv_testing_consent", ReceptionsPageFormLive.HivTestingConsent, :index
      live "/nurse/forms/medical_report", ReceptionsPageFormLive.MedicalReport, :index
      live "/nurse/forms/patient_referral", ReceptionsPageFormLive.PatientReferral, :index
      live "/nurse/forms/payment_receipt", ReceptionsPageFormLive.PaymentReceipt, :index
    end
  end

  # inventory manager scopes
  scope "/", MedcampWeb do
    pipe_through [:browser, :require_authenticated_inventory_manager]

    live_session :inventory_manager_current_user,
      on_mount: [
        {MedcampWeb.UserAuth, :mount_current_user},
        {MedcampWeb.StockAlertsLive, :assign_stock_alerts},
        {MedcampWeb.Plugs.RequirePanelPermission, :default}
      ] do
      live "/inventory_manager/dashboard", InventoryManagerDashboardLive.Index, :index
      live "/inventory_manager/in_store", InStoreLive.Index, :index
      live "/inventory_manager/in_store/:id", InStoreLive.Show, :show

      live "/inventory_manager/inventories_received", InventoryReceivedLive.Index, :index
      live "/inventory_manager/inventories_received/new", InventoryReceivedLive.Index, :new
      live "/inventory_manager/inventories_received/:id/edit", InventoryReceivedLive.Index, :edit

      live "/inventory_manager/inventories_received/:id", InventoryReceivedLive.Show, :show

      live "/inventory_manager/inventories_received/:id/show/edit",
           InventoryReceivedLive.Show,
           :edit

      live "/inventory_manager/inventories_received/:id/batches",
           BatchLive.Index,
           :index

      live "/inventory_manager/inventories_received/:id/batches/print_preview/:batch_id",
           BatchLive.Index,
           :print_preview

      live "/inventory_manager/inventories_received/:id/batches/new",
           BatchLive.Index,
           :new

      live "/inventory_manager/inventories_received/:id/batches/:batch_id/edit",
           BatchLive.Index,
           :edit

      live "/inventory_manager/suppliers", SupplierLive.Index, :index
      live "/inventory_manager/suppliers/new", SupplierLive.Index, :new
      live "/inventory_manager/suppliers/:id", SupplierLive.Show, :show
      live "/inventory_manager/suppliers/:id/edit", SupplierLive.Index, :edit

      live "/inventory_manager/batches", AllBatchesLive.Index, :index
      live "/inventory_manager/batches/:id", BatchLive.Show, :show

      live "/inventory_manager/stock_requests", InventoryManagerStockRequestLive, :index

      live "/inventory_manager/inventories_issued", InventoryIssuedLive.Index, :index
      live "/inventory_manager/inventories_issued/new", InventoryIssuedLive.Index, :new

      live "/inventory_manager/inventories_issued/scan",
           InventoryIssuedLive.Index,
           :scan

      live "/inventory_manager/inventories_issued/:id/edit", InventoryIssuedLive.Index, :edit

      live "/inventory_manager/consumption_analysis",
           InventoryManagerConsumptionAnalysisLive.Index,
           :index

      live "/inventory_manager/settings", InventoryManagerSettingsLive.Index, :index

      live "/inventory_manager/requisitions", RequisitionLive.Index, :index
      live "/inventory_manager/requisitions/new", RequisitionLive.Index, :new
      live "/inventory_manager/requisitions/:id/edit", RequisitionLive.Index, :edit
      live "/inventory_manager/requisitions/:id", RequisitionLive.Show, :show
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", MedcampWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:medcamp, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MedcampWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes
  scope "/", MedcampWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete
    delete "/users/log_out/inactivity", UserSessionController, :delete_due_to_inactivity
  end

  scope "/", MedcampWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{MedcampWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/log_in", UserLoginLive, :new
      live "/users/log_in/otp", UserLoginOtpLive, :new

      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
    post "/users/log_in/otp", UserSessionController, :verify_otp
    post "/users/log_in/otp/resend", UserSessionController, :resend_otp
    get "/users/log_in_with_token", UserSessionController, :create_with_token
  end

  scope "/", MedcampWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{MedcampWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      live "/visitor_book/new", VisitorBookLive.New, :new

      live "/daily_activities", DailyActivityLive.Index, :index
      live "/daily_activities/history", DailyActivityLive.Index, :history
      live "/shift_handovers", ShiftHandoverLive.Index, :index
      live "/shift_handovers/new", ShiftHandoverLive.Index, :new
      live "/shift_handovers/:id/edit", ShiftHandoverLive.Index, :edit

      live "/shift_handovers/:id", ShiftHandoverLive.Show, :show
      live "/shift_handovers/:id/show/edit", ShiftHandoverLive.Show, :edit

      live "/requisitions", RequisitionLive.Index, :index
      live "/requisitions/new", RequisitionLive.Index, :new
      live "/requisitions/:id/edit", RequisitionLive.Index, :edit
      live "/requisitions/:id", RequisitionLive.Show, :show

      live "/forms", ReceptionsPageFormLive.Index, :index
      live "/forms/dama", ReceptionsPageFormLive.Dama, :index
      live "/forms/lab_request", ReceptionsPageFormLive.LabRequest, :index
      live "/forms/discharge_summary", ReceptionsPageFormLive.DischargeSummary, :index
      live "/forms/radiology_request", ReceptionsPageFormLive.RadiologyRequest, :index
      live "/forms/prescription_sheet", ReceptionsPageFormLive.PrescriptionSheet, :index
      live "/forms/sick_leave", ReceptionsPageFormLive.SickLeave, :index
      live "/forms/surgical_consent", ReceptionsPageFormLive.SurgicalConsent, :index

      live "/forms/blood_transfusion_consent",
           ReceptionsPageFormLive.BloodTransfusionConsent,
           :index

      live "/forms/hiv_testing_consent", ReceptionsPageFormLive.HivTestingConsent, :index
      live "/forms/medical_report", ReceptionsPageFormLive.MedicalReport, :index
      live "/forms/patient_referral", ReceptionsPageFormLive.PatientReferral, :index
      live "/forms/payment_receipt", ReceptionsPageFormLive.PaymentReceipt, :index
    end
  end

  scope "/supplier", MedcampWeb.Supplier, as: :supplier do
    pipe_through [:browser, :require_authenticated_user, :supplier_auth]

    live_session :supplier,
      layout: {MedcampWeb.Layouts, :supplier},
      on_mount: [
        {MedcampWeb.UserAuth, :ensure_authenticated},
        {MedcampWeb.Plugs.RequireProcurementRole, ~w(supplier)},
        {MedcampWeb.ProcurementPortal, :supplier}
      ] do
      live "/dashboard", DashboardLive, :index
      live "/profile", ProfileLive, :show
      live "/registration/:step", RegistrationLive, :step
      live "/rfqs", RfqInboxLive, :index
      live "/rfqs/:id", RfqInboxLive, :show
      live "/quotes/new/:rfq_id", QuoteLive, :new
      live "/quotes/:id", QuoteLive, :show
      live "/proforma-invoices/new/:quote_id", ProformaLive, :new
      live "/proforma-invoices/:id", ProformaLive, :show
      live "/purchase-orders", PurchaseOrderLive, :index
      live "/purchase-orders/:id", PurchaseOrderLive, :show
      live "/order-flow/invoices", InvoiceLive, :index
      live "/invoices/new/:po_id", InvoiceLive, :new
      live "/invoices/:id", InvoiceLive, :show
      live "/order-flow/shipments", ShipmentLive, :index
      live "/shipments/new/:invoice_id", ShipmentLive, :new
      live "/shipments/:id", ShipmentLive, :show
    end
  end

  scope "/procurement", MedcampWeb.Procurement, as: :procurement do
    pipe_through [:browser, :require_authenticated_user, :procurement_auth]

    live_session :procurement,
      layout: {MedcampWeb.Layouts, :procurement},
      on_mount: [
        {MedcampWeb.UserAuth, :ensure_authenticated},
        {MedcampWeb.Plugs.RequireProcurementRole,
         ~w(procurement_officer stores_officer finance_officer admin)},
        {MedcampWeb.ProcurementPortal, :procurement}
      ] do
      live "/dashboard", DashboardLive, :index
      live "/suppliers", SupplierListLive, :index
      live "/suppliers/:id", SupplierDetailLive, :show
      live "/onboarding", OnboardingQueueLive, :index
      live "/onboarding/:id", OnboardingQueueLive, :review
      live "/rfqs", RfqListLive, :index
      live "/rfqs/new", RfqFormLive, :new
      live "/rfqs/:id", RfqDetailLive, :show
      live "/quotes/:rfq_id", QuoteComparisonLive, :show
      live "/purchase-orders", PoListLive, :index
      live "/purchase-orders/new", PoFormLive, :new
      live "/purchase-orders/new/:rfq_id", PoFormLive, :new_from_rfq
      live "/purchase-orders/:id", PoDetailLive, :show
      live "/invoices", InvoiceListLive, :index
      live "/invoices/:id", InvoiceDetailLive, :show
      live "/grn", GrnListLive, :index
      live "/grn/new/:shipment_id", GrnFormLive, :new
      live "/grn/:id", GrnDetailLive, :show

      scope "/", alias: false do
        live "/requisitions", MedcampWeb.RequisitionLive.Index, :index
        live "/requisitions/new", MedcampWeb.RequisitionLive.Index, :new
        live "/requisitions/:id/edit", MedcampWeb.RequisitionLive.Index, :edit
        live "/requisitions/:id", MedcampWeb.RequisitionLive.Show, :show
      end
    end
  end

  # Supplier portal: suppliers log in and see their own dashboard (supplied / used / remaining)
  scope "/", MedcampWeb do
    pipe_through [:browser, :require_authenticated_user, :supplier_auth]

    live_session :supplier_current_user,
      layout: {MedcampWeb.Layouts, :supplier},
      on_mount: [
        {MedcampWeb.UserAuth, :mount_current_user},
        {MedcampWeb.ProcurementPortal, :supplier}
      ] do
      live "/supplier", SupplierDashboardLive, :show
      live "/supplier/documents", SupplierPortalLive.Documents, :index
      live "/supplier/invoices", SupplierPortalLive.Invoices, :index
      live "/supplier/invoices/new", SupplierPortalLive.Invoices, :new
      live "/supplier/invoices/:id/edit", SupplierPortalLive.Invoices, :edit
      live "/supplier/quotes", SupplierPortalLive.Quotes, :index
      live "/supplier/quotes/new", SupplierPortalLive.Quotes, :new
      live "/supplier/quotes/:id/edit", SupplierPortalLive.Quotes, :edit
      live "/supplier/advance_ship_notices", SupplierPortalLive.AdvanceShipNotices, :index
      live "/supplier/advance_ship_notices/new", SupplierPortalLive.AdvanceShipNotices, :new
      live "/supplier/advance_ship_notices/:id/edit", SupplierPortalLive.AdvanceShipNotices, :edit
      live "/supplier/delivery_notes", SupplierPortalLive.DeliveryNotes, :index
      live "/supplier/delivery_notes/new", SupplierPortalLive.DeliveryNotes, :new
      live "/supplier/delivery_notes/:id/edit", SupplierPortalLive.DeliveryNotes, :edit
      live "/supplier/recalls", SupplierPortalLive.Recalls, :index
      live "/supplier/recalls/new", SupplierPortalLive.Recalls, :new
      live "/supplier/recalls/:id/edit", SupplierPortalLive.Recalls, :edit

      live "/supplier/forms", ReceptionsPageFormLive.Index, :index
      live "/supplier/forms/dama", ReceptionsPageFormLive.Dama, :index
      live "/supplier/forms/lab_request", ReceptionsPageFormLive.LabRequest, :index
      live "/supplier/forms/discharge_summary", ReceptionsPageFormLive.DischargeSummary, :index
      live "/supplier/forms/radiology_request", ReceptionsPageFormLive.RadiologyRequest, :index
      live "/supplier/forms/prescription_sheet", ReceptionsPageFormLive.PrescriptionSheet, :index
      live "/supplier/forms/sick_leave", ReceptionsPageFormLive.SickLeave, :index
      live "/supplier/forms/surgical_consent", ReceptionsPageFormLive.SurgicalConsent, :index

      live "/supplier/forms/blood_transfusion_consent",
           ReceptionsPageFormLive.BloodTransfusionConsent,
           :index

      live "/supplier/forms/hiv_testing_consent", ReceptionsPageFormLive.HivTestingConsent, :index
      live "/supplier/forms/medical_report", ReceptionsPageFormLive.MedicalReport, :index
      live "/supplier/forms/patient_referral", ReceptionsPageFormLive.PatientReferral, :index
      live "/supplier/forms/payment_receipt", ReceptionsPageFormLive.PaymentReceipt, :index
    end
  end

  scope "/support_staff", MedcampWeb do
    pipe_through [:browser, :require_authenticated_support_staff]

    live_session :require_authenticated_support_staff,
      on_mount: [
        {MedcampWeb.UserAuth, :ensure_authenticated},
        {MedcampWeb.Plugs.RequirePanelPermission, :default}
      ] do
      live "/daily_activities", DailyActivityLive.Index, :index
      live "/daily_activities/history", DailyActivityLive.Index, :history

      live "/staff_meals", SupportStaffStaffMealLive.Index, :index

      live "/shift_handovers", ShiftHandoverLive.Index, :index
      live "/shift_handovers/new", ShiftHandoverLive.Index, :new
      live "/shift_handovers/:id/edit", ShiftHandoverLive.Index, :edit
      live "/shift_handovers/:id", ShiftHandoverLive.Show, :show
      live "/shift_handovers/:id/show/edit", ShiftHandoverLive.Show, :edit

      live "/requisitions", RequisitionLive.Index, :index
      live "/requisitions/new", RequisitionLive.Index, :new
      live "/requisitions/:id/edit", RequisitionLive.Index, :edit
      live "/requisitions/:id", RequisitionLive.Show, :show

      live "/forms", ReceptionsPageFormLive.Index, :index
      live "/forms/dama", ReceptionsPageFormLive.Dama, :index
      live "/forms/lab_request", ReceptionsPageFormLive.LabRequest, :index
      live "/forms/discharge_summary", ReceptionsPageFormLive.DischargeSummary, :index
      live "/forms/radiology_request", ReceptionsPageFormLive.RadiologyRequest, :index
      live "/forms/prescription_sheet", ReceptionsPageFormLive.PrescriptionSheet, :index
      live "/forms/sick_leave", ReceptionsPageFormLive.SickLeave, :index
      live "/forms/surgical_consent", ReceptionsPageFormLive.SurgicalConsent, :index

      live "/forms/blood_transfusion_consent",
           ReceptionsPageFormLive.BloodTransfusionConsent,
           :index

      live "/forms/hiv_testing_consent", ReceptionsPageFormLive.HivTestingConsent, :index
      live "/forms/medical_report", ReceptionsPageFormLive.MedicalReport, :index
      live "/forms/patient_referral", ReceptionsPageFormLive.PatientReferral, :index
      live "/forms/payment_receipt", ReceptionsPageFormLive.PaymentReceipt, :index

      live "/todos", TodosLive.Index, :index
      live "/todos/new", TodosLive.Index, :new
      live "/todos/:id/edit", TodosLive.Index, :edit
    end
  end
end
