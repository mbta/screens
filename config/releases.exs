# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

# make sure ExAWS.SecretsManager and its dependencies are available
Application.ensure_all_started(:poison)
Application.ensure_all_started(:hackney)
Application.ensure_all_started(:ex_aws)
Application.ensure_all_started(:ex_aws_secretsmanager)

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

cognito_client_secret =
  (eb_env_name <> "-cognito-client-secret")
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

config :screens,
  api_v3_key: api_v3_key,
  environment_name: eb_env_name,
  signs_ui_s3_bucket: signs_ui_s3_bucket,
  sentry_frontend_dsn: System.get_env("SENTRY_DSN")

config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  environment_name: eb_env_name,
  included_environments: [eb_env_name],
  enable_source_code_context: true,
  root_source_code_path: File.cwd!()

config :ueberauth, Ueberauth.Strategy.Cognito, client_secret: cognito_client_secret
config :screens, ScreensWeb.AuthManager, secret_key: screens_auth_secret

config :screens, Screens.ScreensByAlert.Memcache,
  connection_opts: [
    namespace: System.get_env("HOST"),
    hostname: System.get_env("MEMCACHED_HOST"),
    coder: {Memcache.Coder.Erlang, [:safe]}
  ]

# ## Using releases (Elixir v1.9+)
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start each relevant endpoint:
#
#     config :screens, ScreensWeb.Endpoint, server: true
#
# Then you can assemble a release by calling `mix release`.
# See `mix help release` for more information.
