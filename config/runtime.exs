# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

unless config_env() == :test do
  config :screens,
    api_v3_url: System.get_env("API_V3_URL", "https://api-v3.mbta.com/"),
    api_v3_key: System.get_env("API_V3_KEY"),
    trip_updates_url:
      System.get_env(
        "TRIP_UPDATES_URL",
        "https://cdn.mbta.com/realtime/TripUpdates_enhanced.json"
      ),
    vehicle_positions_url:
      System.get_env(
        "VEHICLE_POSITIONS_URL",
        "https://cdn.mbta.com/realtime/VehiclePositions_enhanced.json"
      )
end

if config_env() == :prod do
  eb_env_name = System.get_env("ENVIRONMENT_NAME")

  config :sentry,
    dsn: System.get_env("SENTRY_DSN"),
    environment_name: eb_env_name

  config :screens, ScreensWeb.Endpoint,
    http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000")],
    secret_key_base: System.get_env("SECRET_KEY_BASE")

  config :screens,
    environment_name: eb_env_name,
    signs_ui_s3_bucket: System.fetch_env!("SIGNS_UI_S3_BUCKET"),
    screenplay_fullstory_org_id: System.get_env("SCREENPLAY_FULLSTORY_ORG_ID")

  config :screens, ScreensWeb.AuthManager, secret_key: System.get_env("SCREENS_AUTH_SECRET")

  config :screens, Screens.ScreensByAlert.Memcache,
    connection_opts: [
      namespace: System.get_env("HOST"),
      hostname: System.get_env("MEMCACHED_HOST"),
      coder: Screens.ScreensByAlert.Memcache.SafeErlangCoder
    ]

  keycloak_opts = [
    issuer: :keycloak_issuer,
    client_id: System.fetch_env!("KEYCLOAK_CLIENT_ID"),
    client_secret: System.fetch_env!("KEYCLOAK_CLIENT_SECRET")
  ]

  config :ueberauth_oidcc,
    issuers: [
      %{
        name: :keycloak_issuer,
        issuer: System.fetch_env!("KEYCLOAK_ISSUER")
      }
    ],
    providers: [
      keycloak: keycloak_opts
    ]
end

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :screens, ScreensWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
