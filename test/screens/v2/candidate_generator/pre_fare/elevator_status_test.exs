defmodule Screens.V2.CandidateGenerator.PreFare.ElevatorStatusTest do
  use ExUnit.Case, async: true

  alias Screens.Alerts.Alert
  alias Screens.Elevator
  alias Screens.Elevator.Closure
  alias Screens.Facilities.Facility
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.CandidateGenerator.PreFare.ElevatorStatus
  alias Screens.V2.WidgetInstance.ElevatorStatus, as: ElevatorWidget
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.PreFare

  import Mox
  setup :verify_on_exit!

  import Screens.Inject
  @alert injected(Alert)
  @elevator injected(Elevator)
  @route_pattern injected(RoutePattern)

  @screen %Screen{
    app_id: :pre_fare_v2,
    app_params: %PreFare{
      header: nil,
      reconstructed_alert_widget: nil,
      elevator_status: %ScreensConfig.ElevatorStatus{
        parent_station_id: "place-here",
        platform_stop_ids: []
      },
      full_line_map: nil,
      content_summary: nil
    },
    device_id: nil,
    name: nil,
    vendor: nil
  }

  test "generates the elevator status widget" do
    facility = %Facility{
      id: "111",
      long_name: "long",
      short_name: "short",
      stop: :unloaded,
      type: :elevator
    }

    alert = %Alert{
      active_period: [{~U[2025-01-01T00:00:00Z], nil}],
      effect: :elevator_closure,
      informed_entities: [%{facility: facility}]
    }

    elevator = %Elevator{
      id: "111",
      alternate_ids: [],
      exiting_summary: "",
      redundancy: :other,
      summary: nil
    }

    expect(@alert, :fetch, fn [activities: [:using_wheelchair], include_all?: true] ->
      {:ok, [alert]}
    end)

    expect(@elevator, :get, fn "111" -> elevator end)

    expect(@route_pattern, :fetch, fn %{canonical?: true, stop_ids: ~w[place-here]} ->
      {:ok,
       [
         %RoutePattern{
           route: %Route{type: :subway},
           stops: [
             %Stop{id: "s1", parent_station: %Stop{id: "place-1"}},
             %Stop{id: "s2", parent_station: %Stop{id: "place-2"}},
             %Stop{id: "s3"}
           ]
         },
         %RoutePattern{
           route: %Route{type: :bus},
           stops: [%Stop{id: "s4", parent_station: %Stop{id: "place-3"}}]
         }
       ]}
    end)

    assert ElevatorStatus.instances(@screen, DateTime.utc_now()) ==
             [
               %ElevatorWidget{
                 closures: [%Closure{alert: alert, elevator: elevator, facility: facility}],
                 home_station_id: "place-here",
                 relevant_station_ids: MapSet.new(~w[place-1 place-2])
               }
             ]
  end
end
