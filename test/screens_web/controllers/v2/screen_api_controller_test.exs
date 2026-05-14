defmodule ScreensWeb.V2.ScreenApiControllerTest do
  use ScreensWeb.ConnCase

  alias Screens.ScreensByAlert
  alias Screens.TestSupport.CandidateGeneratorStub, as: Stub
  alias ScreensConfig.Screen

  import Mox
  setup :verify_on_exit!

  import Screens.Inject
  @cache injected(Screens.Config.Cache)
  @parameters injected(Screens.V2.ScreenData.Parameters)

  require Stub

  Stub.candidate_generator(StubGenerator, fn _ -> [placeholder(:blue)] end)

  setup do
    stub(@cache, :last_deploy_timestamp, fn -> ~U[2020-01-01 00:00:00Z] end)
    stub(@cache, :screen, fn _id -> struct(Screen) end)
    stub(@parameters, :candidate_generator, fn _screen, _variant -> StubGenerator end)
    stub(@parameters, :refresh_rate, fn _app_id -> 0 end)
    stub(@parameters, :variants, fn _screen -> [nil] end)
    stub(ScreensByAlert.Mock, :put_data, fn _screen_id, _alert_ids -> :ok end)
    :ok
  end

  describe "show/2" do
    test "tells client to reload when its code is outdated", %{conn: conn} do
      expect(@cache, :last_deploy_timestamp, fn -> ~U[2026-01-01 12:00:00Z] end)

      conn = get(conn, "/v2/api/screen/1?last_refresh=2026-01-01T11:00:00Z")

      assert %{"force_reload" => true} = json_response(conn, 200)
    end

    test "tells client to reload based on refresh_if_loaded_before", %{conn: conn} do
      expect(@cache, :last_deploy_timestamp, fn -> ~U[2026-01-01 12:00:00Z] end)

      expect(@cache, :screen, fn "1" ->
        struct(Screen, refresh_if_loaded_before: ~U[2026-01-01 14:00:00Z])
      end)

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
      expect(@cache, :screen, fn
        "EIG-604" -> struct(Screen, app_id: :gl_eink_v2, vendor: :mercury)
      end)

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
      expect(@cache, :screen, fn
        "1401" -> struct(Screen, app_id: :bus_shelter_v2, vendor: :lg_mri)
      end)

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
