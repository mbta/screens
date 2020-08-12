defmodule ScreensWeb.AuthController do
  use ScreensWeb, :controller
  require Logger
  plug Ueberauth

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    username = auth.uid
    expiration = auth.credentials.expires_at
    credentials = conn.assigns.ueberauth_auth.credentials

    current_time = System.system_time(:second)

    conn
    |> Guardian.Plug.sign_in(
      ScreensWeb.AuthManager,
      username,
      %{groups: credentials.other[:groups]},
      ttl: {expiration - current_time, :seconds}
    )
    |> redirect(to: ScreensWeb.Router.Helpers.admin_path(conn, :index))
  end

  def callback(
        %{assigns: %{ueberauth_failure: %Ueberauth.Failure{}}} = conn,
        _params
      ) do
    %{assigns: %{ueberauth_failure: %Ueberauth.Failure{errors: errors}}} = conn

    error_messages =
      Enum.map(errors, fn %Ueberauth.Failure.Error{message: message} -> message end)

    _ = Logger.info("Ueberauth Failure with error messages: #{error_messages}")
    send_resp(conn, 401, "unauthenticated")
  end
end
