defmodule Screens.V2.CandidateGenerator.Widgets.SubwayStatusTest do
  use ExUnit.Case

  alias Screens.Alerts.Alert
  alias Screens.V2.CandidateGenerator.Widgets.SubwayStatus
  alias Screens.V2.WidgetInstance.SubwayStatus, as: SubwayStatusWidget
  alias ScreensConfig.Screen

  describe "subway_status_instances/3" do
    setup do
      config =
        struct(Screen, %{
          app_id: :pre_fare_v2
        })

      %{
        config: config,
        now: ~U[2026-07-07T01:00:00Z]
      }
    end

    test "filters out stale alerts", context do
      %{
        config: config,
        now: now
      } = context

      one_week_in_seconds = 604_800
      ten_weeks_ago = DateTime.add(now, -10 * one_week_in_seconds)

      alerts = [
        %Alert{
          id: "1",
          effect: :station_closure,
          informed_entities: [],
          active_period: [{ten_weeks_ago, nil}]
        }
      ]

      fetch_alerts_fn = fn _ -> {:ok, alerts} end

      assert [%SubwayStatusWidget{screen: config, subway_alerts: []}] ==
               SubwayStatus.subway_status_instances(config, now, fetch_alerts_fn)
    end
  end
end
