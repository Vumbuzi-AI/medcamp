# Plan: Trim Medcamp into a Medical Camp Management System

## Goal

Reduce the current full-hospital HMIS into a lean medical camp system with exactly
four clinical roles plus admin, one linear patient flow, and no money anywhere.

## Target flow

```
Admin      → creates users (doctor, nurse, pharmacist, lab technician)
Nurse      → registers patient → patient visit auto-created → triage
Doctor     → picks up visit → doctor note → lab request and/or drug prescription
Lab tech   → sees lab request → fills results → doctor sees results
Pharmacist → maintains drugs + drug batches (GS1 DataMatrix scan-in / scan-out)
           → dispenses prescribed drugs against the visit
```

Everything else is out of scope.

## Roles

Reduce [user.ex](lib/medcamp/accounts/user.ex#L5-L20) to:

```elixir
@roles ~w(admin doctor nurse pharmacist labtechnician)
```

Drop: `reception`, `radiologist`, `support staff`, `inventory_manager`,
`housekeeping`, `cleaner`, `staff`, and all five `@procurement_roles`
(`supplier`, `procurement_officer`, `stores_officer`, `finance_officer`).
`procurement_roles/0` and the procurement/non-procurement split go away entirely.

Nurse absorbs what reception used to do (patient registration + visit creation),
so no reception role is needed.

---

## What we keep

### Domain contexts (`lib/medcamp/`)
- `accounts` — auth, users, roles (trimmed role list)
- `authorization` — role gates (trimmed)
- `patients` — patient registration
- `patient_visits` — auto-created on registration
- `triages` — nurse triage
- `doctor_notes` — clinical notes
- `lab_tests`, `lab_results`, `lab_test_with_templates` — lab request → result
- `drugs`, `drug_batches`, `batches` — pharmacy stock
- `drug_allocations`, `drugs_given` — prescription → dispense
- `gtin` — GS1 / DataMatrix parsing + validation (core to the batch scan flow)
- `uploads`, `user_login_sessions` — supporting infra

### LiveViews (`lib/medcamp_web/live/`)
- `nurses_pages` (trimmed), `doctors_pages` (trimmed), `lab_pages` / `labs_pages`
  (trimmed), `pharmacist_pages` / `pharmacists_pages` (trimmed),
  `admins_pages` (trimmed), `medical_camp_pages` (this is already the camp UI —
  keep `home.ex`, `scan.ex`, `global_scan.ex`, `doctor_notes`,
  `lab_order_component.ex`, `prescribe_medicine_component.ex`)

---

## What we remove

### 1. Payments & money (hard requirement — no payments)
Delete contexts: `mpesas`, `patient_charges`, `costings`, `wallet_deposits`,
`wallet_withdrawals`, `subsidized_procedures`.

Delete LiveViews/controllers: `ConfirmPaymentLive`, `ReceiptLive`,
`MpesaController`, `AdminPaymentsLive`, `AdminPaymentsController`,
`Admin/ReceptionMpesaReconciliationLive`, `CostingLive`,
`SubsidizedProcedureLive`, `ReceptionsPageFormLive.PaymentReceipt`,
`AdminInsuranceLive`.

Delete every `*/trigger_payment*` route (~15 of them across nurse, reception,
doctor) and the `trigger_payment` actions in the LiveViews they point at.

Strip from schemas/migrations: `patient_visits` payment/amount fields,
`payment_type`, `is_paid`/pending-payment flags, insurance fields on `patients`.
Also drop the `number` dependency from [mix.exs](mix.exs) once currency
formatting is gone.

### 2. Inpatient / ward management
Delete: `inpatient`, `admission_requests`, `rooms`, `room_allocations`,
`room_equipments`, `cadex_notes`, `shift_handovers`, `daily_activities`,
`duty_rota`. A camp is outpatient-only and single-session.

Routes: all `/nurse/:patient_id/admission_requests*`, `*/room_allocations*`,
`*/cadex_notes*`, `*/shift_handovers*`, `/duty_rota`, `/daily_activities`,
`/admin/rooms*`, and the `new_admission` / `new_discharge` / `new_continuation`
doctor-note sub-routes.

### 3. Radiology
Delete `radiology_tests`, `radiology_results`, the whole `radiologist_pages` /
`radiologists_pages` scope, `AdminRadiologyTestLive`, and the
`request_radiology_test` doctor-note route + `RadiologyRequest` form.

### 4. Procurement / inventory / stores
Delete: `procurement`, `suppliers`, `requisitions`, `inventories`,
`inventories_issues`, `inventories_received`, `inventory_disposals`,
`stock_takes`, `nursing_allocations`, `nursing_consumables`, `lab_allocations`,
`lab_consumables`, `staff_meals`, `dangerous_drug_registers`.

Delete the entire `inventory_manager` router scope, `supplier_portal_live`,
`supplier`, `stock_requests`, `requisition_live`, `procurement`,
`meal_entry_live`, and the `/api/create_inventory_received`, `/api/create_batch`,
`/api/get_all_suppliers`, `/api/get_all_rooms` endpoints.

> Pharmacy stock stays, but simplified: the pharmacist adds drugs and drug
> batches directly (`/pharmacist/drugs`, `/pharmacist/pending_drug_batches`),
> with no supplier / GRN / requisition chain in front of it.

### 5. Public website & marketing
Delete `lib/medcamp_web/live/website/`, `landing_live`, `tibasasa_live`,
`blogs` + `DoctorBlogLive`, and the `/`, `/home`, `/about`, `/services`,
`/blog`, `/post/:slug`, `/contact` routes. Root `/` redirects straight to
`/users/log_in`.

### 6. Surveys, feedback, misc side-features
Delete: `community_health_surveys` (all three LiveViews), `feedback` +
`AdminFeedbackLive`, `visitors` / `visitor_book_live`, `todos` / `todos_live`,
`sops` / `sops_live`, `assigned_tags`, `departments`, `appointments`,
`referrals`, `procedures`, `nurse_procedures`, `doctor_procedures`,
`quality_assurance`, `ministry_reporting` (+ the top-level
`ministry_reporting/` dir and `docs/ministry-reporting-mcp.md`),
`sentry_webhooks`, `mch` + `mother-child-health.html`, `allergy_histories`,
`pharmacy_logs`, `patient_form_records` + the 14 `ReceptionsPageFormLive.*`
printable forms, `blogs`, `chat`, `telephone_directory`.

Optional keep: `artificial_intelligence` + `/doctor/transcribe` if voice note
dictation is wanted at camp — otherwise delete it and the associated deps.

### 7. Reception role
Delete the whole `/reception/*` scope and `receptions_pages`. Move
`patients/new`, `patients/:id/edit`, and visit creation into the nurse scope
(most already exist there).

---

## Behaviour changes to implement

1. **Auto-create visit on registration.** `Patients.create_patient/1` (or a new
   `Patients.register_for_camp/2`) wraps in an `Ecto.Multi` that also inserts a
   `patient_visit` with status `triage_pending`. Nurse never creates a visit by
   hand — remove `/nurse/visits/new`.

2. **Visit status machine**, replacing payment-gated transitions:
   `triage_pending → triaged → with_doctor → (lab_pending | pharmacy_pending) → completed`
   Each queue page filters on this instead of on payment state.

3. **Doctor note actions** reduce to exactly two: *request lab* and
   *prescribe drug*. Reuse the existing
   [lab_order_component.ex](lib/medcamp_web/live/medical_camp_pages/lab_order_component.ex)
   and [prescribe_medicine_component.ex](lib/medcamp_web/live/medical_camp_pages/prescribe_medicine_component.ex).

4. **Pharmacist DataMatrix flow stays as-is**: add drug → add batch →
   scan GS1 DataMatrix on `/pharmacist/pending_drug_batches/:id/scan` to confirm
   batch (GTIN, batch no, expiry, serial) → dispense via
   `/api/drugs_given_scan_out` and `/drug_allocations/scan_verify`. Keep
   `Medcamp.Gtin` and `Medcamp.Gtin.Validation` untouched.

5. **Admin sees everything that survives the trim.** Admin is the oversight
   role — any page that still exists for a clinical role has an admin-visible
   equivalent. Concretely, admin keeps:

   - **Camp oversight** — `/admin/medical_camp`, `/admin/medical_camp/report`,
     `/admin/medical_camp/access`, and all four
     `/admin/medical_camp/export/*` endpoints (summary, patients, geography,
     diagnoses). This is the primary admin surface.
   - **Users** — `/admin/users` CRUD, `/admin/users/:id/permissions`,
     `/admin/users/:id/user_code`.
   - **Clinical** — `/admin/patients`, `/admin/patients/:id`,
     `/admin/patient_visits`, `/admin/doctor-note-search`,
     `/admin/doctor-note-quality`.
   - **Pharmacy & drug movement** — `/admin/drugs`, `/admin/drug_allocations`
     (the allocation → dispense report), `/admin/consumption_analysis`,
     and read access to drug batches / scan history. Admin can trace a drug
     from batch intake through DataMatrix scan-out to the patient it was
     given to.
     `Medcamp.ConsumptionAnalysis` currently reads both
     `DrugsGiven.DrugGiven` and `InventoriesIssues.InventoryIssued` — keep the
     drug half, strip the inventory half when that context is deleted.
   - **Lab** — `/lab_tests` catalogue CRUD and `/admin/lab_surveillance`
     (test volume + result patterns across the camp).
   - **Audit** — `/admin/audit_logs`, `/admin/audit_logs/:id`,
     `/admin/login_sessions`, `/admin/settings`.

   Removed from admin only because the underlying feature is gone: payments,
   M-Pesa reconciliation, insurance, procedures, subsidized procedures, rooms,
   radiology tests, general inventory, stock takes, inventory disposals,
   requisitions, lab allocations, nurse allocations, shift handovers, daily
   activities, forms, todos, feedback, visitors book, community health survey,
   assigned tags, Sentry webhooks, ministry reporting.

---

## Execution order

| Step | Work | Notes |
|---|---|---|
| 1 | Trim `@roles` in `user.ex`; fix `authorization` + role redirects | Compile will surface dead references |
| 2 | Gut `router.ex` down to 5 scopes | 1576 → target ~250 lines |
| 3 | Delete web LiveViews/controllers for removed features | Router already dropped them |
| 4 | Delete domain contexts + schemas | Work leaf-first to avoid broken assocs |
| 5 | Strip payment fields from surviving schemas | `patient_visits`, `patients` |
| 6 | Squash migrations into one clean baseline | Camp DB starts empty; no data to preserve |
| 7 | Add visit auto-creation + status machine | The only genuinely new code |
| 8 | Trim nav/sidebar components + dashboards per role; keep the admin sidebar broad (camp, users, patients, visits, drugs, drug movement, consumption, lab, audit) | `components/layouts` |
| 9 | Delete orphaned tests; prune `mix.exs` deps | `number`, `httpotion`, `poison` likely unused |
| 10 | Rewrite `docs/` — `DOMAINS.md`, `PORTALS.md`, `WORKFLOWS.md`, `DATA_MODEL.md` | Delete `ENCRYPTION_PLAN.md`, `SENTRY_WEBHOOK_*`, `ministry-reporting-mcp.md`, `landing_page_content.md` if unused |

## Decisions to confirm

- **Migration squash vs. down-migrations** — plan assumes squash to a fresh
  baseline. If any existing camp data must be preserved, this changes to a
  series of drop migrations instead.
- **Keep AI transcription?** Not in the stated flow, but it is a genuine
  time-saver for doctors at a camp. Currently marked optional above.
- **Referrals** — marked for deletion, but a camp often needs "refer to
  district hospital". Cheap to keep if wanted.
