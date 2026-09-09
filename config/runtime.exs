import Config

# Mix evaluates this file before starting the application. Load local secrets
# for development and test commands, while allowing variables exported by the
# shell or deployment environment to take precedence.
if config_env() in [:dev, :test] do
  env_file = Path.expand("../.env", __DIR__)

  strip_matching_quotes = fn value ->
    if byte_size(value) >= 2 do
      first = binary_part(value, 0, 1)
      last = binary_part(value, byte_size(value) - 1, 1)

      if first == last and first in ["\"", "'"] do
        binary_part(value, 1, byte_size(value) - 2)
      else
        value
      end
    else
      value
    end
  end

  if File.regular?(env_file) do
    env_file
    |> File.stream!()
    |> Enum.each(fn raw_line ->
      line =
        raw_line
        |> String.trim()
        |> String.replace_prefix("export ", "")

      case String.split(line, "=", parts: 2) do
        [key, value] ->
          key = String.trim(key)

          if line != "" and not String.starts_with?(line, "#") and
               Regex.match?(~r/^[A-Za-z_][A-Za-z0-9_]*$/, key) and
               is_nil(System.get_env(key)) do
            value =
              value
              |> String.trim()
              |> strip_matching_quotes.()

            System.put_env(key, value)
          end

        _other ->
          :ok
      end
    end)
  end
end

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/medcamp start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :medcamp, MedcampWeb.Endpoint, server: true
end

# Reports logger errors to Sentry. Defaults to on in prod and off everywhere
# else, so local dev/test runs don't spam Sentry with noise; set
# SENTRY_LOGGER_ENABLED explicitly to override either way.
sentry_logger_enabled =
  case System.get_env("SENTRY_LOGGER_ENABLED") do
    nil -> config_env() == :prod
    value -> value in ~w(true 1)
  end

config :medcamp, :sentry_logger_enabled, sentry_logger_enabled

if config_env() != :test do
  real_postal_api_key = System.get_env("POSTAL_API_KEY")

  postal_api_key =
    real_postal_api_key ||
      case config_env() do
        :prod ->
          raise """
          environment variable POSTAL_API_KEY is missing.
          Create a MailSafi Postal server API key and expose it to the release.
          """

        # Placeholder so Medcamp.Postal still runs its delivery path in dev;
        # the send itself is redirected below when no real key is present.
        _ ->
          "dev-local"
      end

  config :medcamp, Medcamp.Postal,
    api_url:
      System.get_env("POSTAL_API_URL") ||
        "https://postalmail.mailsafi.com/api/v1/send/message",
    api_key: postal_api_key,
    from: System.get_env("POSTAL_FROM_ADDRESS") || "no-reply@gs1kenya.org",
    from_name: System.get_env("POSTAL_FROM_NAME") || "Tibasasa"

  # Dev mail routing:
  #   - no POSTAL_API_KEY  -> render into the Swoosh mailbox (/dev/mailbox)
  #   - POSTAL_API_KEY set  -> real MailSafi send, same as prod
  if config_env() == :dev and is_nil(real_postal_api_key) do
    config :medcamp, Medcamp.Postal, http_client: Medcamp.Postal.LocalClient
  end
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []
  socket_options = maybe_ipv6 ++ [keepalive: true]

  config :medcamp, Medcamp.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    timeout: String.to_integer(System.get_env("DB_QUERY_TIMEOUT") || "60000"),
    connect_timeout: String.to_integer(System.get_env("DB_CONNECT_TIMEOUT") || "15000"),
    queue_target: String.to_integer(System.get_env("DB_QUEUE_TARGET") || "5000"),
    queue_interval: String.to_integer(System.get_env("DB_QUEUE_INTERVAL") || "10000"),
    socket_options: socket_options

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :medcamp, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :medcamp, MedcampWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :medcamp, MedcampWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :medcamp, MedcampWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.
end
