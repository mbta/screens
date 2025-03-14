defmodule Screens.V2.CandidateGenerator.Widgets.OnBus.DeparturesTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance.DeparturesNoData
  alias Screens.V2.WidgetInstance.Departures.NormalSection
  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Trips.Trip
  alias Screens.V2.CandidateGenerator.Widgets.OnBus.Departures
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.Departures, as: DeparturesWidget
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.OnBus

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

  defp departures_candidate(config, route_id, stop_id, options) do
    Departures.departures_candidate(
      config,
      route_id,
      stop_id,
      Keyword.merge(
        [
          departure_fetch_fn: fn _, _ -> :error end
        ],
        options
      )
    )
  end

  describe "departures_candidate/4" do
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
               departures_candidate(config, route_id, stop_id, departure_fetch_fn: mock_fetch_fn)
    end

    test "returns DeparturesNoData section when fetch fails" do
      route_id = "86"
      stop_id = "100"
      mock_fetch_fn = fn _, _ -> {:error, :service_down} end
      config = build_config()

      assert departures_candidate(config, route_id, stop_id, departure_fetch_fn: mock_fetch_fn) ==
               [
                 %DeparturesNoData{screen: config, show_alternatives?: true}
               ]
    end

    test "filters out departures for the current route_id" do
      config = build_config()
      route_id = "86"
      stop_id = "22549"

      mock_departures = [
        build_departure("66", 0),
        build_departure("109", 0)
      ]

      # 86 prediction scheduled for 1 minute earlier
      mock_departures_on_route = [
        build_departure("86", 0, :bus, ~U[2024-01-01 11:59:00Z])
      ]

      mock_fetch_fn = fn %{stop_ids: [^stop_id]}, [include_schedules: false] ->
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
               departures_candidate(config, route_id, stop_id, departure_fetch_fn: mock_fetch_fn)
    end
  end
end
