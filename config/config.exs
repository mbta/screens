# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :screens, ScreensWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "0XmZH5iePmWrvV+PgrsU5z6WFgYupY2Zoh7FEk8pzuDLWftBrF/KtLBbG615wstt",
  render_errors: [view: ScreensWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: ScreensWeb.PubSub

# Include 2 logger backends
config :logger,
  backends: [:console, Sentry.LoggerBackend]

# Do not send local errors to Sentry
config :sentry,
  dsn: "",
  environment_name: "dev",
  included_environments: []

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:client_ip, :request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Use the HTML encoder for SSML files as well
config :phoenix, :format_encoders,
  html: Phoenix.HTML.Engine,
  ssml: Phoenix.HTML.Engine

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
  config_fetcher: Screens.Config.State.S3Fetch,
  config_s3_bucket: "mbta-ctd-config",
  audio_psa_s3_bucket: "mbta-dotcom",
  audio_psa_s3_directory: "/screens/audio_assets/psa/",
  signs_ui_s3_path: "config.json",
  signs_ui_config_fetcher: Screens.SignsUiConfig.State.S3Fetch,
  default_api_v3_url: "https://api-v3.mbta.com/",
  record_sentry: false

config :screens,
  # Maps alert informed entity contents to the appropriate headsign to show for that alert.
  # List elements must be of the shape {informed_stop_ids, not_informed_stop_ids, headsign}.
  # Each set of stop IDs can be either a single string or a list of strings.
  dup_alert_headsign_matchers: %{
    # Kenmore
    "place-kencl" => [
      {"70149", ~w[70153 70211 70187], "Boston College"},
      {"70211", ~w[70153 70149 70187], "Cleveland Circle"},
      {"70187", ~w[70153 70149 70211], "Riverside"},
      {~w[70149 70211], ~w[70153 70187], "BC/Clev. Circ."},
      {~w[70149 70187], ~w[70153 70211], "BC/Riverside"},
      {~w[70211 70187], ~w[70153 70149], "Clev. Circ./Riverside"},
      {~w[70149 70211 70187], "70153", {:adj, "westbound"}},
      {"70152", ~w[70148 70212 70186], "Park Street"}
    ],
    # Prudential
    "place-prmnl" => [
      {"70154", "70242", "Park Street"},
      {"70241", "70155", "Heath Street"}
    ],
    # Haymarket
    "place-haecl" => [
      # GL
      {"70205", "70201", "Northbound"},
      {"70202", "70206", "Copley & West"},
      # OL
      {"70027", "70023", "Oak Grove"},
      {"70022", "70026", "Forest Hills"}
    ],
    # Back Bay
    "place-bbsta" => [
      {"70017", "70013", "Oak Grove"},
      {"70012", "70016", "Forest Hills"}
    ],
    # Tufts
    "place-tumnl" => [
      {"70019", "70015", "Oak Grove"},
      {"70014", "70018", "Forest Hills"}
    ],
    # Sullivan
    "place-sull" => [
      {"70279", "70029", "Oak Grove"},
      {"70028", "70278", "Forest Hills"}
    ],
    # Malden Center
    "place-mlmnl" => [
      {"70036", "70033", "Oak Grove"},
      {"70032", "70036", "Forest Hills"}
    ],
    # Broadway
    "place-brdwy" => [
      {"70080", "70084", "Alewife"},
      {"70083", "70079", "Ashmont/Braintree"}
    ],
    # Aquarium
    "place-aqucl" => [
      {"70046", "70042", "Wonderland"},
      {"70041", "70045", "Bowdoin"}
    ],
    # Airport
    "place-aport" => [
      {"70050", "70046", "Wonderland"},
      {"70045", "70049", "Bowdoin"}
    ],
    # Quincy Center
    "place-qnctr" => [
      {"70100", "70104", "Alewife"},
      {"70103", "70099", "Braintree"}
    ]
  },
  prefare_alert_headsign_matchers: %{
    # Government Center
    "place-gover" => [
      # GL
      {"70203", "70200", "North Station & North"},
      {~w[70199 70198 70197 70196], "70204", "Copley & West"},
      # BL
      {"70042", "70038", "Wonderland"},
      {"70038", "70041", "Bowdoin"}
    ],
    # Tufts
    "place-tumnl" => [
      {"70019", "70015", "Oak Grove"},
      {"70014", "70018", "Forest Hills"}
    ],
    # Back Bay
    "place-bbsta" => [
      {"70017", "70013", "Oak Grove"},
      {"70012", "70016", "Forest Hills"}
    ],
    # Forest Hills
    "place-forhl" => [
      {"70003", nil, "Oak Grove"}
    ],
    # Maverick
    "place-mvbcl" => [
      {"70048", "70044", "Wonderland"},
      {"70043", "70047", "Bowdoin"}
    ],
    # Ashmont
    "place-asmnl" => [
      {"70092", nil, "Alewife"}
    ],
    # Charles/MGH
    "place-chmnl" => [
      {"70072", "70076", "Alewife"},
      {"70075", "70071", "Ashmont/Braintree"}
    ],
    # Porter
    "place-portr" => [
      {"70064", "70068", "Alewife"},
      {"70067", "70063", "Ashmont/Braintree"}
    ]
  },
  # Stop IDs at stations serviced by two subway lines, where we also have DUP screens.
  two_line_stops: [
    # Haymarket
    "70024",
    "70025",
    "70203",
    "70204",
    "place-haecl"
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
