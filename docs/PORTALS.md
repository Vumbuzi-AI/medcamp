# Portals

Routes are in `lib/medcamp_web/router.ex`. Each role scope is gated by a
`require_authenticated_<role>` plug in `MedcampWeb.UserAuth`, which bounces a
signed-in user of another role to their own landing page. On top of that,
`MedcampWeb.Plugs.RequirePanelPermission` checks the per-panel permission the
sidebar link is guarded by, so hiding a tab also closes its URL.

Both halves read from `MedcampWeb.SidebarCatalog`, the single source of truth
for what each role can see.

| Portal | Role | URL scope | Screens |
| --- | --- | --- | --- |
| Login | anonymous | `/`, `/users/log_in`, `/users/log_in/otp`, `/users/reset_password` | `/` redirects to login; there is no public website. |
| Nurse | `nurse` | `/nurse/*` | Scan, patients (register/edit), visits, triages, per-patient overview / triages / visits / doctor notes (read-only), settings. |
| Doctor | `doctor` | `/doctor/*` | Scan, dashboard, patient list, my visits, pending cases, all lab results; per-patient notes, triages, visits, lab results, drug allocations. Notes support lab requests, prescriptions, AI review and voice dictation. |
| Laboratory | `labtechnician` | `/lab/*` | Scan, dashboard, lab results queue, add/fill/view templated test entries, print GSRN, lab tests, templates, surveillance, per-patient results. |
| Pharmacy | `pharmacist` | `/pharmacist/*` | Scan, dashboard, drug catalogue, drug batches (add + DataMatrix confirm), drug allocations, dispensing and print preview, allocation report, per-patient allocations. |
| Administration | `admin` | `/admin/*`, `/lab_tests` | Camp overview and report, patients, visits, doctor-note quality and search, drugs, drug allocations, consumption analysis, lab tests, lab surveillance, users and permissions, login sessions, audit logs, settings, CSV exports. |
| Medical camp (link-based) | patient GSRN / camp PIN | `/medical-camp/scan`, `/8018/:gsrn/medical-camp/*`, `/admin/medical_camp/{access,external}` | Global scan, patient camp home, triage, camp doctor notes, external admin camp access and report. |
| Pharmacy scan API | scanner hardware | `/api/drugs_given_scan_out`, `/api/drugs_to_be_scanned`, `/api/drug_allocations/{check_verify,scan_verify}` | GS1 DataMatrix verification and scan-out during dispensing. |
| Dev tools | dev only, when `:dev_routes` | `/dev/dashboard`, `/dev/mailbox` | LiveDashboard, Swoosh mailbox preview. |

## Role landing pages

`MedcampWeb.UserAuth.default_path_for_role/1`:

| Role | Lands on |
| --- | --- |
| `admin` | `/admin/dashboard` |
| `doctor` | `/doctor/scan` |
| `nurse` | `/nurse/scan` |
| `labtechnician` | `/lab/scan` |
| `pharmacist` | `/pharmacist/scan` |
