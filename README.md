# Medcamp

Medcamp is a Phoenix LiveView healthcare operations system for Glocal Health Centre. It includes role-based portals for doctors, nurses, reception, pharmacy, laboratory, radiology, administration, inventory, procurement, suppliers, support staff, public website pages, payments, and medical camp workflows.

Major areas:

- Public website, blog, contact, feedback, patient/user/room GS1 lookup pages, and payment receipts.
- Clinical portals for reception, doctors, nurses, laboratory, radiology, pharmacy, and medical camp work.
- Operational portals for administration, inventory, procurement, suppliers, support staff, staff meals, requisitions, SOPs, and duty rotas.
- Shared domains for patients, visits, notes, labs, radiology, medicines, rooms, billing, stock, suppliers, audits, surveys, and MCH.

## Prerequisites

- Elixir `~> 1.14` with a compatible Erlang/OTP installation
- PostgreSQL running locally
- Node/npm for the assets in `assets/package.json`

No `.tool-versions`, `Dockerfile`, or `docker-compose.yml` is currently included, so install the language/runtime versions locally.

## Setup

The development database is configured in `config/dev.exs` as:

- database: `medcamp_dev`
- username: `postgres`
- password: `postgres`
- host: `localhost`

From the project root:

```bash
mix setup
```

This runs dependencies, database create/migrate/seed, Tailwind setup, esbuild setup, and an asset build through the aliases in `mix.exs`.

## Run

```bash
mix phx.server
```

Open http://localhost:7700.

## Seeded Logins

`mix setup`, `mix ecto.setup`, and `mix run priv/repo/seeds.exs` create these development users when missing:

| Role                | Email                     | Password       | PIN    |
| ------------------- | ------------------------- | -------------- | ------ |
| Admin               | `admin@example.com`       | `password1234` | `1001` |
| Doctor              | `doctor@example.com`      | `password1234` | `1002` |
| Nurse               | `nurse@example.com`       | `password1234` | `1003` |
| Reception           | `reception@example.com`   | `password1234` | `1004` |
| Pharmacist          | `pharmacist@example.com`  | `password1234` | `1005` |
| Lab technician      | `lab@example.com`         | `password1234` | `1006` |
| Radiologist         | `radiology@example.com`   | `password1234` | `1007` |
| Inventory manager   | `inventory@example.com`   | `password1234` | `1008` |
| Support staff       | `support@example.com`     | `password1234` | `1009` |
| Procurement officer | `procurement@example.com` | `password1234` | `1010` |
| Stores officer      | `stores@example.com`      | `password1234` | `1011` |
| Finance officer     | `finance@example.com`     | `password1234` | `1012` |
| Supplier            | `supplier@example.com`    | `password1234` | `1013` |

The seeds also create default departments, a demo patient and visit, rooms, suppliers, lab/radiology/procedure catalogs, basic lab templates, and starter pharmacy inventory.

## Common Commands

```bash
mix test
mix format
mix credo
mix run priv/repo/seeds.exs
mix ecto.setup
mix assets.build
mix assets.deploy
```

`mix credo` runs the project's static analysis checks from `.credo.exs`.

`mix ecto.drop` and `mix ecto.reset` are intentionally blocked in `mix.exs` to protect clinical data. If a local reset is truly required, coordinate with the team before changing those aliases.

## Opening a Pull Request

Before opening a pull request:

1. Run `./scripts/check_linters.sh` and fix any formatting, Credo, or test failures.
2. Fill out the pull request summary, changes, and how-to-test sections.
3. Add screenshots or screen recordings for UI changes. Use `N/A` when there are no visual changes.
4. Complete the pull request checklist, including docs, migrations, seeds, and secrets checks when relevant.

### Commit Messages

Use the format `name/what-pr-does` for commit messages.

Examples:

```sh
michael/add-lab-order-filters
sarah/fix-prescription-validation
```

## Configuration Notes

Development uses the default Phoenix esbuild + Tailwind asset pipeline configured in `config/config.exs` and `config/dev.exs`. Production runtime requires `DATABASE_URL` and `SECRET_KEY_BASE`; optional production variables include `PHX_SERVER`, `PHX_HOST`, `PORT`, `POOL_SIZE`, `DNS_CLUSTER_QUERY`, `ECTO_IPV6`, `DB_QUERY_TIMEOUT`, `DB_CONNECT_TIMEOUT`, `DB_QUEUE_TARGET`, and `DB_QUEUE_INTERVAL`. Database timeout values are expressed in milliseconds.

For local development, copy `.env.example` to the Git-ignored `.env` file and set `OPENAI_API_KEY`; `mix phx.server` and other Mix commands load it automatically. Deployed environments must provide the key through their environment. There is no application fallback key. Voice dictation uses `gpt-4o-transcribe` by default and routes only experimental Kenyan-language translation through `gpt-5.6-terra` with reasoning disabled. Use `OPENAI_TRANSCRIBE_MODEL` or `OPENAI_DICTATION_TRANSLATION_MODEL` to override those defaults.

Application email is delivered through the MailSafi Postal API. Set `POSTAL_API_KEY` in every deployed environment. `POSTAL_API_URL` defaults to `https://postalmail.mailsafi.com/api/v1/send/message`, `POSTAL_FROM_NAME` defaults to `GHCE`, and `POSTAL_FROM_ADDRESS` defaults to `no-reply@gs1kenya.org`. The API key is required when the application starts in production.

### Sentry webhooks

The Sentry Custom Integration webhook receiver is `POST /api/webhooks/sentry`. It accepts JSON webhook deliveries without a shared secret; keep the URL limited to the Sentry integration where possible.

Webhook deliveries are retained for 30 days. Admins can inspect a structured incident view and redacted request headers at `/admin/sentry-webhooks`.

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Domains](docs/DOMAINS.md)
- [Portals](docs/PORTALS.md)
- [Authentication and authorization](docs/AUTH.md)
- [Data model](docs/DATA_MODEL.md)
- [Workflows](docs/WORKFLOWS.md)
- [Environment](docs/ENVIRONMENT.md)
- [Sentry webhook setup for CRM and chat](docs/SENTRY_WEBHOOK_CRM_CHAT_SETUP.md)
