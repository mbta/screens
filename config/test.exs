import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :screens, ScreensWeb.Endpoint,
  http: [port: 4002],
  server: false

config :screens,
  config_fetcher: Screens.Config.State.LocalFetch,
  local_config_file_spec: {:test, "config.json"},
  signs_ui_config_fetcher: Screens.SignsUiConfig.State.LocalFetch,
  default_api_v3_url: [:no_api_requests_allowed_during_testing]

config :screens, ScreensWeb.AuthManager, secret_key: "test key"

config :ueberauth, Ueberauth,
  providers: [
    cognito: {Screens.Ueberauth.Strategy.Fake, []}
  ]

# Print only warnings and errors during test
config :logger, level: :warn

config :screens,
  # See config.exs for details
  prefare_alert_headsign_matchers: %{
    # Downtown Crossing
    "place-dwnxg" => [
      # RL
      {"70076", "70080", "Alewife"},
      {"70079", "70075", "Ashmont/Braintree"}
    ]
  }
