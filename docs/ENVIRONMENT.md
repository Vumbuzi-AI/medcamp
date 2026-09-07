# Environment

## Local Development

Development config is in `config/dev.exs`.

| Setting | Value | Required | Notes |
| --- | --- | --- | --- |
| PostgreSQL username | `postgres` | Yes | Local DB user. |
| PostgreSQL password | `postgres` | Yes | Local DB password. |
| PostgreSQL host | `localhost` | Yes | Local database host. |
| Database | `medcamp_dev` | Yes | Created by `mix ecto.setup`. |
| HTTP port | `7700` | Yes | Visit `http://localhost:7700`. |
| `secret_key_base` | configured in dev | Yes | Local-only signing secret. |
| `dev_routes` | `true` | Optional | Enables `/dev/dashboard` and `/dev/mailbox`. |

No `.tool-versions`, `Dockerfile`, or `docker-compose.yml` exists in the repo at the time of writing.

## Production Runtime

Production config is loaded from `config/runtime.exs`.

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `DATABASE_URL` | Yes in prod | none | Ecto connection URL, for example `ecto://USER:PASS@HOST/DATABASE`. |
| `SECRET_KEY_BASE` | Yes in prod | none | Phoenix cookie/session signing secret. Generate with `mix phx.gen.secret`. |
| `PHX_SERVER` | Optional | unset | Starts the endpoint server in releases when set. |
| `PHX_HOST` | Optional | `example.com` | Host used in generated URLs. |
| `PORT` | Optional | `4000` | HTTP port in prod. |
| `POOL_SIZE` | Optional | `10` | DB pool size. |
| `ECTO_IPV6` | Optional | unset | Uses IPv6 socket options when `true` or `1`. |
| `DNS_CLUSTER_QUERY` | Optional | unset | DNS cluster discovery setting. |

## Application Config Values

`config/config.exs` currently includes M-Pesa/PayPal-like credentials directly in source (`consumer_key`, `consumer_secret`, `mpesa_short_code`, `mpesa_passkey`, `client_id`, `secret`). Treat these as secrets and rotate/move them to runtime environment variables before production use.

Mailer is `Swoosh.Adapters.Local` by default. Production mailer settings are only present as comments in `runtime.exs`.

## Asset Pipeline

The project uses Phoenix's default Tailwind plus esbuild setup:

- Tailwind config: `config :tailwind, version: "3.4.3", medcamp: ...`
- Esbuild target: `assets/js/app.js` bundled to `priv/static/assets`.
- Aliases: `assets.setup`, `assets.build`, and `assets.deploy`.

## Mix Aliases

| Alias | Action |
| --- | --- |
| `mix setup` | `deps.get`, `ecto.setup`, `assets.setup`, `assets.build`. |
| `mix ecto.setup` | Creates DB, runs migrations, runs `priv/repo/seeds.exs`. |
| `mix test` | Creates/migrates test DB quietly, then runs tests. |
| `mix credo` | Runs static analysis using `.credo.exs`. |
| `mix assets.build` | Runs Tailwind and esbuild. |
| `mix assets.deploy` | Minifies Tailwind/esbuild output and runs `phx.digest`. |

`mix ecto.drop` and `mix ecto.reset` are intentionally blocked in `mix.exs` to protect clinical and patient data. Local destructive resets require deliberately changing that alias after team confirmation.
