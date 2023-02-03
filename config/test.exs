import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :screens, ScreensWeb.Endpoint,
  http: [port: 4002],
  server: false

config :screens,
  config_fetcher: Screens.Config.State.LocalFetch,
  last_deploy_fetcher: Screens.Util.LastDeploy.LocalFetch,
  local_config_file_spec: {:test, "config.json"},
  signs_ui_config_fetcher: Screens.SignsUiConfig.State.LocalFetch,
  # This will help us write testable functions.
  # Functions that request external data cause flaky tests, so to stop us from writing tests that execute API requests,
  # we pass a non-string as the default URL (causing tests to break.)
  #
  # To write testable functions: pass request-firing functions as arguments. Default value can be the "normal" fetch function,
  # and then during tests, we can pass a stubbed version
  default_api_v3_url: [:no_api_requests_allowed_during_testing],
  blue_bikes_station_information_url: [:no_api_requests_allowed_during_testing],
  blue_bikes_station_status_url: [:no_api_requests_allowed_during_testing],
  blue_bikes_api_client: Screens.BlueBikes.FakeClient,
  dup_headsign_replacements: %{
    "Test 1" => "T1"
  }

config :screens, ScreensWeb.AuthManager, secret_key: "test key"

config :ueberauth, Ueberauth,
  providers: [
    cognito: {Screens.Ueberauth.Strategy.Fake, []}
  ]

# Print only warnings and errors during test
config :logger, level: :warn

config :screens, :screens_by_alert,
  cache_module: Screens.ScreensByAlert.GenServer,
  screen_data_fn: &Screens.V2.MockScreenData.by_screen_id/2,
  screens_by_alert_ttl_seconds: 2,
  screens_last_updated_ttl_seconds: 2,
  screens_ttl_seconds: 1
