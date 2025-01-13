defmodule ScreensWeb.AuthManager.ErrorHandler do
  @moduledoc false

  @behaviour Guardian.Plug.ErrorHandler

  alias Phoenix.Controller
  alias ScreensWeb.Router.Helpers, as: Routes

  @impl true
  def auth_error(conn, error, _opts) do
    case Controller.get_format(conn) do
      "html" ->
        Controller.redirect(conn,
          to: Routes.auth_path(conn, :request, "keycloak", auth_params(error))
        )

      "json" ->
        Plug.Conn.send_resp(conn, 401, "unauthenticated")
    end
  end

  defp auth_params({:invalid_token, {:auth_expired, sub}}), do: [prompt: "login", login_hint: sub]
  defp auth_params({:unauthenticated, _}), do: []
  defp auth_params(_error), do: [prompt: "login"]
end
