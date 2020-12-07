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
  config_fetcher: Screens.Config.State.S3Fetch,
  config_s3_bucket: "mbta-ctd-config",
  audio_psa_s3_bucket: "mbta-dotcom",
  audio_psa_s3_directory: "/screens/audio_assets/psa/",
  signs_ui_s3_path: "config.json",
  signs_ui_config_fetcher: Screens.SignsUiConfig.State.S3Fetch,
  api_v3_url: "https://api-v3.mbta.com/"

config :screens,
  # "Constant" (rarely changing) system properties used by the DUP app to save on API requests.
  # Map keys are IDs of stops where we have DUP screens.
  dup_constants: %{
    ### GL
    # Kenmore
    "70150" => %{
      adjacent_stops: {MapSet.new(~w[70148 70186 70212]), "70152"},
      headsign: "Park Street"
    },
    "71150" => %{
      adjacent_stops: {MapSet.new(~w[70148 70186 70212]), "70152"},
      headsign: "Park Street"
    },
    "70151" => %{
      adjacent_stops: {"70153", MapSet.new(~w[70149 70187 70211])},
      headsign: "Cleveland Circle/Riverside"
    },
    "71151" => %{
      adjacent_stops: {"70153", MapSet.new(~w[70149 70187 70211])},
      headsign: "Cleveland Circle/Riverside"
    },
    # Prudential
    "70240" => %{
      adjacent_tops: {"70242", "70154"},
      headsign: "Park Street"
    },
    "70239" => %{
      adjacent_stops: {"70155", "70241"},
      headsign: "Heath Street"
    },
    # Haymarket
    "70203" => %{
      adjacent_stops: {"70201", "70205"},
      headsign: "North Station & North"
    },
    "70204" => %{
      adjacent_stops: {"70206", "70202"},
      headsign: "Copley & West"
    },
    ### OL
    # Back Bay
    "70015" => %{
      adjacent_stops: {"70013", "70017"},
      headsign: "Oak Grove"
    },
    "70014" => %{
      adjacent_stops: {"70016", "70012"},
      headsign: "Forest Hills"
    },
    # Tufts
    "70017" => %{
      adjacent_stops: {"70015", "70019"},
      headsign: "Oak Grove"
    },
    "70016" => %{
      adjacent_stops: {"70018", "70014"},
      headsign: "Forest Hills"
    },
    # Haymarket
    "70025" => %{
      adjacent_stops: {"70023", "70027"},
      headsign: "Oak Grove"
    },
    "70024" => %{
      adjacent_stops: {"70026", "70022"},
      headsign: "Forest Hills"
    },
    # Sullivan
    "70031" => %{
      adjacent_stops: {"70029", "70279"},
      headsign: "Oak Grove"
    },
    "70030" => %{
      adjacent_stops: {"70278", "70028"},
      headsign: "Forest Hills"
    },
    # Malden Center
    "70035" => %{
      adjacent_stops: {"70033", "70036"},
      headsign: "Oak Grove"
    },
    "70034" => %{
      adjacent_stops: {"70036", "70032"},
      headsign: "Forest Hills"
    },
    ### RL
    # Broadway
    "70082" => %{
      adjacent_stops: {"70084", "70080"},
      headsign: "Alewife"
    },
    "70081" => %{
      adjacent_stops: {"70079", "70083"},
      headsign: "Ashmont/Braintree"
    },
    ### BL
    # Aquarium
    "70044" => %{
      adjacent_stops: {"70042", "70046"},
      headsign: "Wonderland"
    },
    "70043" => %{
      adjacent_stops: {"70045", "70041"},
      headsign: "Bowdoin"
    },
    # Airport
    "70048" => %{
      adjacent_stops: {"70046", "70050"},
      headsign: "Wonderland"
    },
    "70047" => %{
      adjacent_stops: {"70049", "70045"},
      headsign: "Bowdoin"
    }
  },
  # Stop IDs at stations serviced by two subway lines, where we also have DUP screens.
  two_line_stops: [
    # Haymarket
    "70024", "70025", "70203", "70204"
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
