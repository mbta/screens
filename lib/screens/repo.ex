defmodule Screens.Repo do
  require Logger

  use Ecto.Repo,
    otp_app: :screens,
    adapter: Ecto.Adapters.Postgres

  def add_prod_credentials(config, auth_token_fn \\ &ExAws.RDS.generate_db_auth_token/4) do
    host = System.fetch_env!("DATABASE_HOST")
    user = System.fetch_env!("DATABASE_USER")
    port = String.to_integer(System.get_env("DATABASE_PORT", "5432"))

    token = auth_token_fn.(host, user, port, %{})

    hash_string = Base.encode16(:crypto.hash(:sha3_256, token))
    Logger.info("#{__MODULE__} add_prod_credentials token_hash=#{hash_string}")

    Keyword.merge(config,
      hostname: host,
      username: user,
      port: port,
      password: token,
      ssl_opts: [
        cacertfile: "priv/aws-cert-bundle.pem",
        verify: :verify_peer,
        server_name_indication: String.to_charlist(host),
        verify_fun:
          {&:ssl_verify_hostname.verify_fun/3, [check_hostname: String.to_charlist(host)]}
      ]
    )
  end
end
