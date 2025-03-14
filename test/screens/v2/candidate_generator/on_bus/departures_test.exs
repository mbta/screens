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

  @stop injected(Stop)

  defp build_config() do
    %Screen{
      app_params: %OnBus{
        evergreen_content: []
      },
      vendor: nil,
      device_id: nil,
      name: nil,
      app_id: :on_bus_v2
    }
  end

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

  defp build_stops(ids) do
    Enum.map(ids, fn id ->
      %Stop{
        id: id,
        name: "Test Stop Name",
        location_type: 0,
        parent_station: nil,
        child_stops: nil,
        platform_code: nil
      }
    end)
  end

  defp departures_candidate(config, %QueryParams{route_id: route_id, stop_id: stop_id}, fetch_fn) do
    Departures.departures_candidate(
      config,
      %QueryParams{route_id: route_id, stop_id: stop_id},
      DateTime.utc_now(),
      fetch_fn
    )
  end

  setup do
    stub(@stop, :fetch_connecting, fn _ ->
      {:ok, build_stops(~w[100])}
    end)

    {:ok, %{now: DateTime.utc_now()}}
  end

  describe "departures_candidate/3" do
    test "happy path returns a DeparturesWidget with single section containing two departures" do
      config = build_config()
      route_id = "86"
      stop_id = "100"

      mock_departures = [build_departure("66", 0), build_departure("109", 0)]

      mock_fetch_fn = fn %{stop_ids: [^stop_id]}, [include_schedules: false] ->
        {:ok, mock_departures}
      end

      assert [
               %DeparturesWidget{
                 screen: ^config,
                 sections: [
                   %NormalSection{rows: ^mock_departures}
                 ]
               }
             ] =
               departures_candidate(
                 config,
                 %QueryParams{route_id: route_id, stop_id: stop_id},
                 mock_fetch_fn
               )
    end

    test "returns DeparturesNoData section when fetch fails" do
      route_id = "86"
      stop_id = "100"
      mock_fetch_fn = fn _, _ -> :error end
      config = build_config()

      assert departures_candidate(
               config,
               %QueryParams{route_id: route_id, stop_id: stop_id},
               mock_fetch_fn
             ) ==
               [
                 %DeparturesNoData{screen: config}
               ]
    end

    test "filters out departures for the current route_id" do
      config = build_config()
      route_id = "86"
      stop_id = "22549"

      connecting_routes = ~w[100 12345 22549]

      stub(@stop, :fetch_connecting, fn _ ->
        {:ok, build_stops(connecting_routes)}
      end)

      mock_departures = [
        build_departure("66", 0),
        build_departure("109", 0)
      ]

      # 86 prediction scheduled for 1 minute earlier
      mock_departures_on_route = [
        build_departure("86", 0, :bus, ~U[2024-01-01 11:59:00Z])
      ]

      mock_fetch_fn = fn %{stop_ids: ^connecting_routes}, [include_schedules: false] ->
        {:ok, mock_departures ++ mock_departures_on_route}
      end

      assert [
               %DeparturesWidget{
                 screen: ^config,
                 sections: [
                   %NormalSection{rows: ^mock_departures}
                 ]
               }
             ] =
               departures_candidate(
                 config,
                 %QueryParams{route_id: route_id, stop_id: stop_id},
                 mock_fetch_fn
               )
    end

    test "returns DeparturesNoService section when fetch finds no departures" do
      route_id = "86"
      stop_id = "100"
      mock_fetch_fn = fn _, _ -> {:ok, []} end
      config = build_config()

      assert departures_candidate(
               config,
               %QueryParams{route_id: route_id, stop_id: stop_id},
               mock_fetch_fn
             ) ==
               [
                 %DeparturesNoService{screen: config}
               ]
    end
  end
end
