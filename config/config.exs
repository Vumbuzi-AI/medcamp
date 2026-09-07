# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :medcamp,
  ecto_repos: [Medcamp.Repo],
  generators: [timestamp_type: :utc_datetime],
  login_otp_enabled: false

config :medcamp,
  mpesa_env: "api",
  consumer_key: "sGAGY8399D5Ajrfc3FsM8U7yp1KhgSRlUgAGATsEBWdoMrGN",
  consumer_secret: "6oyus6pR63AyqAUio7CJT80sPO1wPgCZfgQG8XNZ7u1pYzayeZB23pF2cYo90QaN",
  mpesa_short_code: "4161369",
  mpesa_code: "4161369",
  mpesa_passkey: "f620ffb7a62a2b54308009158b745fcd1986e912ac5267e53816e34d26f3bd08",
  client_id: "AW_NV6YQCMYfBCA0Xi_SHdp585_jI4nDEvTkCUSqzXouUiEM8VtjeOX3-ktBLVVDKup7i8s-WyQ2bpjH",
  secret: "EPNiDKKdDpt0NGHsgzHa-DobS1eGc4xuwtg6x4I-j0VD6-hBtHZsLhX3vjHT6OZ6smnCPJr0KYqeGok2"

config :sentry,
  dsn:
    "https://7a640afde0052f2f7b93f63037a45e9c@o4511777360314368.ingest.us.sentry.io/4511777366605824",
  environment_name: :prod,
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()]

# Configures the endpoint
config :medcamp, MedcampWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MedcampWeb.ErrorHTML, json: MedcampWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Medcamp.PubSub,
  live_view: [signing_salt: "BcZyrBgH"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :medcamp, Medcamp.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)

config :esbuild,
  version: "0.25.0",
  medcamp: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  medcamp: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
