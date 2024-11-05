defmodule Screens.V2.CandidateGenerator.Widgets.ElevatorClosures do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.ElevatorStatus, as: ElevatorStatusWidget
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.{ElevatorStatus, PreFare}

  def elevator_status_instances(
        %Screen{
          app_params: %PreFare{
            elevator_status: %ElevatorStatus{parent_station_id: parent_station_id}
          }
        } = config,
        now \\ DateTime.utc_now(),
        fetch_location_context_fn \\ &LocationContext.fetch/3,
        fetch_elevator_alerts_with_facilities_fn \\ &Alert.fetch_elevator_alerts_with_facilities/0
      ) do
    with {:ok, location_context} <- fetch_location_context_fn.(PreFare, parent_station_id, now),
         {:ok, parent_station_map} <- Stop.fetch_parent_station_name_map(),
         {:ok, alerts} <- fetch_elevator_alerts_with_facilities_fn.() do
      elevator_closures = relevant_alerts(alerts)
      icon_map = get_icon_map(elevator_closures, parent_station_id)

      [
        %ElevatorStatusWidget{
          alerts: elevator_closures,
          location_context: location_context,
          screen: config,
          now: now,
          station_id_to_name: parent_station_map,
          station_id_to_icons: icon_map
        }
      ]
    else
      :error -> []
    end
  end

  defp relevant_alerts(alerts) do
    Enum.filter(alerts, fn
      %Alert{effect: :elevator_closure} = alert -> alert
      _ -> false
    end)
  end

  defp get_icon_map(elevator_closures, home_parent_station_id) do
    elevator_closures
    |> get_parent_station_ids_from_entities()
    |> MapSet.new()
    |> MapSet.put(home_parent_station_id)
    |> Enum.map(fn station_id ->
      {station_id, station_id |> routes_serving_stop() |> routes_to_icons()}
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

  defp routes_serving_stop(stop_id) do
    case Route.fetch(%{stop_id: stop_id}) do
      {:ok, routes} -> routes
      :error -> []
    end
  end

  defp routes_to_icons(routes) do
    routes
    |> Enum.map(fn
      %Screens.Routes.Route{type: :subway, id: id} -> id |> String.downcase() |> String.to_atom()
      %Screens.Routes.Route{type: :light_rail, id: "Green-" <> _} -> :green
      %Screens.Routes.Route{type: :light_rail, id: "Mattapan" <> _} -> :mattapan
      %Screens.Routes.Route{type: :bus, short_name: "SL" <> _} -> :silver
      %Screens.Routes.Route{type: type} -> type
    end)
    |> Enum.uniq()
  end
end
