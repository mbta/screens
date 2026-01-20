defmodule Screens.V2.CandidateGenerator.DupNewTest do
  use ExUnit.Case, async: true

  alias Screens.Util.Assets
  alias Screens.V2.CandidateGenerator.DupNew
  alias Screens.V2.RDS
  alias Screens.V2.WidgetInstance.{DeparturesNoData, EvergreenContent}
  alias ScreensConfig.{Alerts, Departures, EvergreenContentItem, Header, Schedule}
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.Dup, as: DupConfig

  import Mox
  setup :verify_on_exit!

  import Screens.Inject
  @alert injected(Screens.Alerts.Alert)
  @rds injected(RDS)

  setup do
    stub(@alert, :fetch, fn _ -> {:ok, []} end)
    stub(@rds, :get, fn _, _ -> [{:ok, []}] end)
    :ok
  end

  describe "candidate_instances/2" do
    @config %Screen{
      app_id: :dup_v2,
      app_params: %DupConfig{
        alerts: %Alerts{stop_id: "place-abcde"},
        header: %Header.StopName{stop_name: "Test Stop"},
        primary_departures: %Departures{sections: []},
        secondary_departures: %Departures{sections: []}
      },
      vendor: :outfront,
      device_id: "TEST",
      name: "TEST"
    }
    @now ~U[2024-01-15 11:45:30Z]

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

      assert expected_instance in DupNew.candidate_instances(config, now_active)
      assert expected_instance not in DupNew.candidate_instances(config, now_inactive)
    end

    test "stub: always returns no-data state for departures" do
      expected_instance = %DeparturesNoData{screen: @config, slot_name: :main_content_zero}
      assert expected_instance in DupNew.candidate_instances(@config, @now)
    end
  end
end
