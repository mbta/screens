defmodule ScreensWeb.ScreenConfigsApiControllerTest do
  use ScreensWeb.ConnCase

  import ExUnit.CaptureLog
  import Mox
  import Screens.Inject
  import Screens.TestSupport.ScreenConfigBuilder

  alias Screens.Config.ScreenConfig
  alias Screens.Repo
  alias ScreensConfig.Screen

  @data_cache injected(Screens.V2.ScreenData.Cache)
  @env_var "SCREENS_API_CLIENT_KEY"

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    previous_value = System.get_env(@env_var)

    on_exit(fn ->
      restore_env_var(@env_var, previous_value)
    end)

    :ok
  end

  setup :verify_on_exit!

  setup do
    screen_dup_config = screen_config(:dup_v2)
    screen_busway_config = screen_config(:busway_v2)
    screen_bus_eink_config = screen_config(:bus_eink_v2)

    {:ok,
     %{
       screen_dup_config: screen_dup_config,
       screen_busway_config: screen_busway_config,
       screen_bus_eink_config: screen_bus_eink_config
     }}
  end

  describe "index/2" do
    test "returns 401 when bearer token is missing", %{conn: conn} do
      System.put_env(@env_var, "shared-secret")

      capture_log([level: :warning], fn ->
        conn = get(conn, "/api/screen_configs")

        assert conn.status == 401
        assert conn.resp_body == "{\"error\":\"unauthorized\"}"
      end)
    end

    test "returns all screen configs as JSON when bearer token is valid", %{
      conn: conn,
      screen_dup_config: screen_dup_config,
      screen_busway_config: screen_busway_config
    } do
      System.put_env(@env_var, "shared-secret")

      Repo.insert!(%ScreenConfig{id: "screen-1", config: screen_dup_config})
      Repo.insert!(%ScreenConfig{id: "screen-2", config: screen_busway_config})

      conn =
        conn
        |> put_req_header("authorization", "Bearer shared-secret")
        |> get("/api/screen_configs")

      assert conn.status == 200

      %{"config" => config_json} = json_response(conn, 200)
      config = Jason.decode!(config_json)

      assert config["screens"]["screen-1"] == normalize_json(Screen.to_json(screen_dup_config))
      assert config["screens"]["screen-2"] == normalize_json(Screen.to_json(screen_busway_config))
    end

    test "filters screen configs by ids", %{
      conn: conn,
      screen_dup_config: screen_dup_config,
      screen_busway_config: screen_busway_config,
      screen_bus_eink_config: screen_bus_eink_config
    } do
      System.put_env(@env_var, "shared-secret")

      Repo.insert!(%ScreenConfig{id: "screen-1", config: screen_dup_config})
      Repo.insert!(%ScreenConfig{id: "screen-2", config: screen_busway_config})
      Repo.insert!(%ScreenConfig{id: "screen-3", config: screen_bus_eink_config})

      conn =
        conn
        |> put_req_header("authorization", "Bearer shared-secret")
        |> get("/api/screen_configs", %{"ids" => "screen-1,screen-3"})

      assert conn.status == 200

      %{"config" => config_json} = json_response(conn, 200)
      config = Jason.decode!(config_json)

      assert config["screens"]["screen-1"] == normalize_json(Screen.to_json(screen_dup_config))
      assert config["screens"]["screen-2"] == nil

      assert config["screens"]["screen-3"] ==
               normalize_json(Screen.to_json(screen_bus_eink_config))
    end

    test "returns empty screens object when filtering by non-existent ids", %{
      conn: conn,
      screen_dup_config: screen_dup_config
    } do
      System.put_env(@env_var, "shared-secret")

      Repo.insert!(%ScreenConfig{id: "screen-1", config: screen_dup_config})

      conn =
        conn
        |> put_req_header("authorization", "Bearer shared-secret")
        |> get("/api/screen_configs", %{"ids" => "screen-nonexistent"})

      assert conn.status == 200

      %{"config" => config_json} = json_response(conn, 200)
      config = Jason.decode!(config_json)

      assert config["screens"] == %{}
    end
  end

  describe "update/2" do
    test "returns 401 when bearer token is missing", %{conn: conn} do
      System.put_env(@env_var, "shared-secret")

      capture_log([level: :warning], fn ->
        conn =
          post(conn, "/api/screen_configs", %{
            screen_configs: [%{id: "screen-1", config: %{"app_id" => "dup_v2"}}]
          })

        assert conn.status == 401
        assert conn.resp_body == "{\"error\":\"unauthorized\"}"
      end)
    end

    test "updates screen configs in Postgres", %{
      conn: conn,
      screen_dup_config: screen_dup_config,
      screen_busway_config: screen_busway_config
    } do
      System.put_env(@env_var, "shared-secret")
      expect(@data_cache, :invalidate, fn ["screen-1"], fun -> {:ok, fun.()} end)

      Repo.insert!(%ScreenConfig{id: "screen-1", config: screen_dup_config})

      conn =
        conn
        |> put_req_header("authorization", "Bearer shared-secret")
        |> post("/api/screen_configs", %{
          screen_configs: [
            %{id: "screen-1", config: screen_busway_config}
          ]
        })

      assert json_response(conn, 200) == %{"success" => true}

      updated = Repo.get!(ScreenConfig, "screen-1")
      assert updated.config == screen_busway_config
    end

    test "returns 400 when screen_configs param is missing", %{conn: conn} do
      System.put_env(@env_var, "shared-secret")

      capture_log([level: :warning], fn ->
        conn =
          conn
          |> put_req_header("authorization", "Bearer shared-secret")
          |> post("/api/screen_configs", %{})

        assert conn.status == 400
        response = json_response(conn, 400)
        assert response["success"] == false
        assert response["error"] == "screen_configs parameter is required"
      end)
    end
  end

  defp restore_env_var(env_var, nil), do: System.delete_env(env_var)
  defp restore_env_var(env_var, value), do: System.put_env(env_var, value)
end
