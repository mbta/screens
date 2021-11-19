defmodule ScreensWeb.Plugs.Metadata do
  @moduledoc false

  require Logger

  def init(default), do: default

  def call(conn, _default) do
    log_client_ip(conn)

    conn
  end

  defp log_client_ip(conn) do
    forwarded_for =
      conn
      |> Plug.Conn.get_req_header("x-forwarded-for")
      |> List.first()
    remote_ip = 
      conn.remote_ip
      |> :inet_parse.ntoa()
      |> to_string()

    Logger.metadata(client_ip: forwarded_for || remote_ip)
  end
end
