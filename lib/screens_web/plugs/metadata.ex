defmodule ScreensWeb.Plugs.Metadata do
  @moduledoc false

  require Logger

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> copy_remote_ip_to_client_ip()
  end

  defp copy_remote_ip_to_client_ip(conn) do
    client_ip = Logger.metadata()[:remote_ip]

    Logger.metadata(client_ip: client_ip)

    conn
  end
end
