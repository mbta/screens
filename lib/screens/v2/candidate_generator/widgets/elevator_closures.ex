defmodule Screens.V2.CandidateGenerator.Widgets.ElevatorClosures do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{ElevatorStatus, PreFare}
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.ElevatorStatus, as: ElevatorStatusWidget

  @behaviour Screens.V2.AlertsCandidateGeneratorBehaviour

  def elevator_status_instances(
        %Screen{
          app_params: %PreFare{
            elevator_status: %ElevatorStatus{parent_station_id: parent_station_id}
          }
        } = config,
        now \\ DateTime.utc_now(),
        fetch_with_facilities_fn \\ &Alert.fetch_with_facilities/1
      ) do
    with {:ok, routes_at_stop} <-
           Route.fetch_routes_by_stop(parent_station_id, now, [:light_rail, :subway]),
         route_ids_at_stop = Enum.map(routes_at_stop, & &1.route_id),
         {:ok, stop_sequences} <-
           RoutePattern.fetch_parent_station_sequences_through_stop(
             parent_station_id,
             route_ids_at_stop
           ),
         {:ok, parent_station_map} <- Stop.fetch_parent_station_name_map(),
         {:ok, alerts} <-
           fetch([activity: "USING_WHEELCHAIR"], fetch_with_facilities_fn) do
      elevator_closures = relevant_alerts(alerts, config)
      icon_map = get_icon_map(elevator_closures, parent_station_id)

      [
        %ElevatorStatusWidget{
          alerts: elevator_closures,
          stop_sequences: stop_sequences,
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

  @impl true
  def fetch(opts, fetch_fn), do: fetch_fn.(opts)

  @impl true
  def relevant_alerts(alerts, _config, _opts \\ []) do
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
      {station_id, station_id |> Stop.create_station_with_routes_map() |> routes_to_icons()}
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
