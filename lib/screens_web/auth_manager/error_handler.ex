defmodule ScreensWeb.AuthManager.ErrorHandler do
  @moduledoc false

  @behaviour Guardian.Plug.ErrorHandler

  require Logger

  @impl true
  def auth_error(conn, error, _opts) do
    Logger.info("auth_debug error_handler #{inspect(error)}")
    Phoenix.Controller.redirect(conn,
      to: ScreensWeb.Router.Helpers.auth_path(conn, :request, "keycloak", auth_params(error))
    )
  end

  defp auth_params({:invalid_token, {:auth_expired, sub}}), do: [prompt: "login", login_hint: sub]
  defp auth_params({:unauthenticated, _}), do: []
  defp auth_params(_error), do: [prompt: "login"]
end
