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
  pubsub_server: ScreensWeb.PubSub,
  live_view: [signing_salt: "cK5v02Jnzmp4C8NjV0wwpD2IdTaZdMvi"]

# Include 2 logger backends
config :logger,
  backends: [:console, Sentry.LoggerBackend]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:client_ip, :remote_ip, :request_id]

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
  keycloak_role: "screens-admin"

config :screens, ScreensWeb.AuthManager, issuer: "screens"

# Placeholder for Keycloak authentication, defined for real in environment configs
config :ueberauth, Ueberauth,
  providers: [
    keycloak: nil
  ]

config :screens,
  gds_dms_username: "mbtadata@gmail.com",
  config_fetcher: Screens.Config.Fetch.S3,
  pending_config_fetcher: Screens.PendingConfig.Fetch.S3,
  config_s3_bucket: "mbta-ctd-config",
  audio_psa_s3_bucket: "mbta-dotcom",
  audio_psa_s3_directory: "/screens/audio_assets/psa/",
  signs_ui_s3_path: "config.json",
  signs_ui_config_fetcher: Screens.SignsUiConfig.Fetch.S3,
  triptych_player_s3_bucket: "mbta-ctd-config",
  triptych_player_fetcher: Screens.TriptychPlayer.Fetch.S3,
  last_deploy_fetcher: Screens.Util.LastDeploy.S3Fetch,
  default_api_v3_url: "https://api-v3.mbta.com/",
  blue_bikes_api_client: Screens.BlueBikes.Client,
  blue_bikes_station_information_url:
    "https://gbfs.bluebikes.com/gbfs/en/station_information.json",
  blue_bikes_station_status_url: "https://gbfs.bluebikes.com/gbfs/en/station_status.json",
  record_sentry: false

config :screens,
  # Maps alert informed entity contents to the appropriate headsign to show for that alert.
  # List elements must be of the shape
  # %{informed: informed_stop_ids, not_informed: not_informed_stop_ids, alert_headsign: alert_headsign, headway_headsign: optional(headway_headsign)}.
  # Each set of stop IDs can be either a single string or a list of strings.
  dup_alert_headsign_matchers: %{
    # Kenmore
    "place-kencl" => [
      %{informed: "70149", not_informed: ~w[70153 70211 70187], alert_headsign: "Boston College"},
      %{
        informed: "70211",
        not_informed: ~w[70153 70149 70187],
        alert_headsign: "Cleveland Circle"
      },
      %{informed: "70187", not_informed: ~w[70153 70149 70211], alert_headsign: "Riverside"},
      %{
        informed: ~w[70149 70211],
        not_informed: ~w[70153 70187],
        alert_headsign: "BC/Clev. Circ."
      },
      %{informed: ~w[70149 70187], not_informed: ~w[70153 70211], alert_headsign: "BC/Riverside"},
      %{
        informed: ~w[70211 70187],
        not_informed: ~w[70153 70149],
        alert_headsign: "Clev. Circ./Riverside"
      },
      %{
        informed: ~w[70149 70211 70187],
        not_informed: "70153",
        alert_headsign: {:adj, "westbound"},
        headway_headsign: "Park Street"
      },
      %{
        informed: "70152",
        not_informed: ~w[70148 70212 70186],
        alert_headsign: "Park Street",
        headway_headsign: "Westbound"
      }
    ],
    # Prudential
    "place-prmnl" => [
      %{
        informed: "70154",
        not_informed: "70242",
        alert_headsign: "Park Street",
        headway_headsign: "Heath Street"
      },
      %{
        informed: "70241",
        not_informed: "70155",
        alert_headsign: "Heath Street",
        headway_headsign: "Park Street"
      }
    ],
    # Haymarket
    "place-haecl" => [
      # GL
      %{
        informed: "70205",
        not_informed: "70201",
        alert_headsign: "North Station & North",
        headway_headsign: "Copley & West"
      },
      %{
        informed: "70202",
        not_informed: "70206",
        alert_headsign: "Copley & West",
        headway_headsign: "North Station & North"
      },
      # OL
      %{
        informed: "70027",
        not_informed: "70023",
        alert_headsign: "Oak Grove",
        headway_headsign: "Forest Hills"
      },
      %{
        informed: "70022",
        not_informed: "70026",
        alert_headsign: "Forest Hills",
        headway_headsign: "Oak Grove"
      }
    ],
    # Back Bay
    "place-bbsta" => [
      %{
        informed: "70017",
        not_informed: "70013",
        alert_headsign: "Oak Grove",
        headway_headsign: "Forest Hills"
      },
      %{
        informed: "70012",
        not_informed: "70016",
        alert_headsign: "Forest Hills",
        headway_headsign: "Oak Grove"
      }
    ],
    # Tufts
    "place-tumnl" => [
      %{
        informed: "70019",
        not_informed: "70015",
        alert_headsign: "Oak Grove",
        headway_headsign: "Forest Hills"
      },
      %{
        informed: "70014",
        not_informed: "70018",
        alert_headsign: "Forest Hills",
        headway_headsign: "Oak Grove"
      }
    ],
    # Sullivan
    "place-sull" => [
      %{
        informed: "70279",
        not_informed: "70029",
        alert_headsign: "Oak Grove",
        headway_headsign: "Forest Hills"
      },
      %{
        informed: "70028",
        not_informed: "70278",
        alert_headsign: "Forest Hills",
        headway_headsign: "Oak Grove"
      }
    ],
    # Malden Center
    "place-mlmnl" => [
      %{
        informed: "70036",
        not_informed: "70033",
        alert_headsign: "Oak Grove",
        headway_headsign: "Forest Hills"
      },
      %{
        informed: "70032",
        not_informed: "70036",
        alert_headsign: "Forest Hills",
        headway_headsign: "Oak Grove"
      }
    ],
    # Broadway
    "place-brdwy" => [
      %{
        informed: "70080",
        not_informed: "70084",
        alert_headsign: "Alewife",
        headway_headsign: "Ashmont/Braintree"
      },
      %{
        informed: "70083",
        not_informed: "70079",
        alert_headsign: "Ashmont/Braintree",
        headway_headsign: "Alewife"
      }
    ],
    # Aquarium
    "place-aqucl" => [
      %{
        informed: "70046",
        not_informed: "70042",
        alert_headsign: "Wonderland",
        headway_headsign: "Bowdoin"
      },
      %{
        informed: "70041",
        not_informed: "70045",
        alert_headsign: "Bowdoin",
        headway_headsign: "Wonderland"
      }
    ],
    # Airport
    "place-aport" => [
      %{
        informed: "70050",
        not_informed: "70046",
        alert_headsign: "Wonderland",
        headway_headsign: "Bowdoin"
      },
      %{
        informed: "70045",
        not_informed: "70049",
        alert_headsign: "Bowdoin",
        headway_headsign: "Wonderland"
      }
    ],
    # Quincy Center
    "place-qnctr" => [
      %{
        informed: "70100",
        not_informed: "70104",
        alert_headsign: "Alewife",
        headway_headsign: "Braintree"
      },
      %{
        informed: "70103",
        not_informed: "70099",
        alert_headsign: "Braintree",
        headway_headsign: "Alewife"
      }
    ],
    # Maverick
    "place-mvbcl" => [
      %{
        informed: "70048",
        not_informed: "70044",
        alert_headsign: "Wonderland",
        headway_headsign: "Bowdoin"
      },
      %{
        informed: "70043",
        not_informed: "70047",
        alert_headsign: "Bowdoin",
        headway_headsign: "Wonderland"
      }
    ],
    # South Station
    "place-sstat" => [
      %{
        informed: "70078",
        not_informed: "70082",
        alert_headsign: "Alewife",
        headway_headsign: "Ashmont/Braintree"
      },
      %{
        informed: "70081",
        not_informed: "70077",
        alert_headsign: "Ashmont/Braintree",
        headway_headsign: "Alewife"
      }
    ],
    # Kendall
    "place-knncl" => [
      %{
        informed: "70070",
        not_informed: "70074",
        alert_headsign: "Alewife",
        headway_headsign: "Ashmont/Braintree"
      },
      %{
        informed: "70073",
        not_informed: "70069",
        alert_headsign: "Ashmont/Braintree",
        headway_headsign: "Alewife"
      }
    ],
    # Park Street
    "place-pktrm" => [
      # Green Line
      # Government Center -> Park Street -> Boylston
      %{
        # Government Center
        not_informed: "70202",
        # Boylston
        informed: "70159",
        alert_headsign: "Copley & West",
        headway_headsign: "Northbound"
      },
      # Boylston -> Park Street -> Government Center
      %{
        # Boylston
        not_informed: "70158",
        # Government Center
        informed: "70201",
        alert_headsign: "Northbound",
        headway_headsign: "Copley & West"
      },
      # Red Line
      # Charles/MGH -> Park Street -> Downtown Crossing (Southbound)
      %{
        # Charles/MGH
        not_informed: "70073",
        # Downtown Crossing
        informed: "70077",
        alert_headsign: "Ashmont/Braintree",
        headway_headsign: "Alewife"
      },
      # Downtown Crossing -> Park Street -> Charles/MGH (Northbound)
      %{
        # Downtown Crossing
        not_informed: "70078",
        # Charles/MGH
        informed: "70074",
        alert_headsign: "Alewife",
        headway_headsign: "Ashmont/Braintree"
      }
    ],
    # Arlington
    "place-armnl" => [
      # Boylston -> Arlington -> Copley
      %{
        # Boylston
        not_informed: "70159",
        # Copley
        informed: "70155",
        alert_headsign: "Copley & West",
        headway_headsign: "Northbound"
      },
      # Copley -> Arlington -> Boylston
      %{
        # Copley
        not_informed: "70154",
        # Boylston
        informed: "70158",
        alert_headsign: "Northbound",
        headway_headsign: "Copley & West"
      }
    ]
  },
  prefare_alert_headsign_matchers: %{
    # Government Center
    "place-gover" => [
      # GL
      %{informed: "70203", not_informed: "70200", alert_headsign: "North Station & North"},
      %{
        informed: ~w[70199 70198 70197 70196],
        not_informed: "70204",
        alert_headsign: "Copley & West"
      },
      # BL
      %{informed: "70042", not_informed: "70038", alert_headsign: "Wonderland"},
      %{informed: "70038", not_informed: "70041", alert_headsign: "Bowdoin"}
    ],
    # Tufts
    "place-tumnl" => [
      %{informed: "70019", not_informed: "70015", alert_headsign: "Oak Grove"},
      %{informed: "70014", not_informed: "70018", alert_headsign: "Forest Hills"}
    ],
    # Back Bay
    "place-bbsta" => [
      %{informed: "70017", not_informed: "70013", alert_headsign: "Oak Grove"},
      %{informed: "70012", not_informed: "70016", alert_headsign: "Forest Hills"}
    ],
    # Forest Hills
    "place-forhl" => [
      %{informed: "70003", not_informed: nil, alert_headsign: "Oak Grove"}
    ],
    # Maverick
    "place-mvbcl" => [
      %{informed: "70048", not_informed: "70044", alert_headsign: "Wonderland"},
      %{informed: "70043", not_informed: "70047", alert_headsign: "Bowdoin"}
    ],
    # Ashmont
    "place-asmnl" => [
      %{informed: "70092", not_informed: nil, alert_headsign: "Alewife"}
    ],
    # Charles/MGH
    "place-chmnl" => [
      %{informed: "70072", not_informed: "70076", alert_headsign: "Alewife"},
      %{informed: "70075", not_informed: "70071", alert_headsign: "Ashmont & Braintree"}
    ],
    # Porter
    "place-portr" => [
      %{informed: "70064", not_informed: "70068", alert_headsign: "Alewife"},
      %{informed: "70067", not_informed: "70063", alert_headsign: "Ashmont & Braintree"}
    ],
    "place-welln" => [
      %{informed: "70278", not_informed: "70034", alert_headsign: "Forest Hills"},
      %{informed: "70035", not_informed: "70279", alert_headsign: "Oak Grove"}
    ]
  },
  dup_headsign_replacements: %{
    "Charlestown Navy Yard" => "Charlestown",
    "Saugus Center via Kennedy Dr & Square One Mall" => "Saugus Center via Kndy Dr & Square One",
    "Malden via Square One Mall & Kennedy Dr" => "Malden via Square One Mall & Kndy Dr",
    "Washington St & Pleasant St Weymouth" => "Washington St & Plsnt St Weymouth",
    "Woodland Rd via Gateway Center" => "Woodland Rd via Gatew'y Center",
    "Sullivan (Limited Stops)" => "Sullivan",
    "Ruggles (Limited Stops)" => "Ruggles",
    "Wickford Junction" => "Wickford Jct",
    "Needham Heights" => "Needham Hts",
    "Houghs Neck via McGrath & Germantown" => "Houghs Neck via McGth & Gtwn",
    "Houghs Neck via Germantown" => "Houghs Neck via Germntwn",
    "Middleborough/Lakeville" => "Middleborough / Lakeville",

    # The following are special headsigns for the 2022 Orange Line surge
    "Needham Heights via Ruggles" => "Needham Hts via Ruggles",
    "Needham Heights via Forest Hills" => "Needham Hts via Forest Hills",
    "Wickford Junction via Ruggles" => "Wickford Jct via Ruggles",
    "Wickford Junction via Forest Hills" => "Wickford Jct via Forest Hills",
    "Providence & Needham via Forest Hills" => "Providence via Forest Hills",
    "Norwood Central via Ruggles" => "Norwood Cntrl via Ruggles"
  },
  dup_headway_branch_stations: ["place-kencl", "place-jfk", "place-coecl"],
  dup_headway_branch_terminals: [
    "Boston College",
    "Cleveland Circle",
    "Riverside",
    "Heath Street",
    "Ashmont",
    "Braintree"
  ]

config :screens, :screens_by_alert,
  cache_module: Screens.ScreensByAlert.GenServer,
  screen_data_fn: &Screens.V2.ScreenData.by_screen_id/2,
  screens_by_alert_ttl_seconds: 40,
  screens_last_updated_ttl_seconds: 3600,
  screens_ttl_seconds: 40

config :screens, Screens.ScreenApiResponseCache,
  gc_interval: :timer.hours(1),
  allocated_memory: 250_000_000

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
