defmodule ScreensWeb.Plug.LegacyLogging do
  @moduledoc """
  Logs information on screen page/data requests in a format expected by Splunk reports/alerts.
  These should eventually be migrated to use the Logster request logs, which should have all the
  same data attached, at which point this module can be removed.

  ## Options

  The options value can be `:page`, `:data`, or `:audio`, indicating which type of request to log.
  """

  alias Plug.Conn
  alias ScreensConfig.Screen

  def init(options), do: options

  def call(conn, options), do: Conn.register_before_send(conn, &log(&1, options))

  defp log(%Conn{assigns: %{is_real_screen: true, screen: %Screen{name: name}}} = conn, :page) do
    Logster.info(["[screen page load]", screen_name: inspect(name)])
    conn
  end

  defp log(
         %Conn{assigns: %{is_real_screen: true, screen: %Screen{name: name}}, params: params} =
           conn,
         :data
       ) do
    Logster.info([
      "[screen data request]",
      last_refresh: params["last_refresh"],
      screen_name: inspect(name),
      ofm_app_package_version: params["version"]
    ])

    status = Logger.metadata() |> Keyword.get(:response_type)

    if not is_nil(status) do
      Logster.info([
        "[screen api response #{if(status == :ok, do: :success, else: status)}]",
        last_refresh: params["last_refresh"],
        screen_name: inspect(name)
      ])
    end

    conn
  end

  defp log(%Conn{assigns: %{is_real_screen: true, screen: %Screen{name: name}}} = conn, :audio) do
    Logster.info(["[screen audio request]", screen_name: inspect(name)])
    conn
  end

  defp log(conn, _options), do: conn
end
