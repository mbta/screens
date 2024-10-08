defmodule ScreensWeb.AuthController do
  require Logger

  use ScreensWeb, :controller
  plug Ueberauth

  # Respond with 404 instead of crashing when the path doesn't match a supported provider
  def request(conn, %{"provider" => provider}) when provider != "keycloak" do
    send_resp(conn, 404, "Not Found")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    username = auth.uid
    expiration = auth.credentials.expires_at
    current_time = System.system_time(:second)

    keycloak_client_id =
      get_in(Application.get_env(:ueberauth_oidcc, :providers), [:keycloak, :client_id])

    roles =
      get_in(auth.extra.raw_info.userinfo, ["resource_access", keycloak_client_id, "roles"]) || []

    redirect_to = Plug.Conn.get_session(conn, :previous_path, ~p"/admin")

    conn
    |> Plug.Conn.delete_session(:previous_path)
    |> Guardian.Plug.sign_in(
      ScreensWeb.AuthManager,
      username,
      %{roles: roles},
      ttl: {expiration - current_time, :seconds}
    )
    |> redirect(to: redirect_to)
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

    Logger.info("[ueberauth_failure] messages=\"#{error_messages}\"")

    send_resp(conn, 401, "unauthenticated")
  end
end
