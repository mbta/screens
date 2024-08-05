# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

eb_env_name = System.get_env("ENVIRONMENT_NAME")

api_v3_url =
  case eb_env_name do
    "screens-prod" -> "https://api-v3.mbta.com/"
    "screens-dev" -> "https://api-dev.mbtace.com/"
    "screens-dev-green" -> "https://api-dev-green.mbtace.com/"
    _ -> System.get_env("API_V3_URL", "https://api-v3.mbta.com/")
  end

unless config_env() == :test do
  config :screens,
    api_v3_url: api_v3_url,
    api_v3_key: System.get_env("API_V3_KEY")
end

if config_env() == :prod do
  signs_ui_s3_bucket =
    case eb_env_name do
      "screens-prod" -> "mbta-signs"
      "screens-dev" -> "mbta-signs-dev"
      "screens-dev-green" -> "mbta-signs-dev"
      _ -> nil
    end

  config :screens, ScreensWeb.Endpoint,
    http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000")],
    secret_key_base: System.get_env("SECRET_KEY_BASE")

  sentry_dsn = System.get_env("SENTRY_DSN")

  config :screens,
    environment_name: eb_env_name,
    signs_ui_s3_bucket: signs_ui_s3_bucket,
    sentry_frontend_dsn: sentry_dsn,
    screenplay_fullstory_org_id: System.get_env("SCREENPLAY_FULLSTORY_ORG_ID")

  if sentry_dsn not in [nil, ""] do
    config :sentry,
      dsn: sentry_dsn,
      environment_name: eb_env_name
  end

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
