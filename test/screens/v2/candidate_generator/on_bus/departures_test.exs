defmodule Screens.V2.CandidateGenerator.Widgets.OnBus.DeparturesTest do
  use ExUnit.Case, async: true

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

  defp build_departure(
         route_id,
         direction_id,
         route_type \\ :bus,
         arrival_time \\ ~U[2024-01-01 12:00:00Z]
       ) do
    %Departure{
      prediction: %Prediction{
        route: %Route{id: route_id, type: route_type},
        trip: %Trip{direction_id: direction_id},
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

  defp departures_candidate(config, %QueryParams{route_id: route_id, stop_id: stop_id}) do
    Departures.departures_candidate(
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

  describe "departures_candidate/3" do
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
             ] = departures_candidate(@config, %QueryParams{route_id: route_id, stop_id: stop_id})
    end

    test "returns DeparturesNoData section when fetch fails" do
      route_id = "86"
      stop_id = "100"

      stub(@departure, :fetch, fn _, _ -> :error end)

      assert departures_candidate(@config, %QueryParams{route_id: route_id, stop_id: stop_id}) ==
               [%DeparturesNoData{screen: @config}]
    end

    test "filters out departures for the current route_id" do
      route_id = "86"
      stop_id = "22549"
      child_stops = ["2", "5"]
      connecting_stops = ["100", "12345"]
      all_stops = [stop_id] |> Enum.concat(child_stops) |> Enum.concat(connecting_stops)

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
             ] = departures_candidate(@config, %QueryParams{route_id: route_id, stop_id: stop_id})
    end

    test "returns DeparturesNoService section when fetch finds no departures" do
      route_id = "86"
      stop_id = "100"

      stub(@departure, :fetch, fn %{stop_ids: [^stop_id]}, _ ->
        {:ok, []}
      end)

      assert departures_candidate(
               @config,
               %QueryParams{route_id: route_id, stop_id: stop_id}
             ) == [%DeparturesNoService{screen: @config}]
    end
  end

  describe "fetch_connecting_stops/1" do
    test "single stop with no connections" do
      stop_id = "no_connections_stop"

      stub(@stop, :fetch, fn %{ids: [^stop_id]}, _ ->
        {:ok, [build_stop(stop_id)]}
      end)

      assert [^stop_id] = Departures.fetch_connecting_stops(stop_id)
    end

    test "single stop with only connecting stops" do
      stop_id = "only_connecting_stops"
      connecting_stop_ids = ["connection_1", "connection_2"]

      stub(@stop, :fetch, fn %{ids: [^stop_id]}, _ ->
        {:ok, [build_stop(stop_id, connecting_ids: connecting_stop_ids)]}
      end)

      assert [^stop_id] ++ ^connecting_stop_ids = Departures.fetch_connecting_stops(stop_id)
    end

    test "single stop with only a parent station" do
      stop_id = "has_a_parent_id"
      parent_id = "parent_id"

      stub(@stop, :fetch, fn %{ids: [^stop_id]}, _ ->
        {:ok, [build_stop(stop_id, parent_station_id: parent_id)]}
      end)

      assert [^stop_id] ++ [^parent_id] =
               Departures.fetch_connecting_stops(stop_id)
    end

    test "stop with a parent station that has children and connecting stops" do
      stop_id = "has_a_parent_id"
      parent_id = "parent_id"
      children_of_parent_ids = ["child_1", "child_2", "child_3"]
      connections_of_parent_ids = ["conn_1", "conn_2", "conn_3"]

      all_stop_ids =
        [stop_id]
        |> Enum.concat([parent_id])
        |> Enum.concat(children_of_parent_ids)
        |> Enum.concat(connections_of_parent_ids)

      stub(@stop, :fetch, fn %{ids: [^stop_id]}, _ ->
        {:ok,
         [
           build_stop(stop_id,
             parent_station_id: parent_id,
             parents_child_ids: children_of_parent_ids,
             parents_connecting_ids: connections_of_parent_ids
           )
         ]}
      end)

      assert ^all_stop_ids = Departures.fetch_connecting_stops(stop_id)
    end

    test "stop lookup fails" do
      stop_id = "failure_id"

      stub(@stop, :fetch, fn %{ids: [^stop_id]}, _ -> :error end)

      assert [^stop_id] = Departures.fetch_connecting_stops(stop_id)
    end
  end
end
