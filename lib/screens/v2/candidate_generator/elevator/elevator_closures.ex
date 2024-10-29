defmodule Screens.V2.CandidateGenerator.Elevator.ElevatorClosures do
  @moduledoc false

  require Logger

  alias Screens.Alerts.Alert
  alias Screens.Facilities.Facility
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.ElevatorClosures
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Elevator

  @stop Application.compile_env(:screens, [__MODULE__, :stop_module], Stop)
  @facility Application.compile_env(:screens, [__MODULE__, :facility_module], Facility)
  @alert Application.compile_env(:screens, [__MODULE__, :alert_module], Alert)
  @route Application.compile_env(:screens, [__MODULE__, :route_module], Route)

  def elevator_status_instances(
        %Screen{
          app_params: %Elevator{
            elevator_id: elevator_id
          }
        } = config,
        now \\ DateTime.utc_now()
      ) do
    with {:ok, %Stop{id: stop_id}} <- @facility.fetch_stop_for_facility(elevator_id),
         {:ok, location_context} <- @stop.fetch_location_context(Elevator, stop_id, now),
         {:ok, parent_station_map} <- @stop.fetch_parent_station_name_map(),
         {:ok, alerts} <- @alert.fetch_elevator_alerts_with_facilities() do
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
      :error ->
        []

      {:error, error} ->
        Logger.error("[elevator_status_instances] #{inspect(error)}")
        []
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
    case @route.fetch(%{stop_id: stop_id}) do
      {:ok, routes} -> Enum.map(routes, & &1.id)
      # Show no route pills instead of crashing the screen
      :error -> []
    end
  end
end
