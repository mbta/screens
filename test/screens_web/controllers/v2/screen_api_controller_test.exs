defmodule ScreensWeb.V2.ScreenApiControllerTest do
  use ScreensWeb.ConnCase

  alias Screens.Config.ScreenConfig
  alias Screens.Repo
  alias Screens.ScreensByAlert
  alias Screens.TestSupport.CandidateGeneratorStub, as: Stub
  alias Screens.TestSupport.ScreenDataCache

  import Mox
  import Screens.Inject
  import Screens.TestSupport.ScreenConfigBuilder

  setup :verify_on_exit!
  setup {ScreenDataCache, :passthrough}

  @build_info injected(Screens.Util.BuildInfo)
  @parameters injected(Screens.V2.ScreenData.Parameters)

  require Stub

  Stub.candidate_generator(StubGenerator, fn _ -> [placeholder(:blue)] end)

  setup do
    stub(@build_info, :build_identifier, fn -> ~U[2020-01-01 00:00:00Z] end)
    stub(@parameters, :candidate_generator, fn _screen -> StubGenerator end)
    stub(@parameters, :refresh_rate, fn _app_id -> 0 end)
    stub(ScreensByAlert.Mock, :put_data, fn _screen_id, _alert_ids -> :ok end)

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)

    Repo.insert!(%ScreenConfig{id: "1", config: screen_config(:dup_v2)})

    :ok
  end

  describe "show/2" do
    test "tells client to reload when its code is outdated", %{conn: conn} do
      expect(@build_info, :build_identifier, fn -> ~U[2026-01-01 12:00:00Z] end)

      conn = get(conn, "/v2/api/screen/1?last_refresh=2026-01-01T11:00:00Z")

      assert %{"force_reload" => true} = json_response(conn, 200)
    end

    test "tells client to reload based on refresh_if_loaded_before", %{conn: conn} do
      expect(@build_info, :build_identifier, fn -> ~U[2026-01-01 12:00:00Z] end)

      Repo.get!(ScreenConfig, "1")
      |> ScreenConfig.changeset(%{
        config: %{screen_config(:dup_v2) | refresh_if_loaded_before: ~U[2026-01-01 14:00:00Z]}
      })
      |> Repo.update!()

      conn = get(conn, "/v2/api/screen/1?last_refresh=2026-01-01T13:00:00Z")

      assert %{"force_reload" => true} = json_response(conn, 200)
    end

    test "does not tell packaged client to reload", %{conn: conn} do
      conn = get(conn, "/v2/api/screen/1?last_refresh=packaged")

      assert %{"force_reload" => false} = json_response(conn, 200)
    end

    @tag :capture_log
    test "errors on missing or invalid refresh timestamp", %{conn: conn} do
      assert conn |> get("/v2/api/screen/1") |> response(400)
      assert conn |> get("/v2/api/screen/1?last_refresh=foo") |> response(400)
    end

    test "returns flex_zone for Mercury screens", %{conn: conn} do
      Repo.insert!(%ScreenConfig{
        id: "EIG-604",
        config: screen_config(:bus_eink_v2, vendor: :mercury)
      })

      conn = get(conn, "/v2/api/screen/EIG-604?last_refresh=2024-12-02T00:00:00Z")

      assert %{
               "audio_data" => "",
               "data" => %{
                 "main" => %{"color" => "blue", "type" => "placeholder", "text" => ""},
                 "type" => "normal"
               },
               "disabled" => false,
               "flex_zone" => [],
               "force_reload" => false,
               "last_deploy_timestamp" => "2020-01-01T00:00:00Z"
             } == json_response(conn, 200)
    end

    test "omits flex_zone from non-Mercury screens", %{conn: conn} do
      Repo.insert!(%ScreenConfig{id: "1401", config: screen_config(:dup_v2, vendor: :lg_mri)})

      conn = get(conn, "/v2/api/screen/1401?last_refresh=2024-12-02T00:00:00Z")

      assert %{
               "data" => %{
                 "main" => %{"color" => "blue", "type" => "placeholder", "text" => ""},
                 "type" => "normal"
               },
               "disabled" => false,
               "force_reload" => false
             } == json_response(conn, 200)
    end
  end
end
