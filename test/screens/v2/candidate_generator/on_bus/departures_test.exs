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

    [
      %Stop{
        id: id,
        name: "Test Stop Name",
        location_type: 0,
        parent_station:
          if parent_station_id != nil do
            build_stop(parent_station_id)
          else
            nil
          end,
        child_stops: Enum.flat_map(Keyword.get(options, :child_ids, []), &build_stop(&1)),
        connecting_stops:
          Enum.flat_map(Keyword.get(options, :connecting_ids, []), &build_stop(&1)),
        platform_code: nil
      }
    ]
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
      {:ok, build_stop("100")}
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

      stub(@stop, :fetch, fn _, _ ->
        {:ok,
         build_stop(stop_id,
           connecting_ids: connecting_stops,
           child_ids: child_stops
         )}
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
end
