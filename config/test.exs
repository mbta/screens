use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :screens, ScreensWeb.Endpoint,
  http: [port: 4002],
  server: false

config :screens,
  config_fetcher: Screens.Config.State.LocalFetch

config :screens, ScreensWeb.AuthManager, secret_key: "test key"

config :ueberauth, Ueberauth,
  providers: [
    cognito: {Screens.Ueberauth.Strategy.Fake, []}
  ]

# Print only warnings and errors during test
config :logger, level: :warn
