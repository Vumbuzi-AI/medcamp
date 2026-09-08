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

  ## Public / camp-floor routes

  scope "/", MedcampWeb do
    pipe_through [:browser, :redirect_to_correct_page]

    get "/", PageController, :home
  end

  scope "/", MedcampWeb do
    pipe_through [:browser]

    live "/8017/:gsrn", UserLive.Profile, :index
    live "/8018/:gsrn", PatientCardLive, :index

    post "/8018/:gsrn/medical-camp/session", MedicalCampSessionController, :create
    post "/admin/medical_camp/access/session", AdminMedicalCampPinSessionController, :create
    delete "/admin/medical_camp/access/logout", AdminMedicalCampPinSessionController, :delete

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

  ## Pharmacy scan API (GS1 DataMatrix scan-out / verify)

  scope "/api", MedcampWeb do
    pipe_through :api

    post "/drugs_given_scan_out", DrugsGivenController, :scan_out_drug

    post "/drugs_to_be_scanned/",
         DrugsGivenController,
         :get_drugs_to_be_scanned

    post "/drug_allocations/check_verify", DrugsGivenController, :check_verify
    post "/drug_allocations/scan_verify", DrugsGivenController, :scan_verify
  end

  ## Shared authenticated routes

  scope "/", MedcampWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/patients/:patient_id/documents/:document_type", PatientDocumentController, :show
  end

  ## Doctor

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
      live "/doctor/scan", DoctorsPage.ScanIndex, :index
      live "/doctor/medical_camp_scan", DoctorsPage.MedicalCampScanIndex, :index

      live "/doctor/patients", DoctorsPagePatientLive.Index, :index
      live "/doctor/patients/:id", DoctorsPagePatientLive.Show, :index

      live "/doctor/patient_visits", DoctorsPagePatientLive.VisitsIndex, :index
      live "/doctor/pending_patient_visits", DoctorsPagePatientLive.PendingIndex, :index
      live "/doctor/lab_results", DoctorsPagePatientLive.AllLabResultsLiveIndex, :index

      live "/doctor/patients/:id/triages", DoctorsPagePatientLive.TriageIndex, :index
      live "/doctor/patients/:id/visits", DoctorsPagePatientLive.PatientVisitIndex, :index

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

      live "/doctor/settings", DoctorSettingsLive.Index, :index
    end
  end

  ## Nurse — registration, visits, triage

  scope "/", MedcampWeb do
    pipe_through [:browser, :require_authenticated_nurse]

    live_session :nurse_current_user,
      on_mount: [
        {MedcampWeb.UserAuth, :mount_current_user},
        {MedcampWeb.Plugs.RequirePanelPermission, :default}
      ] do
      live "/nurse/dashboard", NurseDashboardLive.Index, :index
      live "/nurse/scan", NursesPages.ScanIndex, :index
      live "/nurse/medical_camp_scan", NursesPages.MedicalCampScanIndex, :index

      live "/nurse/patients", NursesPages.PatientIndex, :index
      live "/nurse/patients/new", NursesPages.PatientIndex, :new
      live "/nurse/patients/:id/edit", NursesPages.PatientIndex, :edit

      live "/nurse/visits", NursesPages.PatientVisitIndex, :index

      live "/nurse/triages", NursesPages.TriageIndex, :index
      live "/nurse/triages/new", NursesPages.TriageIndex, :new
      live "/nurse/triages/:triage_id/edit", NursesPages.TriageIndex, :edit

      live "/nurse/:patient_id/patient_overview",
           NursesPages.EachPatientOverviewIndex,
           :index

      live "/nurse/:patient_id/triages",
           NursesPages.EachPatientTriageIndex,
           :index

      live "/nurse/:patient_id/triages/new",
           NursesPages.EachPatientTriageIndex,
           :new

      live "/nurse/:patient_id/triages/:triage_id/edit",
           NursesPages.EachPatientTriageIndex,
           :edit

      live "/nurse/:patient_id/visits",
           NursesPages.EachPatientVisitIndex,
           :index

      live "/nurse/:patient_id/doctor_notes",
           NursesPages.EachPatientDoctorNoteIndex,
           :index

      live "/nurse/:patient_id/doctor_notes/:note_id",
           NursesPages.EachPatientDoctorNoteShow,
           :index

      live "/nurse/settings", NurseSettingsLive.Index, :index
    end
  end

  ## Lab technician

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

      live "/lab/surveillance", LabPagesLabSurveillanceLive.Index, :index

      live "/lab/:patient_id/lab_results", LabPagesEachPatientLabResultLive.Index, :index

      live "/lab/:patient_id/lab_results/:id",
           LabPagesEachPatientLabResultLive.Show,
           :index

      live "/lab/:patient_id/lab_results/:id/print_preview",
           LabPagesEachPatientLabResultLive.Show,
           :print_preview

      live "/lab/settings", LabPages.SettingsIndex, :index
    end
  end

  ## Pharmacist — drugs, batches, DataMatrix, dispensing

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

      live "/pharmacist/drugs", PharmacistsLive.DrugsIndex, :index
      live "/pharmacist/drugs/new", PharmacistsLive.DrugsIndex, :new
      live "/pharmacist/drugs/:id/edit", PharmacistsLive.DrugsIndex, :edit
      live "/pharmacist/drugs/:id/new_batch", PharmacistsLive.DrugsShow, :new_batch

      live "/pharmacist/drugs/:id/batches/:batch_id/edit",
           PharmacistsLive.DrugsShow,
           :edit_batch

      live "/pharmacist/drugs/:id/batches/:batch_id/print",
           PharmacistsLive.DrugsShow,
           :print_batch

      live "/pharmacist/drugs/:id", PharmacistsLive.DrugsShow, :index

      live "/pharmacist/drug_allocations", PharmacistsLive.DrugAllocationsIndex, :index

      live "/pharmacist/drug_allocations/report",
           PharmacistsLive.DrugAllocationReportIndex,
           :index

      live "/pharmacist/drug_allocations/:id", PharmacistsLive.DrugAllocationsShow, :index

      live "/pharmacist/drug_allocations/:id/give_drug/:drug_assigned_id",
           PharmacistsLive.DrugAllocationsShow,
           :give_drug

      live "/pharmacist/drug_allocations/:id/new_drug_given",
           PharmacistsLive.DrugAllocationsShow,
           :new_drug_given

      live "/pharmacist/drug_allocations/:id/confirm",
           PharmacistsLive.DrugAllocationsShow,
           :confirm

      live "/pharmacist/drug_allocations/:id/print_preview/:drug_given_id",
           PharmacistsLive.DrugAllocationsShow,
           :print_preview

      live "/pharmacist/drug_allocations/:id/drugs_given/:drug_given_id/edit",
           PharmacistsLive.DrugAllocationsShow,
           :edit_drug_given

      live "/pharmacist/:patient_id/drug_allocations",
           PharmacistsLive.EachPatientDrugAllocationsIndex,
           :index

      live "/pharmacist/settings", PharmacistsLive.SettingsIndex, :index
    end
  end

  ## Admin — full oversight of everything above

  scope "/", MedcampWeb do
    pipe_through [:browser, :require_authenticated_admin]

    get "/admin/medical_camp/export/summary", MedicalCampExportController, :summary
    get "/admin/medical_camp/export/patients", MedicalCampExportController, :patients
    get "/admin/medical_camp/export/geography", MedicalCampExportController, :geography
    get "/admin/medical_camp/export/diagnoses", MedicalCampExportController, :diagnoses
    get "/admin/users/:email", UsersController, :index

    live_session :admin_current_user,
      on_mount: [
        {MedcampWeb.UserAuth, :mount_current_user},
        {MedcampWeb.StockAlertsLive, :assign_stock_alerts},
        {MedcampWeb.Plugs.RequirePanelPermission, :default}
      ] do
      live "/admin/dashboard", AdminDashboardLive.Index, :index

      live "/admin/medical_camp", AdminMedicalCampLive.Index, :index
      live "/admin/medical_camp/report", AdminMedicalCampReportLive.Show, :show

      live "/admin/patients", AdminPatientsLive.Index, :index
      live "/admin/patients/:id", AdminPatientsLive.Show, :show
      live "/admin/patient_visits", AdminPatientVisitLive.Index, :index
      live "/admin/doctor-note-quality", AdminDoctorNoteQualityLive.Index, :index
      live "/admin/doctor-note-search", AdminDoctorNoteSearchLive.Index, :index

      live "/admin/drugs", AdminDrugsLive.Index, :index
      live "/admin/drug_allocations", AdminDrugAllocationReportLive.Index, :index
      live "/admin/consumption_analysis", AdminConsumptionAnalysisLive.Index, :index

      live "/lab_tests", AdminLabTestLive.Index, :index
      live "/lab_tests/new", AdminLabTestLive.Index, :new
      live "/lab_tests/:id/edit", AdminLabTestLive.Index, :edit
      live "/admin/lab_surveillance", AdminLabSurveillanceLive.Index, :index

      live "/admin/settings", AdminSettingsLive.Index, :index
    end

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

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:medcamp, :dev_routes) do
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
    end
  end
end
