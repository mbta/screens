# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

if config_env() == :prod do
  # make sure ExAWS.SecretsManager and its dependencies are available
  {:ok, _} = Application.ensure_all_started(:httpoison)
  {:ok, _} = Application.ensure_all_started(:hackney_telemetry)
  {:ok, _} = Application.ensure_all_started(:hackney)
  {:ok, _} = Application.ensure_all_started(:ex_aws)
  {:ok, _} = Application.ensure_all_started(:ex_aws_secretsmanager)

  eb_env_name = System.get_env("ENVIRONMENT_NAME")

  secret_key_base =
    (eb_env_name <> "-secret-key-base")
    |> ExAws.SecretsManager.get_secret_value()
    |> ExAws.request!()
    |> Map.fetch!("SecretString")

  api_v3_key =
    (eb_env_name <> "-api-v3-key")
    |> ExAws.SecretsManager.get_secret_value()
    |> ExAws.request!()
    |> Map.fetch!("SecretString")

  screens_auth_secret =
    (eb_env_name <> "-screens-auth-secret")
    |> ExAws.SecretsManager.get_secret_value()
    |> ExAws.request!()
    |> Map.fetch!("SecretString")

  signs_ui_s3_bucket =
    case eb_env_name do
      "screens-prod" -> "mbta-signs"
      "screens-dev" -> "mbta-signs-dev"
      "screens-dev-green" -> "mbta-signs-dev"
      _ -> nil
    end

  config :screens, ScreensWeb.Endpoint,
    http: [:inet6, port: String.to_integer(System.get_env("PORT") || "4000")],
    secret_key_base: secret_key_base

  sentry_dsn = System.get_env("SENTRY_DSN")

  config :screens,
    api_v3_key: api_v3_key,
    environment_name: eb_env_name,
    signs_ui_s3_bucket: signs_ui_s3_bucket,
    sentry_frontend_dsn: sentry_dsn,
    screenplay_fullstory_org_id: System.get_env("SCREENPLAY_FULLSTORY_ORG_ID")

  if sentry_dsn not in [nil, ""] do
    config :sentry,
      dsn: sentry_dsn,
      environment_name: eb_env_name
  end

  config :screens, ScreensWeb.AuthManager, secret_key: screens_auth_secret

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
