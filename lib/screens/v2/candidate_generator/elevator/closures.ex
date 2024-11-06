defmodule Screens.V2.CandidateGenerator.Elevator.Closures do
  @moduledoc false

  require Logger

  alias Screens.Alerts.{Alert, InformedEntity}
  alias Screens.Facilities.Facility
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.LocationContext
  alias Screens.V2.WidgetInstance.ElevatorClosures
  alias Screens.V2.WidgetInstance.Serializer.RoutePill
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Elevator

  @stop Application.compile_env(:screens, [__MODULE__, :stop_module], Stop)
  @location_context Application.compile_env(
                      :screens,
                      [__MODULE__, :location_context_module],
                      LocationContext
                    )
  @facility Application.compile_env(:screens, [__MODULE__, :facility_module], Facility)
  @alert Application.compile_env(:screens, [__MODULE__, :alert_module], Alert)
  @route Application.compile_env(:screens, [__MODULE__, :route_module], Route)

  @spec elevator_status_instances(Screen.t()) :: list(ElevatorClosures.t())
  @spec elevator_status_instances(Screen.t(), DateTime.t()) :: list(ElevatorClosures.t())
  def elevator_status_instances(
        %Screen{
          app_params: %Elevator{
            elevator_id: elevator_id
          }
        },
        now \\ DateTime.utc_now()
      ) do
    with {:ok, %Stop{id: stop_id}} <- @facility.fetch_stop_for_facility(elevator_id),
         {:ok, location_context} <- @location_context.fetch(Elevator, stop_id, now),
         {:ok, parent_station_map} <- @stop.fetch_parent_station_name_map(),
         {:ok, alerts} <- @alert.fetch_elevator_alerts_with_facilities() do
      elevator_closures = relevant_alerts(alerts)
      routes_map = get_routes_map(elevator_closures, stop_id)

      {in_station_alerts, outside_alerts} =
        split_alerts_by_location(elevator_closures, location_context)

      [
        %ElevatorClosures{
          id: elevator_id,
          in_station_alerts: Enum.map(in_station_alerts, &alert_to_elevator_closure/1),
          other_stations_with_alerts:
            format_outside_alerts(outside_alerts, parent_station_map, routes_map)
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
      {station_id, station_id |> route_ids_serving_stop() |> routes_to_labels()}
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
      {:ok, routes} -> routes
      # Show no route pills instead of crashing the screen
      :error -> []
    end
  end

  defp routes_to_labels(routes) do
    routes
    |> Enum.map(fn
      %Route{type: :subway, id: id} -> id |> String.downcase() |> String.to_atom()
      %Route{type: :light_rail, id: "Green-" <> _} -> :green
      %Route{type: :light_rail, id: "Mattapan" <> _} -> :mattapan
      %Route{type: :bus, short_name: "SL" <> _} -> :silver
      %Route{type: :rail} -> :cr
      %Route{type: type} -> type
    end)
    |> Enum.uniq()
  end

  defp split_alerts_by_location(alerts, location_context) do
    Enum.split_with(alerts, fn %Alert{informed_entities: informed_entities} ->
      location_context.home_stop in Enum.map(informed_entities, & &1.stop)
    end)
  end

  defp get_informed_facility(entities) do
    entities
    |> Enum.find_value(fn
      %{facility: facility} -> facility
      _ -> false
    end)
  end

  defp alert_to_elevator_closure(%Alert{
         id: id,
         informed_entities: entities,
         description: description,
         header: header
       }) do
    facility = get_informed_facility(entities)

    %{
      id: id,
      elevator_name: facility.name,
      elevator_id: facility.id,
      description: description,
      header_text: header
    }
  end

  defp format_outside_alerts(alerts, station_id_to_name, station_id_to_routes) do
    alerts
    |> Enum.group_by(&get_parent_station_id_from_informed_entities(&1.informed_entities))
    |> Enum.map(fn {parent_station_id, alerts} ->
      alerts_at_station = Enum.map(alerts, &alert_to_elevator_closure/1)

      route_pills =
        station_id_to_routes
        |> Map.fetch!(parent_station_id)
        |> Enum.map(&RoutePill.serialize_icon/1)

      %{
        id: parent_station_id,
        name: Map.fetch!(station_id_to_name, parent_station_id),
        routes: route_pills,
        alerts: alerts_at_station
      }
    end)
  end

  defp get_parent_station_id_from_informed_entities(entities) do
    entities
    |> Enum.find_value(fn
      ie -> if InformedEntity.parent_station?(ie), do: ie.stop
    end)
  end
end
