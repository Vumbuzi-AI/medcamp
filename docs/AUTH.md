# Authentication And Authorization

## User Model

Users are stored in `Medcamp.Accounts.User` (`users`). Important fields include `email`, `hashed_password`, `name`, `role`, `otp`, `is_active`, `is_for_medical_camp`, `department_id`, `supplier_id`, `last_logged_in_at`, and `last_logged_out_at`.

Valid roles are defined in `lib/medcamp/accounts/user.ex`:

- Clinical/operations: `admin`, `doctor`, `nurse`, `labtechnician`, `reception`, `pharmacist`, `radiologist`, `support staff`, `inventory_manager`, `housekeeping`, `cleaner`, `staff`.
- Procurement: `supplier`, `procurement_officer`, `stores_officer`, `finance_officer`, `admin`.

## Browser Session

`MedcampWeb.UserAuth` fetches the current user from the session token or signed remember-me cookie. Email login verification is temporarily disabled by `config :medcamp, login_otp_enabled: false`, so successful password verification creates the authenticated session immediately. Setting that option to `true` restores the existing six-digit, single-use email code flow; codes expire after five minutes and permit five attempts. The code verifier is stored server-side in `users_tokens`, while the pending browser session contains only a random nonce and token reference.

Authenticated browser sessions are logged out after five minutes without pointer, keyboard, touch, or scroll activity. The browser synchronizes activity periodically, while `UserAuth` independently rejects a stale session on the next HTTP request. Timeout and explicit logout both delete the database token and remember-me cookie, broadcast the LiveView disconnect, and record logout.

## Route Protection

The router uses these pipeline plugs:

- `:browser`: HTML, session, flash, CSRF, secure headers, and `fetch_current_user`.
- `:api`: JSON.
- `:supplier_auth`: `MedcampWeb.Plugs.RequireProcurementRole` for `supplier`.
- `:procurement_auth`: `RequireProcurementRole` for `procurement_officer`, `stores_officer`, `finance_officer`, and `admin`.

Role-specific plugs in `UserAuth` protect `/doctor`, `/nurse`, `/reception`, `/pharmacist`, `/lab`, `/radiologist`, `/admin`, `/inventory_manager`, and `/support_staff`. Mismatched users are redirected to their role's default page.

Default signed-in redirects:

| Role | Redirect |
| --- | --- |
| `admin` | `/admin/users` |
| `doctor` | `/doctor/scan` |
| `reception` | `/reception/scan` |
| `nurse` | `/nurse/scan` |
| `labtechnician` | `/lab/scan` |
| `pharmacist` | `/pharmacist/scan` |
| `inventory_manager` | `/inventory_manager/inventories_received` |
| `radiologist` | `/radiologist/scan` |
| `support staff` | `/support_staff/daily_activities` |
| procurement roles | `/procurement/dashboard` |
| `supplier` | `/supplier/dashboard` |

## LiveView Mount Hooks

- `MedcampWeb.UserAuth`: `:mount_current_user`, `:ensure_authenticated`, and `:redirect_if_user_is_authenticated`.
- `MedcampWeb.Plugs.RequireProcurementRole`: role checks for procurement and supplier LiveView sessions.
- `MedcampWeb.ProcurementPortal`: assigns active nav, notifications, PubSub subscriptions, counts, and portal layout state.
- `MedcampWeb.StockAlertsLive.assign_stock_alerts`: mounted for admin, pharmacist, and inventory manager sessions.
- `MedcampWeb.MedicalCampAuth`: requires a user session before protected medical camp doctor-note pages.
- `MedcampWeb.MealEntryAuth`: assigns a support staff user from `meal_entry_user_id` stored by the meal PIN session controller.
- `MedcampWeb.AdminMedicalCampExternalAuth`: mounts or requires an active admin from the medical camp admin PIN session.

## PIN Flows

- User OTP/PIN values are normalized to 4 digits by `Accounts.User`.
- `Accounts.get_admin_by_otp/1` backs admin medical camp access.
- `Accounts.get_support_staff_by_otp/1` backs mobile staff meal entry.
- Medical camp patient pages use GSRN routes and protected doctor-note pages check for a session token.

## Adding A Role

1. Add the role to `@non_procurement_roles` or `@procurement_roles` in `Medcamp.Accounts.User`.
2. Add or update a route plug in `MedcampWeb.UserAuth` or `RequireProcurementRole`.
3. Add a router scope/live_session for the new portal.
4. Update `redirect_to_page_conn_case/2`.
5. Seed at least one development user and update README/docs.
6. Add tests for route access and redirect behavior.
