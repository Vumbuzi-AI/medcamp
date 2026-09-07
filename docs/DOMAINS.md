# Domains

Context modules under `lib/medcamp`. Public functions follow Phoenix context
conventions: `list_*`, `filter_*`, `count_*`, `get_*!`, `create_*`,
`update_*`, `delete_*`, `change_*`.

| Domain | Responsibility | Schemas / tables | Notable functions |
| --- | --- | --- | --- |
| `Medcamp.Accounts` | Users, the five camp roles, session tokens, password and OTP flows. | `Accounts.User` (`users`), `Accounts.UserToken` (`users_tokens`) | `register_user/1`, `get_user_by_email/1`, `generate_user_session_token/1`, `User.roles/0` |
| `Medcamp.Authorization` | Per-panel permissions layered on top of roles. Fails closed. | `permissions`, `role_permissions`, `user_permissions`, `permission_reviews` | `can?/2`, `effective_permissions/1`, `toggle_user_permission/4`, `PanelSync.sync/1` |
| `Medcamp.Patients` | Patient demographics, GSRN/PIN allocation, and camp registration. | `Patients.Patient` (`patients`), `PatientDocument` (`patient_documents`) | **`register_for_camp/2`** (creates patient + visit together), `get_available_gsrn/0` |
| `Medcamp.PatientVisits` | The visit and its position in the camp flow. | `PatientVisits.PatientVisit` (`patient_visits`) | `update_status/2`, `mark_triaged/1`, `mark_with_doctor/1`, `mark_lab_pending/1`, `mark_pharmacy_pending/1`, `mark_completed/1`, `list_queue/2`, `current_visit_for_patient/2` |
| `Medcamp.CampFlow` | Advances a visit when a clinical context records work. | none | `advance/2` |
| `Medcamp.Triages` | Nurse observations and emergency scale. | `Triages.Triage` (`triages`) | triage CRUD; `create_triage/1` advances the visit to `triaged` |
| `Medcamp.DoctorNotes` | Consultations, diagnosis, ICD coding, AI review payloads, sub-notes. | `DoctorNotes.DoctorNote` (`doctor_notes`) | note CRUD; `create_doctor_note/1` advances the visit to `with_doctor` |
| `Medcamp.LabTests`, `Medcamp.LabResults`, `Medcamp.LabTestTemplates` | Lab catalogue, orders and results, templated test entry, interpretation. | `lab_tests`, `lab_results`, `lab_test_categories`, `lab_test_templates`, `lab_test_entries` | `create_lab_result/1` (advances to `lab_pending`), `create_camp_lab_order/1`, template CRUD |
| `Medcamp.InventoriesReceived` | The pharmacy **item master**: one row per product, keyed by GTIN. Legacy name; not a goods receipt. | `inventories_received` | `get_inventory_received_by_gtin/1`, `strip_first_three_take_13/1`, `extract_batch/1` |
| `Medcamp.Drugs`, `Medcamp.Batches`, `Medcamp.DrugBatches` | Drug catalogue and physical stock batches with GS1 identifiers. | `drugs`, `batches`, `drug_batches` | `DrugBatches.take_in_batch/1`, `Batches.get_batch_by_gtin_and_batch/2`, active/available batch queries |
| `Medcamp.DrugAllocations`, `Medcamp.DrugsGiven` | Prescriptions and what was actually dispensed, down to the batch. | `drug_allocations` (embeds `drugs_assigned`), `drugs_given` (embeds `batch_allocations`) | `create_drug_allocation/1` (advances to `pharmacy_pending`), `calculate_price/2`, scan-out helpers |
| `Medcamp.StockAlerts`, `Medcamp.ConsumptionAnalysis` | Near-expiry and below-reorder drug alerts; dispensing volumes over time. | reads `drug_batches`, `batches`, `drugs_given` | `list_all_alerts/0`, `alert_count/0`, `consumption_analysis/1` |
| `Medcamp.AllergyHistories` | Known allergies, surfaced before prescribing. | `allergy_histories` | allergy CRUD, `list_allergy_histories_for_patient/1` |
| `Medcamp.AuditLogs`, `Medcamp.UserLoginSessions` | Audit trail of writes and login/logout history. | `audit_logs`, `user_login_sessions` | `Repo.audited_insert/update/delete`, session recording |
| `Medcamp.MedicalCampReports`, `Medcamp.DoctorNoteSearch`, `Medcamp.LabSurveillance` | Camp-level reporting, note search, lab result surveillance. | read-only over the above | report and search aggregations |
| `Medcamp.ArtificialIntelligence.*` | Doctor-note review, voice dictation, OpenAI client. | none | `AIDocReviewer`, `VoiceDictation`, `OpenAI` |
| Utility modules | GS1/GTIN parsing and validation, expiry parsing, notifications, mail, pagination, first-boot user seeding. | none | `Gtin`, `DataMatrixParser`, `CreateGtin`, `VerifyGtin`, `ExpiryFilter`, `Postal`, `Notify`, `Pagination`, `Scheduler` |
