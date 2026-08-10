# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :albert_airline, :scopes,
  user: [
    default: true,
    module: AlbertAirline.Accounts.Scope,
    assign_key: :current_scope,
    access_path: [:user, :id],
    schema_key: :user_id,
    schema_type: :id,
    schema_table: :users,
    test_data_fixture: AlbertAirline.AccountsFixtures,
    test_setup_helper: :register_and_log_in_user
  ]

config :albert_airline,
  ecto_repos: [AlbertAirline.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :albert_airline, AlbertAirlineWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: AlbertAirlineWeb.ErrorHTML, json: AlbertAirlineWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: AlbertAirline.PubSub,
  live_view: [signing_salt: "EpUsxSdo"]

# Configure LiveView
config :phoenix_live_view,
  # the attribute set on all root tags. Used for Phoenix.LiveView.ColocatedCSS.
  root_tag_attribute: "phx-r"

# Configure the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :albert_airline, AlbertAirline.Mailer, adapter: Swoosh.Adapters.Local

# Configure error tracking. :dsn is unset here — set only in
# config/runtime.exs for :prod, since Sentry only reports events when
# :dsn is configured. client uses Finch (already a transitive dep via
# Req/Swoosh) instead of adding :hackney as a second HTTP client library.
config :sentry,
  client: AlbertAirline.SentryFinchHTTPClient,
  enable_source_code_context: true,
  root_source_code_paths: [File.cwd!()]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  albert_airline: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.3.0",
  albert_airline: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
