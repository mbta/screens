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

  def call(conn, options) do
    conn |> log(options) |> Conn.register_before_send(&log_before_send(&1, options))
  end

  defp log(
         %Conn{assigns: %{is_real_screen: true, screen: %Screen{name: name}}} = conn,
         :page
       ) do
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
      screen_name: inspect(name)
    ])

    conn
  end

  defp log(
         %Conn{assigns: %{is_real_screen: true, screen: %Screen{name: name}}} = conn,
         :audio
       ) do
    Logster.info(["[screen audio request]", screen_name: inspect(name)])
    conn
  end

  defp log(conn, _options), do: conn

  defp log_before_send(
         %Conn{assigns: %{is_real_screen: true, screen: %Screen{name: name}}, params: params} =
           conn,
         :data
       ) do
    response_type = Logger.metadata() |> Keyword.get(:response_type)

    Logster.info([
      "[screen api response #{if(is_nil(response_type), do: :success, else: response_type)}]",
      last_refresh: params["last_refresh"],
      screen_name: inspect(name)
    ])

    conn
  end

  defp log_before_send(conn, _options), do: conn
end
