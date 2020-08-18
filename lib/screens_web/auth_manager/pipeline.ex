defmodule ScreensWeb.AuthManager.Pipeline do
  @moduledoc false

  use Guardian.Plug.Pipeline,
    otp_app: :screens,
    error_handler: ScreensWeb.AuthManager.ErrorHandler,
    module: ScreensWeb.AuthManager

  plug(Guardian.Plug.VerifySession, claims: %{"typ" => "access"})
  plug(Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"})
  plug(Guardian.Plug.LoadResource, allow_blank: true)
end
