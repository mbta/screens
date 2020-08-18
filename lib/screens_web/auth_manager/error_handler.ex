defmodule ScreensWeb.AuthManager.ErrorHandler do
  @moduledoc false

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {_type, _reason}, _opts) do
    Phoenix.Controller.redirect(
      conn,
      to: ScreensWeb.Router.Helpers.auth_path(conn, :request, "cognito")
    )
  end
end
