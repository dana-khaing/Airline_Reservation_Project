defmodule AlbertAirline.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :logger.add_handler(:sentry_handler, Sentry.LoggerHandler, %{
      config: %{
        metadata: [:file, :line],
        rate_limiting: [max_events: 10, interval: 1_000],
        # Bandit (this app's web server) logs unhandled request exceptions
        # under the :bandit domain — excluded by Sentry's own default (meant
        # to avoid double-reporting when Sentry.PlugCapture is also used,
        # which this app doesn't use), so it's included back here to be the
        # only path that reports web-request crashes.
        excluded_domains: [],
        capture_log_messages: true,
        level: :error
      }
    })

    children = [
      AlbertAirlineWeb.Telemetry,
      AlbertAirline.Repo,
      {DNSCluster, query: Application.get_env(:albert_airline, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AlbertAirline.PubSub},
      {AlbertAirline.RateLimiter, clean_period: :timer.minutes(10)},
      # Start a worker by calling: AlbertAirline.Worker.start_link(arg)
      # {AlbertAirline.Worker, arg},
      # Start to serve requests, typically the last entry
      AlbertAirlineWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AlbertAirline.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AlbertAirlineWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
