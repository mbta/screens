defmodule Screens.V2.CandidateGenerator.DupNewTest do
  use ExUnit.Case, async: true

  alias Screens.Util.Assets
  alias Screens.V2.CandidateGenerator.DupNew
  alias Screens.V2.ScreenData.QueryParams
  alias Screens.V2.WidgetInstance.{DeparturesNoData, EvergreenContent, NormalHeader}
  alias ScreensConfig.{Alerts, Departures, EvergreenContentItem, Header, Schedule}
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.Dup, as: DupConfig

  import Screens.Inject
  import Mox
  setup :verify_on_exit!

  @stop injected(Screens.Stops.Stop)

  describe "candidate_instances/2" do
    @config %Screen{
      app_id: :dup_v2,
      app_params: %DupConfig{
        alerts: %Alerts{stop_id: "place-abcde"},
        header: %Header.CurrentStopName{stop_name: "Test Stop"},
        primary_departures: %Departures{sections: []},
        secondary_departures: %Departures{sections: []}
      },
      vendor: :outfront,
      device_id: "TEST",
      name: "TEST"
    }
    @now ~U[2024-01-15 11:45:30Z]
    @query_params %QueryParams{}

    test "returns expected header instances" do
      expected_header = %NormalHeader{screen: @config, icon: :logo, text: "Test Stop", time: @now}

      instances = DupNew.candidate_instances(@config, @query_params, @now)

      assert Enum.filter(instances, &is_struct(&1, NormalHeader)) ==
               List.duplicate(expected_header, 3)
    end

    test "returns header with stop name determined from stop ID" do
      config = put_in(@config.app_params.header, %Header.CurrentStopId{stop_id: "test_id"})
      expect(@stop, :fetch_stop_name, fn "test_id" -> "Test Name" end)

      instances = DupNew.candidate_instances(config, @query_params, @now)

      assert %NormalHeader{text: "Test Name"} = Enum.find(instances, &is_struct(&1, NormalHeader))
    end

    test "returns evergreen content when scheduled" do
      schedule = %Schedule{start_dt: ~U[2024-01-01 00:00:00Z], end_dt: ~U[2024-02-01 00:00:00Z]}

      item = %EvergreenContentItem{
        asset_path: "test.png",
        priority: [1],
        schedule: [schedule],
        slot_names: ["bottom_pane_zero"]
      }

      config = put_in(@config.app_params.evergreen_content, [item])
      now_active = ~U[2024-01-10 00:00:00Z]
      now_inactive = ~U[2024-02-02 00:00:00Z]

      expected_instance = %EvergreenContent{
        screen: config,
        asset_url: Assets.s3_asset_url("test.png"),
        now: now_active,
        priority: [1],
        schedule: [schedule],
        slot_names: [:bottom_pane_zero]
      }

      assert expected_instance in DupNew.candidate_instances(config, @query_params, now_active)

      assert expected_instance not in DupNew.candidate_instances(
               config,
               @query_params,
               now_inactive
             )
    end

    test "stub: always returns no-data state for departures" do
      expected_instance = %DeparturesNoData{screen: @config, slot_name: :main_content_zero}
      assert expected_instance in DupNew.candidate_instances(@config, @query_params, @now)
    end
  end
end
