# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :screens, ScreensWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "0XmZH5iePmWrvV+PgrsU5z6WFgYupY2Zoh7FEk8pzuDLWftBrF/KtLBbG615wstt",
  render_errors: [view: ScreensWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Screens.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Use the HTML encoder for SSML files as well
config :phoenix, :format_encoders,
  html: Phoenix.Template.HTML,
  ssml: Phoenix.Template.HTML

# Use Jason for JSON parsing in ExAws
config :ex_aws, json_codec: Jason

config :ex_aws, :hackney_opts,
  recv_timeout: 30_000,
  pool: :ex_aws_pool

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase

config :screens,
  redirect_http?: true,
  cognito_group: "screens-admin"

config :screens, ScreensWeb.AuthManager, issuer: "screens"

config :ueberauth, Ueberauth,
  providers: [
    cognito: {Ueberauth.Strategy.Cognito, []}
  ]

config :ueberauth, Ueberauth.Strategy.Cognito,
  auth_domain: {System, :get_env, ["COGNITO_DOMAIN"]},
  client_id: {System, :get_env, ["COGNITO_CLIENT_ID"]},
  user_pool_id: {System, :get_env, ["COGNITO_USER_POOL_ID"]},
  aws_region: {System, :get_env, ["COGNITO_AWS_REGION"]}

config :screens,
  gds_dms_username: "mbtadata@gmail.com",
  config_fetcher: Screens.Config.State.Fetch,
  config_s3_bucket: "mbta-ctd-config",
  audio_psa_s3_bucket: "mbta-dotcom",
  audio_psa_s3_directory: "/screens/audio_assets/psa/",
  signs_ui_s3_bucket: "mbta-signs",
  signs_ui_s3_path: "config.json",
  api_v3_url: "https://api-v3.mbta.com/"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
