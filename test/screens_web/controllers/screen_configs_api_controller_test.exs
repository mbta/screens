defmodule ScreensWeb.ScreenConfigsApiControllerTest do
  use ScreensWeb.ConnCase

  import ExUnit.CaptureLog
  import Mox

  alias Screens.Config.ScreenConfig
  alias Screens.Repo

  @env_var "SCREENS_API_CLIENT_KEY"

  # Test config constants
  @screen_dup_config %{"app_id" => "dup_v2"}
  @screen_busway_config %{"app_id" => "busway_v2"}
  @screen_dup_old_config %{"app_id" => "dup_old"}

  @legacy_config %{
    "screens" => %{
      "dup_1" => @screen_dup_config,
      "busway_1" => @screen_busway_config
    }
  }

  @legacy_config_dup_only %{
    "screens" => %{
      "dup_1" => @screen_dup_old_config
    }
  }

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    previous_value = System.get_env(@env_var)
    previous_config_migration = Application.get_env(:screens, :config_migration)

    on_exit(fn ->
      restore_env_var(@env_var, previous_value)
      restore_app_env(:screens, :config_migration, previous_config_migration)
    end)

    :ok
  end

  setup :verify_on_exit!

  describe "index/2" do
    test "returns 401 when bearer token is missing", %{conn: conn} do
      System.put_env(@env_var, "shared-secret")

      capture_log([level: :warning], fn ->
        conn = get(conn, "/api/screen_configs")

        assert conn.status == 401
        assert conn.resp_body == "{\"error\":\"unauthorized\"}"
      end)
    end

    test "returns all screen configs as JSON when bearer token is valid", %{conn: conn} do
      System.put_env(@env_var, "shared-secret")
      Application.put_env(:screens, :config_migration, true)

      Repo.insert!(%ScreenConfig{id: "screen-1", config: @screen_dup_config})
      Repo.insert!(%ScreenConfig{id: "screen-2", config: @screen_busway_config})

      conn =
        conn
        |> put_req_header("authorization", "Bearer shared-secret")
        |> get("/api/screen_configs")

      assert conn.status == 200

      %{"screen_configs" => screen_configs} = json_response(conn, 200)

      assert length(screen_configs) == 2
      configs_by_id = Map.new(screen_configs, &{&1["id"], &1["config"]})
      assert configs_by_id["screen-1"] == @screen_dup_config
      assert configs_by_id["screen-2"] == @screen_busway_config
    end

    test "returns screen configs from legacy config source when migration flag is false", %{
      conn: conn
    } do
      System.put_env(@env_var, "shared-secret")
      Application.put_env(:screens, :config_migration, false)

      # Mock fetch_config to return our test config
      expect(Screens.Config.Fetch.Mock, :fetch_config, fn ->
        {:ok, Jason.encode!(@legacy_config), 1}
      end)

      conn =
        conn
        |> put_req_header("authorization", "Bearer shared-secret")
        |> get("/api/screen_configs")

      assert conn.status == 200

      %{"screen_configs" => screen_configs} = json_response(conn, 200)

      # Verify configs match our constants
      configs_by_id = Map.new(screen_configs, &{&1["id"], &1["config"]})
      assert configs_by_id["dup_1"] == @screen_dup_config
      assert configs_by_id["busway_1"] == @screen_busway_config
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

    test "updates screen configs in Postgres when migration flag is true", %{conn: conn} do
      System.put_env(@env_var, "shared-secret")
      Application.put_env(:screens, :config_migration, true)

      Repo.insert!(%ScreenConfig{id: "screen-1", config: @screen_dup_config})

      conn =
        conn
        |> put_req_header("authorization", "Bearer shared-secret")
        |> post("/api/screen_configs", %{
          screen_configs: [
            %{id: "screen-1", config: @screen_busway_config}
          ]
        })

      assert json_response(conn, 200) == %{"success" => true}

      updated = Repo.get!(ScreenConfig, "screen-1")
      assert updated.config == @screen_busway_config
    end

    test "updates full config when migration flag is false", %{conn: conn} do
      System.put_env(@env_var, "shared-secret")
      Application.put_env(:screens, :config_migration, false)

      # Mock the fetch and put to prevent writing to the fixture file
      expect(Screens.Config.Fetch.Mock, :fetch_config, fn ->
        {:ok, Jason.encode!(@legacy_config_dup_only), 1}
      end)

      expect(Screens.Config.Fetch.Mock, :put_config, fn config ->
        # Verify the updated config has the new screen 1001 config
        {:ok, decoded} = Jason.decode(config)
        screens = Map.get(decoded, "screens", %{})
        assert screens["dup_1"] == @screen_dup_config
        :ok
      end)

      conn =
        conn
        |> put_req_header("authorization", "Bearer shared-secret")
        |> post("/api/screen_configs", %{
          screen_configs: [
            %{"id" => "dup_1", "config" => @screen_dup_config}
          ]
        })

      assert json_response(conn, 200) == %{"success" => true}
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

  defp restore_app_env(app, key, nil), do: Application.delete_env(app, key)
  defp restore_app_env(app, key, value), do: Application.put_env(app, key, value)
end
