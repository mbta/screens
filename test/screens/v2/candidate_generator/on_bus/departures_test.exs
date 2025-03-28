defmodule Screens.V2.CandidateGenerator.Widgets.OnBus.DeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.Lines.Line
  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V2.CandidateGenerator.Widgets.OnBus.Departures
  alias Screens.V2.Departure
  alias Screens.V2.ScreenData.QueryParams
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias Screens.V2.WidgetInstance.Departures.NormalSection
  alias Screens.V2.WidgetInstance.DeparturesNoData
  alias Screens.V2.WidgetInstance.DeparturesNoService
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.OnBus

  import ExUnit.CaptureLog
  import Mox
  import Screens.Inject

  @departure injected(Departure)
  @stop injected(Stop)

  @config %Screen{
    app_params: %OnBus{
      evergreen_content: []
    },
    vendor: nil,
    device_id: nil,
    name: nil,
    app_id: :on_bus_v2
  }
  @route_id "route_id"

  defp build_departure(
         route_id,
         direction_id,
         route_type \\ :bus,
         arrival_time \\ ~U[2024-01-01 12:00:00Z]
       ) do
    %Departure{
      prediction: %Prediction{
        route: %Route{id: route_id, type: route_type, line: %Line{id: route_id}},
        trip: %Trip{direction_id: direction_id, headsign: "headsign"},
        arrival_time: arrival_time
      }
    }
  end

  defp build_stop(id, options \\ []) do
    parent_station_id = Keyword.get(options, :parent_station_id, nil)

    %Stop{
      id: id,
      name: "Test Stop Name",
      location_type: 0,
      parent_station:
        if parent_station_id != nil do
          children_of_parent_ids = Keyword.get(options, :parents_child_ids, [])
          connections_of_parent_ids = Keyword.get(options, :parents_connecting_ids, [])

          build_stop(parent_station_id,
            child_ids: children_of_parent_ids,
            connecting_ids: connections_of_parent_ids
          )
        else
          nil
        end,
      child_stops: Enum.map(Keyword.get(options, :child_ids, []), &build_stop(&1)),
      connecting_stops: Enum.map(Keyword.get(options, :connecting_ids, []), &build_stop(&1)),
      platform_code: nil
    }
  end

  defp departures_candidates(config, %QueryParams{route_id: route_id, stop_id: stop_id}) do
    Departures.departures_candidates(
      config,
      %QueryParams{route_id: route_id, stop_id: stop_id},
      DateTime.utc_now()
    )
  end

  setup do
    stub(@stop, :fetch, fn _, _ ->
      {:ok, [build_stop("100")]}
    end)

    {:ok, %{now: DateTime.utc_now()}}
  end

  describe "departures_candidates/3" do
    test "happy path returns a DeparturesWidget with single section containing two departures" do
      route_id = "86"
      stop_id = "100"

      mock_departures = [build_departure("66", 0), build_departure("109", 0)]

      stub(@departure, :fetch, fn _, _ ->
        {:ok, mock_departures}
      end)

      assert [
               %DeparturesWidget{
                 screen: @config,
                 sections: [
                   %NormalSection{rows: ^mock_departures}
                 ]
               }
             ] =
               departures_candidates(@config, %QueryParams{route_id: route_id, stop_id: stop_id})
    end

    test "returns DeparturesNoData section when fetch fails" do
      route_id = "86"
      stop_id = "100"

      stub(@departure, :fetch, fn _, _ -> :error end)

      assert departures_candidates(@config, %QueryParams{route_id: route_id, stop_id: stop_id}) ==
               [%DeparturesNoData{screen: @config}]
    end

    test "returns DeparturesNoService section when fetch finds no departures" do
      route_id = "86"
      stop_id = "100"

      stub(@departure, :fetch, fn %{stop_ids: [^stop_id]}, _ ->
        {:ok, []}
      end)

      assert departures_candidates(
               @config,
               %QueryParams{route_id: route_id, stop_id: stop_id}
             ) == [%DeparturesNoService{screen: @config}]
    end

    test "filters out departures for the current route_id" do
      route_id = "86"
      stop_id = "22549"
      child_stops = ["2", "5"]
      connecting_stops = ["100", "12345"]
      all_stops = Enum.concat([[stop_id], child_stops, connecting_stops])

      stub(@stop, :fetch, fn %{ids: [^stop_id]}, _ ->
        {:ok,
         [
           build_stop(stop_id,
             connecting_ids: connecting_stops,
             child_ids: child_stops
           )
         ]}
      end)

      mock_departures = [
        build_departure("66", 0),
        build_departure("78", 0),
        build_departure("109", 0)
      ]

      # 86 prediction scheduled for 1 minute earlier
      mock_departures_on_route = [build_departure("86", 0, :bus, ~U[2024-01-01 11:59:00Z])]

      stub(@departure, :fetch, fn %{stop_ids: ^all_stops}, _ ->
        {:ok, mock_departures ++ mock_departures_on_route}
      end)

      assert [
               %DeparturesWidget{
                 screen: @config,
                 sections: [
                   %NormalSection{rows: ^mock_departures}
                 ]
               }
             ] =
               departures_candidates(@config, %QueryParams{route_id: route_id, stop_id: stop_id})
    end

    test "Orders departures of different modes correctly and filters duplicates" do
      route_id = "86"
      stop_id = "22549"

      stub(@stop, :fetch, fn %{ids: [^stop_id]}, _ ->
        {:ok, [build_stop(stop_id)]}
      end)

      priority_departures = [
        build_departure("subway_id", 0, :subway, ~U[2024-01-01 11:55:00Z]),
        build_departure("light_rail_id", 0, :light_rail, ~U[2024-01-01 11:55:00Z]),
        build_departure("bus_early", 0, :bus, ~U[2024-01-01 11:50:00Z])
      ]

      additional_departures = [
        build_departure("bus_later", 0, :bus, ~U[2024-01-01 11:52:00Z]),
        build_departure("subway_id", 0, :subway, ~U[2024-01-01 11:59:00Z]),
        build_departure("commuter_rail_id", 0, :commuter_rail, ~U[2024-01-01 11:45:00Z])
      ]

      stub(@departure, :fetch, fn %{stop_ids: [^stop_id]}, _ ->
        {:ok, priority_departures ++ additional_departures}
      end)

      assert [
               %DeparturesWidget{
                 screen: @config,
                 sections: [
                   %NormalSection{rows: ^priority_departures}
                 ]
               }
             ] =
               departures_candidates(@config, %QueryParams{route_id: route_id, stop_id: stop_id})
    end

    test "Returns 3 departures, even if they are all for the same route" do
      route_id = "66"
      stop_id = "22549"

      stub(@stop, :fetch, fn %{ids: [^stop_id]}, _ ->
        {:ok, [build_stop(stop_id)]}
      end)

      priority_departures = [
        build_departure("86", 0, :bus, ~U[2024-01-01 11:51:00Z]),
        build_departure("86", 0, :bus, ~U[2024-01-01 11:52:00Z]),
        build_departure("86", 0, :bus, ~U[2024-01-01 11:53:00Z])
      ]

      additional_departures = [
        build_departure("86", 0, :bus, ~U[2024-01-01 11:54:00Z]),
        build_departure("86", 0, :bus, ~U[2024-01-01 11:55:00Z]),
        build_departure("86", 0, :bus, ~U[2024-01-01 11:56:00Z])
      ]

      stub(@departure, :fetch, fn %{stop_ids: [^stop_id]}, _ ->
        {:ok, priority_departures ++ additional_departures}
      end)

      assert [
               %DeparturesWidget{
                 screen: @config,
                 sections: [
                   %NormalSection{rows: ^priority_departures}
                 ]
               }
             ] =
               departures_candidates(@config, %QueryParams{route_id: route_id, stop_id: stop_id})
    end

    test "When only 2 unique route/directions, return 3 stops, including one of each" do
      route_id = "66"
      stop_id = "22549"

      stub(@stop, :fetch, fn %{ids: [^stop_id]}, _ ->
        {:ok, [build_stop(stop_id)]}
      end)

      priority_departures = [
        build_departure("86", 0, :bus, ~U[2024-01-01 11:51:00Z]),
        build_departure("86", 0, :bus, ~U[2024-01-01 11:52:00Z]),
        build_departure("86", 1, :bus, ~U[2024-01-01 11:59:00Z])
      ]

      # earlier departures also with direction_id of 0
      additional_departures = [
        build_departure("86", 0, :bus, ~U[2024-01-01 11:53:00Z]),
        build_departure("86", 0, :bus, ~U[2024-01-01 11:54:00Z]),
        build_departure("86", 0, :bus, ~U[2024-01-01 11:55:00Z])
      ]

      stub(@departure, :fetch, fn %{stop_ids: [^stop_id]}, _ ->
        {:ok, priority_departures ++ additional_departures}
      end)

      assert [
               %DeparturesWidget{
                 screen: @config,
                 sections: [
                   %NormalSection{rows: ^priority_departures}
                 ]
               }
             ] =
               departures_candidates(@config, %QueryParams{route_id: route_id, stop_id: stop_id})
    end
  end

  describe "fetch_connecting_stops/1 behavior within departures_candidates/3 " do
    test "single stop with no connections" do
      stop_id = "no_connections_stop"

      mock_departures = [build_departure("66", 0)]

      stub(@stop, :fetch, fn %{ids: [^stop_id]}, _ ->
        {:ok, [build_stop(stop_id)]}
      end)

      stub(@departure, :fetch, fn %{stop_ids: [^stop_id]}, _ ->
        {:ok, mock_departures}
      end)

      assert [
               %DeparturesWidget{
                 screen: @config,
                 sections: [%NormalSection{rows: ^mock_departures}]
               }
             ] =
               departures_candidates(@config, %QueryParams{route_id: @route_id, stop_id: stop_id})
    end

    test "single stop with only connecting stops" do
      stop_id = "only_connecting_stops"
      connecting_stop_ids = ["connection_1", "connection_2"]

      all_stops = [build_stop(stop_id, connecting_ids: connecting_stop_ids)]
      all_stop_ids = Enum.concat([[stop_id], connecting_stop_ids])
      mock_departures = [build_departure("66", 0)]

      stub(@stop, :fetch, fn %{ids: [^stop_id]}, _ ->
        {:ok, all_stops}
      end)

      stub(@departure, :fetch, fn %{stop_ids: ^all_stop_ids}, _ ->
        {:ok, mock_departures}
      end)

      assert [
               %DeparturesWidget{
                 screen: @config,
                 sections: [%NormalSection{rows: ^mock_departures}]
               }
             ] =
               departures_candidates(@config, %QueryParams{route_id: @route_id, stop_id: stop_id})
    end

    test "single stop with only a parent station" do
      stop_id = "has_a_parent_id"
      parent_id = "parent_id"
      all_stops = [build_stop(stop_id, parent_station_id: parent_id)]
      all_stop_ids = Enum.concat([[stop_id], [parent_id]])
      mock_departures = [build_departure("66", 0)]

      stub(@stop, :fetch, fn %{ids: [^stop_id]}, _ ->
        {:ok, all_stops}
      end)

      stub(@departure, :fetch, fn %{stop_ids: ^all_stop_ids}, _ ->
        {:ok, mock_departures}
      end)

      assert [
               %DeparturesWidget{
                 screen: @config,
                 sections: [%NormalSection{rows: ^mock_departures}]
               }
             ] =
               departures_candidates(@config, %QueryParams{route_id: @route_id, stop_id: stop_id})
    end

    test "stop with a parent station that has children and connecting stops" do
      stop_id = "has_a_parent_id"
      parent_id = "parent_id"
      children_of_parent_ids = ["child_1", "child_2", "child_3"]
      connections_of_parent_ids = ["conn_1", "conn_2", "conn_3"]
      mock_departures = [build_departure("66", 0)]

      all_stops = [
        build_stop(stop_id,
          parent_station_id: parent_id,
          parents_child_ids: children_of_parent_ids,
          parents_connecting_ids: connections_of_parent_ids
        )
      ]

      all_stop_ids =
        Enum.concat([[stop_id], [parent_id], children_of_parent_ids, connections_of_parent_ids])

      stub(@stop, :fetch, fn %{ids: [^stop_id]}, _ ->
        {:ok, all_stops}
      end)

      stub(@departure, :fetch, fn %{stop_ids: ^all_stop_ids}, _ ->
        {:ok, mock_departures}
      end)

      assert [
               %DeparturesWidget{
                 screen: @config,
                 sections: [%NormalSection{rows: ^mock_departures}]
               }
             ] =
               departures_candidates(@config, %QueryParams{route_id: @route_id, stop_id: stop_id})
    end

    test "connection lookup failure results in warning log but still returns departures for stop" do
      stop_id = "failure_id"
      mock_departures = [build_departure("66", 0)]

      stub(@stop, :fetch, fn %{ids: [^stop_id]}, _ ->
        :error
      end)

      stub(@departure, :fetch, fn %{stop_ids: [^stop_id]}, _ ->
        {:ok, mock_departures}
      end)

      warning_log =
        capture_log([level: :warning], fn ->
          [
            %DeparturesWidget{
              screen: @config,
              sections: [%NormalSection{rows: ^mock_departures}]
            }
          ] =
            departures_candidates(@config, %QueryParams{route_id: @route_id, stop_id: stop_id})
        end)

      assert warning_log =~ stop_id
    end
  end
end
