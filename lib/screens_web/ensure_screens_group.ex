defmodule ScreensWeb.EnsureScreensGroup do
  @moduledoc false

  import Plug.Conn

  def init(options), do: options

  def call(conn, _opts) do
    with %{"groups" => groups} <- Guardian.Plug.current_claims(conn),
         true <- is_list(groups),
         screens_group <- Application.get_env(:screens, :cognito_group),
         true <- screens_group in groups do
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
