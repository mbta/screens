defmodule ScreensWeb.Plug.ScreenRequestTest do
  use ScreensWeb.ConnCase

  alias Plug.Conn
  alias Screens.Config.ScreenConfig
  alias Screens.Repo
  alias ScreensConfig.Screen
  alias ScreensWeb.Plug.ScreenRequest
  alias ScreensWeb.Plug.ScreenRequest.Options

  import Mox
  setup :verify_on_exit!

  import Screens.Inject
  @cache injected(Screens.Config.Cache)

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    stub(@cache, :screen, fn _id -> nil end)

    previous_config_migration = Application.get_env(:screens, :config_migration)
    Application.put_env(:screens, :config_migration, false)

    on_exit(fn ->
      restore_app_env(:screens, :config_migration, previous_config_migration)
    end)

    :ok
  end

  describe "init/1" do
    test "parses options" do
      assert ScreenRequest.init(type: :data) == %Options{type: :data}
      assert_raise KeyError, fn -> ScreenRequest.init(badopt: nil) end
    end
  end

  describe "call/2" do
    @screen %Screen{
      app_id: :pre_fare_v2,
      app_params: %Screen.PreFare{
        content_summary: %ScreensConfig.ContentSummary{parent_station_id: ""},
        elevator_status: %ScreensConfig.ElevatorStatus{parent_station_id: ""},
        full_line_map: [%ScreensConfig.FullLineMap{asset_path: ""}],
        header: %ScreensConfig.Header.StopName{stop_name: ""},
        reconstructed_alert_widget: %ScreensConfig.Alerts{stop_id: ""}
      },
      device_id: "",
      name: "",
      vendor: nil
    }

    defp make_successful(%Conn{} = conn, screen \\ @screen) do
      id = System.unique_integer() |> to_string()
      expect(@cache, :screen, fn ^id -> screen end)
      %Conn{conn | path_params: %{"id" => id}}
    end

    test "errors when the request is missing an ID path param", %{conn: conn} do
      conn = ScreenRequest.call(conn, %Options{})
      assert response(conn, 400)
    end

    test "errors when no screen exists for the given ID", %{conn: %Conn{} = conn} do
      conn = ScreenRequest.call(%Conn{conn | path_params: %{"id" => "1"}}, %Options{})
      assert response(conn, 404)
    end

    test "assigns screen ID and configuration", %{conn: %Conn{} = conn} do
      expect(@cache, :screen, fn "1" -> @screen end)

      %Conn{assigns: assigns} =
        ScreenRequest.call(%Conn{conn | path_params: %{"id" => "1"}}, %Options{})

      assert %{screen_id: "1", screen: %{app_id: :pre_fare_v2}} = assigns
    end

    test "fetches screen config from Postgres when migration flag is true", %{
      conn: %Conn{} = conn
    } do
      Application.put_env(:screens, :config_migration, true)

      Repo.insert!(%ScreenConfig{id: "1", config: @screen})

      %Conn{assigns: assigns} =
        ScreenRequest.call(%Conn{conn | path_params: %{"id" => "1"}}, %Options{})

      assert %{screen_id: "1", screen: %{app_id: :pre_fare_v2}} = assigns
    end

    test "populates assigns from params", %{conn: conn} do
      %Conn{assigns: assigns} =
        conn
        |> make_successful()
        |> struct!(query_string: "requestor=test&rotation_index=2")
        |> ScreenRequest.call(%Options{})

      assert %{requestor: "test", rotation_index: "2"} = assigns
    end

    test "assigns is_real_screen from param", %{conn: conn} do
      %Conn{assigns: assigns} =
        conn
        |> make_successful()
        |> struct!(query_string: "is_real_screen=true")
        |> ScreenRequest.call(%Options{})

      assert %{is_real_screen: true} = assigns
    end

    test "assigns screen_side based on screen config and param", %{conn: conn} do
      solo = put_in(@screen.app_params.template, :solo)
      duo = put_in(@screen.app_params.template, :duo)

      assert %Conn{assigns: %{screen_side: "solo"}} =
               conn
               |> make_successful(solo)
               |> ScreenRequest.call(%Options{})

      assert %Conn{assigns: %{screen_side: "duo"}} =
               conn
               |> make_successful(duo)
               |> ScreenRequest.call(%Options{})

      assert %Conn{assigns: %{screen_side: "left"}} =
               conn
               |> make_successful(duo)
               |> struct!(query_string: "screen_side=left")
               |> ScreenRequest.call(%Options{})

      assert %Conn{assigns: %{screen_side: "right"}} =
               conn
               |> make_successful(duo)
               |> struct!(query_string: "screen_side=right")
               |> ScreenRequest.call(%Options{})
    end

    test "sets logger metadata from request type passed in options", %{conn: conn} do
      conn |> make_successful() |> ScreenRequest.call(%Options{type: :foo})
      assert Logger.metadata() |> Keyword.get(:request_type) == :foo
    end
  end

  defp restore_app_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_app_env(app, key, value), do: Application.put_env(app, key, value)
end
