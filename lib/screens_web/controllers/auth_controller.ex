defmodule ScreensWeb.AuthController do
  use ScreensWeb, :controller
  plug Ueberauth

  alias Screens.Log

  # Respond with 404 instead of crashing when the path doesn't match a supported provider
  def request(conn, %{"provider" => provider}) when provider != "keycloak" do
    send_resp(conn, 404, "Not Found")
  end

  def callback(%{assigns: %{ueberauth_auth: %{provider: :keycloak} = auth}} = conn, _params) do
    username = auth.uid

    auth_time =
      Map.get(
        auth.extra.raw_info.claims,
        "auth_time",
        auth.extra.raw_info.claims["iat"]
      )

    keycloak_client_id =
      get_in(Application.get_env(:ueberauth_oidcc, :providers), [:keycloak, :client_id])

    roles =
      get_in(auth.extra.raw_info.userinfo, ["resource_access", keycloak_client_id, "roles"]) || []

    redirect_to = Plug.Conn.get_session(conn, :previous_path, ~p"/admin")

    conn
    |> configure_session(drop: true)
    |> Guardian.Plug.sign_in(
      ScreensWeb.AuthManager,
      username,
      %{auth_time: auth_time, roles: roles},
      ttl: {30, :minutes}
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

    Log.warning("ueberauth_failure", messages: error_messages)

    send_resp(conn, 401, "unauthenticated")
  end
end
