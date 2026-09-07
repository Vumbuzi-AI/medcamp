defmodule Medcamp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    if Application.get_env(:medcamp, :sentry_logger_enabled, false) do
      :logger.add_handler(:my_sentry_handler, Sentry.LoggerHandler, %{
        config: %{metadata: [:file, :line]}
      })
    end

    children = [
      MedcampWeb.Telemetry,
      Medcamp.Repo,
      {DNSCluster, query: Application.get_env(:medcamp, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Medcamp.PubSub},
      # Supervises fire-and-forget background work (e.g. AI lab interpretation)
      {Task.Supervisor, name: Medcamp.TaskSupervisor},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Medcamp.Finch},
      # Start a worker by calling: Medcamp.Worker.start_link(arg)
      # {Medcamp.Worker, arg},
      # Start to serve requests, typically the last entry
      MedcampWeb.Endpoint,
      {Medcamp.Scheduler, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Medcamp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MedcampWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
