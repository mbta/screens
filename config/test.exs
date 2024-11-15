import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :screens, ScreensWeb.Endpoint,
  http: [port: 4002],
  server: false

config :screens,
  config_fetcher: Screens.Config.Fetch.Local,
  pending_config_fetcher: Screens.PendingConfig.Fetch.Local,
  last_deploy_fetcher: Screens.Util.LastDeploy.LocalFetch,
  local_config_file_spec: {:test, "config.json"},
  local_pending_config_file_spec: {:test, "pending_config.json"},
  local_signs_ui_config_file_spec: {:test, "signs_ui_config.json"},
  signs_ui_config_fetcher: Screens.SignsUiConfig.Fetch.Local,
  # This will help us write testable functions.
  # Functions that request external data cause flaky tests, so to stop us from writing tests that execute API requests,
  # we pass a non-string as the default URL (causing tests to break.)
  #
  # To write testable functions: pass request-firing functions as arguments. Default value can be the "normal" fetch function,
  # and then during tests, we can pass a stubbed version
  api_v3_url: [:no_api_requests_allowed_during_testing],
  blue_bikes_station_information_url: [:no_api_requests_allowed_during_testing],
  blue_bikes_station_status_url: [:no_api_requests_allowed_during_testing],
  blue_bikes_api_client: Screens.BlueBikes.FakeClient,
  dup_headsign_replacements: %{
    "Test 1" => "T1"
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
    # Wellington
    "place-welln" => [
      %{informed: "70278", not_informed: "70034", alert_headsign: "Forest Hills"},
      %{informed: "70035", not_informed: "70279", alert_headsign: "Oak Grove"}
    ],
    # Downtown Crossing
    "place-dwnxg" => [
      # OL
      %{informed: "70018", not_informed: "70022", alert_headsign: "Forest Hills"},
      %{informed: "70023", not_informed: "70019", alert_headsign: "Oak Grove"},
      # RL
      %{informed: "70076", not_informed: "70080", alert_headsign: "Alewife"},
      %{informed: "70079", not_informed: "70075", alert_headsign: "Ashmont & Braintree"}
    ],
    # Malden Center
    "place-mlmnl" => [
      %{informed: "70032", not_informed: "70036", alert_headsign: "Forest Hills"},
      %{informed: "70036", not_informed: "70033", alert_headsign: "Oak Grove"}
    ]
  },
  dup_alert_headsign_matchers: %{
    "place-B" => [
      %{
        informed: "place-A",
        not_informed: "not_informed",
        alert_headsign: "Test A",
        headway_headsign: "Test B"
      },
      %{
        informed: "place-B",
        not_informed: "not_informed",
        alert_headsign: "Test B",
        headway_headsign: "Test A"
      }
    ],
    "place-kencl" => [
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
    "place-overnight" => [
      %{
        informed: "place-overnight",
        not_informed: "not_informed",
        alert_headsign: "Test",
        headway_headsign: "Test"
      }
    ]
  }

config :screens, ScreensWeb.AuthManager, secret_key: "test key"

config :ueberauth, Ueberauth,
  providers: [
    keycloak: {Screens.Ueberauth.Strategy.Fake, [roles: ["screens-admin"]]}
  ]

config :ueberauth_oidcc,
  providers: [
    keycloak: [
      issuer: :keycloak_issuer,
      client_id: "test-client",
      client_secret: "fake-secret"
    ]
  ]

# Print only warnings and errors during test
config :logger, level: :warning

config :screens, :screens_by_alert,
  cache_module: Screens.ScreensByAlert.GenServer,
  screen_data_fn: &Screens.V2.MockScreenData.get/2,
  screens_by_alert_ttl_seconds: 2,
  screens_last_updated_ttl_seconds: 2,
  screens_ttl_seconds: 1

config :screens, Screens.V2.ScreenData,
  config_cache_module: Screens.Config.MockCache,
  parameters_module: Screens.V2.ScreenData.MockParameters

config :screens, Screens.V2.CandidateGenerator.DupNew, stop_module: Screens.Stops.MockStop

config :screens, Screens.V2.CandidateGenerator.Dup.Departures,
  headways_module: Screens.MockHeadways

config :screens, Screens.V2.RDS,
  departure_module: Screens.V2.MockDeparture,
  route_pattern_module: Screens.RoutePatterns.MockRoutePattern,
  stop_module: Screens.Stops.MockStop

config :screens, Screens.V2.CandidateGenerator.Elevator.Closures,
  stop_module: Screens.Stops.MockStop,
  facility_module: Screens.Facilities.MockFacility,
  alert_module: Screens.Alerts.MockAlert,
  route_module: Screens.Routes.MockRoute

config :screens, Screens.LastTrip,
  trip_updates_adapter: Screens.LastTrip.TripUpdates.Noop,
  vehicle_positions_adapter: Screens.LastTrip.VehiclePositions.Noop
