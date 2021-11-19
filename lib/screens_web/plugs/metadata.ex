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

    Logger.metadata(client_ip: forwarded_for || conn.remote_ip)
  end
end
