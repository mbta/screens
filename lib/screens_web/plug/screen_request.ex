defmodule ScreensWeb.Plug.ScreenRequest do
  @moduledoc """
  Gets configuration for the screen specified by an `id` path param, assigns values for handling
  a screen page or data request, and sets logger metadata.

  ## Options

  When the options value is `:pending`, the screen data is fetched from pending configuration.
  Otherwise the "live" configuration is used.
  """

  alias Phoenix.Controller
  alias Plug.Conn
  alias Screens.Config.Cache
  alias ScreensConfig.Screen

  def init(options), do: options

  def call(conn, :pending) do
    with {:params, %Conn{path_params: %{"id" => id}}} <- {:params, conn},
         {:ok, fetched} = Screens.PendingConfig.Fetch.fetch_config(),
         {:ok, decoded} = Jason.decode!(fetched),
         pending_config = ScreensConfig.PendingConfig.from_json(decoded),
         {:screen, {:ok, screen}} <- {:screen, Map.fetch(pending_config, id)} do
      handle_request(conn, id, screen)
    else
      {:params, _conn} -> error(conn, 400)
      {:screen, :error} -> error(conn, 404)
    end
  end

  def call(conn, _opts) do
    with {:params, %Conn{path_params: %{"id" => id}}} <- {:params, conn},
         {:cache, true} <- {:cache, Cache.ok?()},
         {:screen, %Screen{} = screen} <- {:screen, Cache.screen(id)} do
      handle_request(conn, id, screen)
    else
      {:params, _conn} -> error(conn, 400)
      {:cache, false} -> error(conn, 503)
      {:screen, nil} -> error(conn, 404)
    end
  end

  defp handle_request(conn, screen_id, screen) do
    conn |> Conn.fetch_query_params() |> assign(screen_id, screen)
  end

  defp assign(%Conn{params: params} = conn, screen_id, screen) do
    %Screen{app_id: app_id, app_params: app_params, vendor: vendor} = screen

    logged_assigns =
      params
      |> Map.take(~w[requestor rotation_index variant])
      |> Keyword.new()
      |> Keyword.merge(
        is_real_screen: match?(%{"is_real_screen" => "true"}, params),
        screen_id: screen_id,
        screen_side: screen_side(app_params, params)
      )

    Logger.metadata([app_id: app_id, vendor: vendor] ++ logged_assigns)

    Conn.merge_assigns(conn, [screen: screen] ++ logged_assigns)
  end

  defp error(conn, status) do
    conn
    |> Conn.put_status(status)
    |> Controller.put_layout(html: {ScreensWeb.LayoutView, :error})
    |> Controller.put_view(ScreensWeb.ErrorView)
    |> Controller.render("#{status}.html")
    |> Conn.halt()
  end

  defp screen_side(%Screen.PreFare{template: :duo}, %{"screen_side" => "left"}), do: "left"
  defp screen_side(%Screen.PreFare{template: :duo}, %{"screen_side" => "right"}), do: "right"
  defp screen_side(%Screen.PreFare{template: :duo}, _query_params), do: "duo"
  defp screen_side(%Screen.PreFare{template: :solo}, _query_params), do: "solo"
  defp screen_side(_app_params, _params), do: nil
end
