defmodule ScreensWeb.V2.ScreenApiControllerTest do
  use ScreensWeb.ConnCase

  alias Screens.ScreensByAlert
  alias Screens.TestSupport.CandidateGeneratorStub, as: Stub
  alias ScreensConfig.Screen

  import Screens.Inject
  import Mox
  setup :verify_on_exit!

  @cache injected(Screens.Config.Cache)
  @parameters injected(Screens.V2.ScreenData.Parameters)

  require Stub

  Stub.candidate_generator(MercuryGenerator, fn _ -> [placeholder(:green)] end)
  Stub.candidate_generator(LgMriGenerator, fn _ -> [placeholder(:red)] end)

  setup do
    stub(@parameters, :refresh_rate, fn _app_id -> 0 end)
    stub(@parameters, :variants, fn _ -> [nil] end)
    stub(ScreensByAlert.Mock, :put_data, fn _screen_id, _alert_ids -> :ok end)
    :ok
  end

  describe "show/2" do
    test "only returns flex_zone for Mercury screens", %{conn: conn} do
      expect(@cache, :screen, fn
        "EIG-604" ->
          struct(Screen, app_id: :gl_eink_v2, vendor: :mercury)
      end)

      stub(
        @parameters,
        :candidate_generator,
        fn %Screen{vendor: :mercury}, nil -> MercuryGenerator end
      )

      conn = get(conn, "/v2/api/screen/EIG-604?last_refresh=2024-12-02T00:00:00Z")

      assert %{
               "audio_data" => "",
               "data" => %{
                 "main" => %{"color" => "green", "type" => "placeholder", "text" => ""},
                 "type" => "normal"
               },
               "disabled" => false,
               "flex_zone" => [],
               "force_reload" => false,
               "last_deploy_timestamp" => nil
             } == json_response(conn, 200)
    end

    test "omits flex_zone from non-Mercury screens", %{conn: conn} do
      expect(@cache, :screen, fn
        "1401" ->
          struct(Screen, app_id: :bus_shelter_v2, vendor: :lg_mri)
      end)

      stub(
        @parameters,
        :candidate_generator,
        fn %Screen{vendor: :lg_mri}, nil -> LgMriGenerator end
      )

      conn = get(conn, "/v2/api/screen/1401?last_refresh=2024-12-02T00:00:00Z")

      assert %{
               "data" => %{
                 "main" => %{"color" => "red", "type" => "placeholder", "text" => ""},
                 "type" => "normal"
               },
               "disabled" => false,
               "force_reload" => false
             } == json_response(conn, 200)
    end
  end
end
