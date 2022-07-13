defmodule ScreensWeb.DebugController do
  use ScreensWeb, :controller
  require Logger

  def log_sentry_init_failure(conn, %{"app_id" => app_id, "message" => message}) do
    Logger.warn("[sentry_init_failure] app_id=#{app_id} message=\"#{message}\"")

    text(conn, "")
  end
end
