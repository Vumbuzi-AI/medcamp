# Medcamp

Medcamp is a Phoenix LiveView system for running a medical camp. It has five
roles and one linear patient flow, and it handles no money.

```
nurse registers patient ──▶ visit opens automatically ──▶ nurse triages
                                                              │
                                              doctor writes note
                                                              │
                                   ┌──────────────────────────┴───────────┐
                            requests labs                        prescribes drugs
                                   │                                      │
                       lab fills results                pharmacist dispenses ──▶ done
```

- **Admin** adds users and sees everything: camp reporting and exports, patients,
  visits, drug movement, lab activity, permissions and the audit trail.
- **Nurse** registers patients and triages them. Registering a patient opens
  their visit in the same transaction, so they are immediately in the queue.
- **Doctor** writes notes, requests lab tests and prescribes drugs.
- **Lab technician** fills templated test results against a doctor's request.
- **Pharmacist** maintains drugs and drug batches, confirms each batch by
  scanning its GS1 DataMatrix, and dispenses against prescriptions.

There is no billing, inpatient/ward management, radiology, procurement or
public website — see [docs/WORKFLOWS.md](docs/WORKFLOWS.md) for the flow in
detail.

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

`mix setup`, `mix ecto.setup` and `mix run priv/repo/seeds.exs` create one
account per role when missing, all with password `123456`:

| Role           | Email                       | PIN    |
| -------------- | --------------------------- | ------ |
| Admin          | `admin@gmail.com`           | `1001` |
| Doctor         | `doctor@gmail.com`          | `1002` |
| Nurse          | `nurse@gmail.com`           | `1003` |
| Pharmacist     | `pharmacist@gmail.com`      | `1005` |
| Lab technician | `labtechnician@gmail.com`   | `1006` |

The seeds also create a lab test catalogue and five drugs, each with one
unconfirmed batch — a pharmacist confirms them by scanning under
**Pharmacist → Drug Batches**.

These are convenience credentials, not a security boundary. Change or remove
them before running a real camp.

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

## Documentation

- [Architecture](docs/ARCHITECTURE.md)
- [Domains](docs/DOMAINS.md)
- [Portals](docs/PORTALS.md)
- [Authentication and authorization](docs/AUTH.md)
- [Data model](docs/DATA_MODEL.md)
- [Workflows](docs/WORKFLOWS.md)
- [Environment](docs/ENVIRONMENT.md)
