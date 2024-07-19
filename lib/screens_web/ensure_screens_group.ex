defmodule ScreensWeb.EnsureScreensGroup do
  @moduledoc false

  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    with %{"roles" => roles} <- Guardian.Plug.current_claims(conn),
         true <- is_list(roles),
         screens_role <- Application.get_env(:screens, :keycloak_role),
         true <- screens_role in roles do
      conn
    else
      _ ->
        conn
        |> Phoenix.Controller.redirect(
          to: ScreensWeb.Router.Helpers.unauthorized_path(conn, :index)
        )
        |> halt()
    end
  end
end
