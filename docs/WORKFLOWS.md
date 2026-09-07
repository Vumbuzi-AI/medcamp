# Workflows

## Standard Outpatient Visit

1. Reception registers or finds a patient in `/reception/patients` using `Medcamp.Patients`.
2. Reception creates a visit in `/reception/visits` or `/reception/:patient_id/visits` using `Medcamp.PatientVisits`.
3. Reception can trigger payment for the visit from the visit LiveView. Payment state is stored on the visit and related billable records.
4. Nursing performs triage in `/nurse/triages` or `/nurse/:patient_id/triages` using `Medcamp.Triages`.
5. The doctor scans or opens the patient from `/doctor/scan`, reviews visits, and writes a doctor note under `/doctor/patients/:id/notes` using `Medcamp.DoctorNotes`.
6. The doctor may request lab tests, radiology, medication, procedures, referrals, or admission from the doctor-note show screen.
7. Lab works orders under `/lab/lab_results`; radiology works imaging under `/radiologist/radiology_results`; pharmacy dispenses under `/pharmacist/drug_allocations`.
8. Results and medication records are visible back on the patient-specific doctor and nurse screens.

## Admission / Inpatient Flow

1. A doctor starts admission from a doctor note using the `new_admission` or `admit_patient` actions.
2. `Medcamp.AdmissionRequests` creates the admission request and optional line items.
3. Nursing reviews patient admission requests under `/nurse/:patient_id/admission_requests`.
4. Doctors and nurses add inpatient documents from doctor/nurse note views: admission notes, continuation notes, treatment sheets, vitals, discharge summaries, and cadex notes.
5. Room allocations are managed through nurse room allocation screens and `Medcamp.RoomAllocations`.

## Lab Result Flow

1. A doctor creates a lab request from a note.
2. A lab technician opens `/lab/lab_results/:id`, adds templated tests, fills result entries, marks reports complete, and can print a GSRN document.
3. Templated fields are managed in `/lab/lab_test_templates` using `Medcamp.LabTestTemplates`.
4. Result interpretation state is stored on `lab_results` as `interpretation_payload`, `interpretation_status`, and `interpretation_generated_at`.

## Pharmacy Flow

1. Inventory manager receives stock in `/inventory_manager/inventories_received` and creates batches.
2. Drug records and active drug batches link catalog items to stock.
3. Doctors prescribe medicine from a doctor note, creating drug allocations.
4. Pharmacists work `/pharmacist/drug_allocations/:id`, dispense items, confirm/print dispensing, and pharmacy logs/registers capture follow-up activity.

## Procurement Flow

1. Procurement users open `/procurement/dashboard` and create RFQs under `/procurement/rfqs`.
2. Suppliers see invitations in `/supplier/rfqs`, submit quotes, then can create proformas.
3. Procurement compares quotes at `/procurement/quotes/:rfq_id` and creates purchase orders.
4. Suppliers acknowledge purchase orders and submit invoices/shipments.
5. Procurement/stores create and finalise GRNs under `/procurement/grn`.
6. Notifications and sidebar counts are refreshed through `MedcampWeb.ProcurementPortal` and `Medcamp.Procurement.Notifications`.

## Medical Camp Flow

1. Staff use `/medical-camp/scan` or a patient GSRN link (`/8018/:gsrn/medical-camp`) to open the camp flow.
2. Camp pages use a medical-camp layout and GSRN-based patient routing.
3. Protected doctor-note pages require a user session through `MedcampWeb.MedicalCampAuth`.
4. Admin external camp reports are PIN-gated through `/admin/medical_camp/access`, then shown at `/admin/medical_camp/external` and `/admin/medical_camp/external/report`.
5. Admin users can review and export camp reports from `/admin/medical_camp` and export endpoints.

## Support Staff Meal Entry

1. Support staff enter a PIN through `/meals/session`.
2. `MealEntryPinSessionController` stores the support staff user id in the session.
3. `/meals/add` mounts through `MedcampWeb.MealEntryAuth` and records staff meal supply rows through `Medcamp.StaffMeals`.
