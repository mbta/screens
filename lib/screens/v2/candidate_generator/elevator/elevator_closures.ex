defmodule Screens.V2.CandidateGenerator.Elevator.ElevatorClosures do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Facilities.Facility
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.ElevatorClosures
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Elevator

  def elevator_status_instances(
        %Screen{
          app_params: %Elevator{
            elevator_id: elevator_id
          }
        } = config,
        now \\ DateTime.utc_now(),
        fetch_stop_for_facility_fn \\ &Facility.fetch_stop_for_facility/1,
        fetch_location_context_fn \\ &Stop.fetch_location_context/3,
        fetch_elevator_alerts_with_facilities_fn \\ &Alert.fetch_elevator_alerts_with_facilities/0
      ) do
    with {:ok, %Stop{id: stop_id}} <- fetch_stop_for_facility_fn.(elevator_id),
         {:ok, location_context} <- fetch_location_context_fn.(Elevator, stop_id, now),
         {:ok, parent_station_map} <- Stop.fetch_parent_station_name_map(),
         {:ok, alerts} <- fetch_elevator_alerts_with_facilities_fn.() do
      elevator_closures = relevant_alerts(alerts)
      routes_map = get_routes_map(elevator_closures, stop_id)

      [
        %ElevatorClosures{
          alerts: elevator_closures,
          location_context: location_context,
          screen: config,
          now: now,
          station_id_to_name: parent_station_map,
          station_id_to_routes: routes_map
        }
      ]
    else
      :error -> []
    end
  end

  defp relevant_alerts(alerts) do
    Enum.filter(alerts, &(&1.effect == :elevator_closure))
  end

  defp get_routes_map(elevator_closures, home_parent_station_id) do
    elevator_closures
    |> get_parent_station_ids_from_entities()
    |> MapSet.new()
    |> MapSet.put(home_parent_station_id)
    |> Enum.map(fn station_id ->
      {station_id, route_ids_serving_stop(station_id)}
    end)
    |> Enum.into(%{})
  end

  defp get_parent_station_ids_from_entities(alerts) do
    alerts
    |> Enum.flat_map(fn %Alert{informed_entities: informed_entities} ->
      informed_entities
      |> Enum.map(fn %{stop: stop_id} -> stop_id end)
      |> Enum.filter(&String.starts_with?(&1, "place-"))
    end)
  end

  defp route_ids_serving_stop(stop_id) do
    case Route.fetch(%{stop_id: stop_id}) do
      {:ok, routes} -> Enum.map(routes, & &1.id)
      # Show no route pills instead of crashing the screen
      :error -> []
    end
  end
end
