defmodule ScreensWeb.AuthController do
  require Logger

  use ScreensWeb, :controller
  plug Ueberauth

  def request(conn, %{"provider" => provider}) when provider != "cognito" do
    send_resp(conn, 404, "Not Found")
  end

  def callback(conn, %{"provider" => provider}) when provider != "cognito" do
    send_resp(conn, 404, "Not Found")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    username = auth.uid
    expiration = auth.credentials.expires_at
    credentials = auth.credentials

    current_time = System.system_time(:second)

    conn
    |> Guardian.Plug.sign_in(
      ScreensWeb.AuthManager,
      username,
      %{groups: credentials.other.groups},
      ttl: {expiration - current_time, :seconds}
    )
    |> redirect(to: ScreensWeb.Router.Helpers.admin_path(conn, :index))
  end

  def callback(
        %{assigns: %{ueberauth_failure: %Ueberauth.Failure{errors: errors}}} = conn,
        _params
      ) do
    error_messages =
      errors
      |> Enum.flat_map(fn
        %Ueberauth.Failure.Error{message: message} when is_binary(message) -> [message]
        _ -> []
      end)
      |> Enum.join(", ")

    _ = Logger.info("[ueberauth_failure] messages=\"#{error_messages}\"")

    send_resp(conn, 401, "unauthenticated")
  end
end
