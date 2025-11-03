defmodule Screens.V2.CandidateGenerator.GlEink.LineMapTest do
  use ExUnit.Case, async: true

  alias Screens.Predictions.Prediction
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Stops.Stop
  alias Screens.V2.CandidateGenerator.GlEink.LineMap
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.LineMap, as: LineMapWidget
  alias ScreensConfig.Screen

  import Mox
  setup :verify_on_exit!

  import Screens.Inject
  @departure injected(Screens.V2.Departure)
  @route_pattern injected(RoutePattern)

  @screen struct(Screen,
            app_params:
              struct(Screen.GlEink,
                line_map: %ScreensConfig.LineMap{
                  stop_id: "stop-test",
                  station_id: "parent-test",
                  direction_id: 0,
                  route_id: "route-test"
                }
              )
          )

  @now ~U[2025-01-01 12:00:00Z]
  @now_with_lookback DateTime.add(@now, -180)

  describe "instances/2" do
    test "fetches data and builds the line map widget" do
      departures = [%Departure{prediction: %Prediction{id: "prediction1"}}]
      stops_dir0 = [%Stop{id: "stop-dir0"}]
      stops_dir1 = [%Stop{id: "stop-dir1"}]

      expect(@departure, :fetch, fn %{stop_ids: ["parent-test"]}, [now: @now_with_lookback] ->
        {:ok, departures}
      end)

      expect(@route_pattern, :fetch, fn %{canonical?: true, route_ids: ["route-test"]} ->
        {:ok,
         [
           %RoutePattern{direction_id: 0, stops: stops_dir0},
           %RoutePattern{direction_id: 1, stops: stops_dir1}
         ]}
      end)

      expected_widget = %LineMapWidget{
        screen: @screen,
        stops: stops_dir0,
        reverse_stops: stops_dir1,
        departures: departures
      }

      assert LineMap.instances(@screen, @now) == [expected_widget]
    end

    test "tolerates data fetching errors and returns no widget" do
      expect(@route_pattern, :fetch, fn _ -> :error end)

      assert LineMap.instances(@screen, @now) == []
    end
  end
end
