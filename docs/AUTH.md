# Authentication And Authorization

## User Model

Users are stored in `Medcamp.Accounts.User` (`users`). Notable fields:
`email`, `hashed_password`, `name`, `role`, `otp`, `is_active`,
`is_for_medical_camp`, `gsrn`, `last_logged_in_at`, `last_logged_out_at`.

The camp has five roles, defined in `lib/medcamp/accounts/user.ex`:

```elixir
@roles ~w(admin doctor nurse pharmacist labtechnician)
```

There is no self-registration — an admin creates every account at
`/admin/users`.

## Browser Session

`MedcampWeb.UserAuth` fetches the current user from the session token or the
signed remember-me cookie. Email login verification is disabled by
`config :medcamp, login_otp_enabled: false`, so a correct password creates the
session immediately. Setting that option to `true` restores the six-digit,
single-use email code flow; codes expire after five minutes and allow five
attempts. The verifier lives server-side in `users_tokens`, while the pending
browser session holds only a nonce and token reference.

Sessions are logged out after five minutes without pointer, keyboard, touch or
scroll activity. The browser reports activity periodically and `UserAuth`
independently rejects a stale session on the next request. Timeout and
explicit logout both delete the token and remember-me cookie, disconnect the
LiveView and record the logout.

## Two Layers Of Access Control

**Role** decides which scope you may enter. `UserAuth` generates one
`require_authenticated_<role>` plug per camp role from a single clause, and a
signed-in user of another role is bounced to their own landing page.

**Panel permission** decides which pages within that scope you actually see.
`Medcamp.Authorization.can?/2` resolves a permission slug for a user, with a
per-user override winning over the role default and an unknown slug always
denied — it fails closed.

`MedcampWeb.SidebarCatalog` is the single source of truth for both halves:

* `MedcampWeb.SidebarComponents` renders only the tabs the user can see.
* `MedcampWeb.Plugs.RequirePanelPermission` refuses the routes behind a tab
  the user cannot see, so hiding a link also closes the URL.

Because `can?/2` fails closed, the `seed_panel_permissions` migration must
run — it derives every permission from the catalog via
`Medcamp.Authorization.PanelSync.sync/1` and grants each role its own panels.
Without it, every page is refused for everyone.

Admins manage per-user overrides at `/admin/users/:id/permissions`.

## Default Landing Pages

`UserAuth.default_path_for_role/1`:

| Role | Redirect |
| --- | --- |
| `admin` | `/admin/dashboard` |
| `doctor` | `/doctor/scan` |
| `nurse` | `/nurse/scan` |
| `labtechnician` | `/lab/scan` |
| `pharmacist` | `/pharmacist/scan` |

## LiveView Mount Hooks

- `MedcampWeb.UserAuth`: `:mount_current_user`, `:ensure_authenticated`,
  `:redirect_if_user_is_authenticated`.
- `MedcampWeb.Plugs.RequirePanelPermission`: `:default`, on every role scope.
- `MedcampWeb.StockAlertsLive.assign_stock_alerts`: admin and pharmacist
  sessions, for the near-expiry / low-stock badge.
- `MedcampWeb.MedicalCampAuth`: gates the camp doctor-note pages.
- `MedcampWeb.AdminMedicalCampExternalAuth`: the admin camp PIN session.

## PIN Flows

- OTP/PIN values are normalized to four digits by `Accounts.User`.
- `Accounts.get_admin_by_otp/1` backs admin medical camp access.
- Camp patient pages are reached by GSRN; the protected doctor-note pages
  additionally require a camp session token.

## Adding A Role

1. Add it to `@roles` in `Medcamp.Accounts.User`.
2. Add it to `@role_gates` in `MedcampWeb.UserAuth` and give it a landing page
   in `default_path_for_role/1`.
3. Add a router scope and `live_session`.
4. Add its tab groups to `MedcampWeb.SidebarCatalog` (`@roles`,
   `tab_groups/1`, `panel_role_for_path/1`, and patient tabs if it opens
   patient records).
5. Add a migration calling `PanelSync.sync(repo())` so the new panels become
   grantable.
6. Add tests for route access and redirect behaviour.
