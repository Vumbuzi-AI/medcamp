# Encryption Plan — Data at Rest and in Transit

Status: **proposal, not yet implemented**. Nothing in this document has been applied to the codebase.

Scope: the Medcamp Phoenix application (`:medcamp`), its PostgreSQL database, and its outbound
integrations. Driver is PHI protection — the `patients`, `doctor_notes`, `lab_*`, and `users`
tables hold identifiers and clinical data.

---

## 1. Current State

Audited on 2026-07-29 against `main`.

### In transit

| Path | State | Evidence |
| --- | --- | --- |
| Browser → app | No TLS enforcement. No `force_ssl`, no HSTS. Endpoint binds plain HTTP on `PORT`. TLS is presumably terminated by an upstream proxy, but nothing in the app requires it or redirects HTTP→HTTPS. | `config/runtime.exs:130-141`, `force_ssl` only present as a comment at `config/runtime.exs:168-174` |
| App → PostgreSQL | **Unencrypted.** `ssl: true` is commented out. | `config/runtime.exs:106` |
| Session cookie | Signed only, not encrypted. Contents readable by anyone holding the cookie. No `secure` or `http_only` flags set explicitly. | `lib/medcamp_web/endpoint.ex:7-13` |
| LiveView websocket | Inherits the endpoint scheme — so unencrypted wherever HTTP is reachable. | `lib/medcamp_web/endpoint.ex:15-17` |
| Outbound → OpenAI, GTIN, Postal | HTTPS URLs via `Req`/Finch, which verifies certificates by default. Acceptable. | `lib/medcamp/artificial_intelligence/openai.ex:44`, `lib/medcamp/create_gtin.ex:39` |
| Outbound → payments | `HTTPoison.get/2` with no SSL options. Hackney does **not** verify peer certificates by default — MITM-able. | `lib/medcamp/pay.ex:32` |

### At rest

| Item | State |
| --- | --- |
| Patient identifiers (`national_id`, `phone_number`, `email`, `home_address`, `insurance_number`, emergency contact) | Plaintext `:string` columns — `lib/medcamp/patients/patient.ex:5-30` |
| Clinical notes (`symptoms`, `diagnosis`, `clinical_notes`, `past_medical_history`, `management`, `impression`) | Plaintext `:string` — `lib/medcamp/doctor_notes/doctor_note.ex:5-30` |
| Staff PII (`email`, `phone_number`, `id_number`, `license_number`) | Plaintext — `lib/medcamp/accounts/user.ex:26-45` |
| Passwords | Correctly hashed with bcrypt. No change needed. |
| Disk / volume encryption | Not represented in the repo. Must be confirmed with whoever owns the deployment. |
| Backups | Not represented in the repo. Must be confirmed. |
| Committed secrets | `config/config.exs` contains M-Pesa / PayPal credentials in source control (`consumer_key`, `consumer_secret`, `mpesa_passkey`, `client_id`, `secret`). Already flagged in `docs/ENVIRONMENT.md`. These are in git history and must be treated as compromised. |

### The constraint that shapes everything

Patient search does `ilike` across `first_name`, `middle_name`, `last_name`, `national_id`,
`email`, `phone_number`, and `gsrn` — `lib/medcamp/patients.ex:167-173` and `262-268`.

Encrypted columns cannot be `ilike`-matched or usefully indexed. Any field we encrypt drops out
of that search unless we add a deterministic lookup path. This is the single largest source of
work and regression risk in the whole plan.

---

## 2. Guiding Decisions

These are proposals. Confirm before Phase 3 begins.

**D1 — Which fields get application-level encryption.**
Recommendation: **direct identifiers plus clinical free text, but not names.**

- Encrypt: `patients.national_id`, `phone_number`, `email`, `home_address`,
  `insurance_number`, `emergency_contact_name`, `emergency_contact_phone_number`;
  `doctor_notes.symptoms`, `diagnosis`, `clinical_notes`, `past_medical_history`,
  `impression`, `management`, `investigations`, `lifestyle_recommendations`,
  `prescribed_medication`; `users.phone_number`, `id_number`, `license_number`.
- Leave plaintext: patient and user names, `gsrn`, `users.email` (used as the login identifier
  and as a `Repo.get_by` key at `lib/medcamp/accounts.ex:15` and `:327`), ICD codes, all
  foreign keys, timestamps, booleans, and numerics.

Rationale: names alone are weak identifiers, and encrypting them would reduce patient search to
exact-match — a serious regression for reception staff. Keeping `users.email` plaintext keeps
authentication simple; it is staff email, not patient data.

**D2 — Where the key lives.**
Recommendation: **cloud KMS (AWS KMS / GCP KMS / HashiCorp Vault) holding a master key, with
the app fetching a data key at boot**, falling back to a plain `CLOAK_KEY` environment variable
only if the deployment has no KMS available. A key sitting in an env var on the same host as
the database materially weakens the control, because an attacker who reaches the host reaches
both. This decision depends on the hosting environment, which is not visible from the repo.

**D3 — Blind index strategy.**
For each encrypted field that must remain searchable, store a companion
`<field>_hash` column containing `HMAC-SHA256(hmac_key, normalize(value))`, indexed. This gives
exact-match lookup without revealing plaintext. Normalization must be defined per field
(downcase and trim for email; strip non-digits and canonicalize country code for phone;
downcase, trim, and strip spaces/dashes for national ID).

Consequence to accept explicitly: **partial-match search on encrypted fields is gone.** Typing
`0712` will no longer find `+254712345678`. Reception must type the full number or the full
national ID. Name search is unaffected.

**D4 — Rotation.** Cloak supports multiple ciphers with one `default`. Rotation is: add the new
key as `default`, keep the old key as a labelled retiring cipher, run `mix medcamp.rotate_vault`
to re-encrypt every row, then remove the old cipher. Plan for annual rotation and immediate
rotation on suspected compromise.

---

## 3. Phased Implementation

### Phase 0 — Infrastructure prerequisites (no code)

Owned by whoever runs the deployment, not by this repo. Do this first; it is cheap and
protects against stolen disks and leaked backup dumps, which application-level encryption
does not.

1. Confirm or enable full-volume encryption on the PostgreSQL host (managed service checkbox,
   or LUKS on a self-hosted VM).
2. Confirm backups are encrypted at rest and that restore has been tested.
3. Confirm TLS terminates at a proxy in front of the app and note whether it forwards
   `x-forwarded-proto`. Phase 1 depends on this answer.
4. Rotate the M-Pesa / PayPal credentials currently in `config/config.exs` and move them to
   runtime environment variables. They are in git history.

**Exit criteria:** written confirmation of items 1–3; credentials rotated.

### Phase 1 — In transit (small, self-contained diff)

Low risk, high value. Can ship independently of everything below.

1. **Force TLS and HSTS.** In `config/prod.exs`:
   ```elixir
   config :medcamp, MedcampWeb.Endpoint,
     force_ssl: [
       hsts: true,
       rewrite_on: [:x_forwarded_proto, :x_forwarded_host]
     ]
   ```
   `rewrite_on` is not optional behind a proxy — without it Plug sees plain HTTP on the internal
   hop and issues an infinite redirect loop. Verify against the Phase 0 item 3 answer before
   deploying.

2. **Verifying TLS to PostgreSQL.** Replace the commented `ssl: true` at
   `config/runtime.exs:106`:
   ```elixir
   ssl: [
     verify: :verify_peer,
     cacerts: :public_key.cacerts_get(),
     server_name_indication: String.to_charlist(db_host),
     customize_hostname_check: [
       match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
     ]
   ]
   ```
   Bare `ssl: true` encrypts but does not authenticate the server, so it does not stop an
   active MITM. `db_host` must be parsed out of `DATABASE_URL`. If the database presents a
   private CA certificate, ship that CA and use `cacertfile:` instead of `cacerts:`.

3. **Encrypt the session cookie.** In `lib/medcamp_web/endpoint.ex`, add to `@session_options`:
   ```elixir
   encryption_salt: "<generated>",
   secure: true,
   http_only: true
   ```
   This upgrades the cookie from signed-only to AES-encrypted. **This logs every user out on
   deploy** — existing cookies become undecryptable. Schedule accordingly.

4. **Certificate verification on hackney.** `lib/medcamp/pay.ex:32` uses `HTTPoison.get/2` with
   no SSL options. Either pass
   `hackney: [ssl_options: [verify: :verify_peer, cacerts: :public_key.cacerts_get()]]`,
   or port the call to `Req`, which verifies by default. Porting to `Req` is preferable — the
   rest of the codebase already uses it, and it removes a dependency-specific footgun.

**Exit criteria:** HTTP request to the prod host returns a 301 to HTTPS; HSTS header present;
`SELECT ssl FROM pg_stat_ssl` shows the app connection as encrypted; payment integration still
succeeds against sandbox.

### Phase 2 — Vault scaffolding (no data touched)

1. Add `{:cloak_ecto, "~> 1.3"}` to `mix.exs`.
2. Add `lib/medcamp/vault.ex`:
   ```elixir
   defmodule Medcamp.Vault do
     use Cloak.Vault, otp_app: :medcamp
   end
   ```
3. Configure ciphers in `config/runtime.exs` (prod reads from KMS or `CLOAK_KEY`; dev and test
   use a fixed local key so the suite is deterministic):
   ```elixir
   config :medcamp, Medcamp.Vault,
     ciphers: [
       default: {Cloak.Ciphers.AES.GCM,
         tag: "AES.GCM.V1",
         key: Base.decode64!(System.fetch_env!("CLOAK_KEY")),
         iv_length: 12}
     ]
   ```
4. Add `Medcamp.Vault` to the supervision tree in `lib/medcamp/application.ex`, **before** `Medcamp.Repo`.
5. Add the Ecto types: `Medcamp.Encrypted.Binary`, and `Medcamp.Hashed.HMAC` for blind indexes.
6. Document `CLOAK_KEY` / `CLOAK_HMAC_KEY` in `docs/ENVIRONMENT.md`.

**Exit criteria:** app boots in all environments; `mix test` green; no schema changes yet.

### Phase 3 — Patients table (the pilot)

Do one table end to end before touching the others. Patients is the right pilot: highest value,
and it exercises the hardest problem (search).

Per encrypted field, the cutover is four deploys — never one. The point is that at every step
the running code can read the data written by the previous step.

1. **Deploy A — add columns.** Migration adds nullable `<field>_encrypted :binary` and, for
   searchable fields, `<field>_hash :binary` with an index. No schema changes, no behaviour
   change.
2. **Deploy B — dual write.** Changesets write both plaintext and encrypted/hash columns.
   Reads still come from plaintext. Backfill task `mix medcamp.encrypt_patients` streams existing
   rows in batches inside a transaction and populates the new columns. Must be idempotent and
   resumable — it will run against production volume.
3. **Deploy C — cut over reads.** Schema fields point at the encrypted columns. Rewrite the
   search in `lib/medcamp/patients.ex:160-180` and `:255-275`: keep `ilike` on the name fields,
   and add exact-match `where` clauses on `national_id_hash` and `phone_number_hash` computed
   from the normalized search term. Rewrite `find_patient_by_phone_number/1`
   (`lib/medcamp/patients.ex:508`) and `find_patient_by_email/1` to look up by hash.
   Audit every other `Repo.get_by` and `where` touching these fields before this deploy.
4. **Deploy D — drop plaintext.** Only after Deploy C has run clean for at least one full
   business cycle and a backup taken under Deploy C has been test-restored. Migration drops the
   old columns and renames `<field>_encrypted` → `<field>`.

**Exit criteria:** patient search by full national ID and full phone number works; name search
unchanged; `SELECT national_id FROM patients LIMIT 1` returns ciphertext; public booking flow
(`find_public_booking_patient/1`) still matches returning patients.

### Phase 4 — Clinical notes and staff PII

Repeat the Phase 3 four-deploy pattern for `doctor_notes` and `users`. Simpler than patients —
these fields are read by association, not searched, so no blind indexes are needed unless an
audit turns up a query. Grep for `ilike`, `where`, and `get_by` against each field first.

`lab_*`, `cadex_notes`, and any other clinical tables follow the same pattern; enumerate them
during Phase 4 planning rather than guessing now.

### Phase 5 — Operational hardening

1. Write `mix medcamp.rotate_vault` for key rotation (D4) and rehearse it in staging.
2. Confirm no plaintext PHI reaches Sentry. `Sentry.PlugContext` is installed at
   `lib/medcamp_web/endpoint.ex:28`; changeset errors and params can carry PHI. Configure scrubbing.
3. Confirm PHI is not logged. Prod is at `:info` (`config/prod.exs:17`), but Ecto query logging
   and error reports can still leak parameters.
4. Add `redact: true` to encrypted schema fields so they do not appear in `inspect/1` output.
5. Check CSV export paths (`{:csv, "~> 3.0"}` is a dependency) — exports decrypt by definition
   and are a legitimate exfiltration route. Ensure they are permission-gated and audit-logged.
   `lib/medcamp/audit_logs.ex` already exists and should cover this.

---

## 4. Risks and Non-Goals

**Risks**

- *Search regression.* Partial matching on national ID and phone disappears (D3). Reception
  staff need to be told before Deploy C, not after.
- *Key loss means data loss.* There is no recovery from a lost Cloak key. Key backup and
  escrow must exist before Phase 3 Deploy B, or the backfill is a data-destruction event.
- *Backfill on production volume.* Row counts are unknown from the repo. Measure first; the
  task must be batched, idempotent, and resumable.
- *Forced logout.* Phase 1 item 3 invalidates all sessions.
- *Redirect loop.* Phase 1 item 1 misconfigured against the actual proxy takes the site down.
  This is why Phase 0 item 3 is a prerequisite.
- *`mix` cannot run in the current sandbox*, so migrations, the backfill, and the test suite
  must be exercised in a real environment before any of this reaches production.

**Explicitly not covered**

- Field-level encryption does not protect against a compromised application server — the app
  holds the key by necessity.
- No client-side or end-to-end encryption is proposed; the server reads all PHI.
- Access control, session timeout, and MFA are separate concerns from encryption and are not
  addressed here.
- Compliance mapping (Kenya Data Protection Act 2019, HIPAA) is not attempted. This plan
  describes controls, not a certification.

---

## 5. Suggested Sequencing

Phase 0 and Phase 1 are independent of the rest and should ship first — they are days of work
and close the widest gaps (unencrypted database connection, no TLS enforcement). Phases 2–4 are
the larger project and depend on D1, D2, and the Phase 0 confirmations.
