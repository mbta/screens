defmodule Screens.V2.CandidateGenerator.Widgets.ElevatorClosures do
  @moduledoc false

  alias Screens.Alerts.{Alert, InformedEntity}
  alias Screens.Elevator
  alias Screens.Facilities.Facility
  alias Screens.LocationContext
  alias Screens.Report
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.ElevatorStatus, as: ElevatorStatusWidget
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.{ElevatorStatus, PreFare}

  import Screens.Inject

  @elevator injected(Elevator)

  defmodule Closure do
    @moduledoc false
    # Internal struct used while generating widgets. Represents a single elevator which is closed.

    @type t :: %__MODULE__{
            id: Facility.id(),
            alert_id: String.t(),
            name: String.t(),
            station_id: Stop.id(),
            periods: [Alert.active_period()],
            elevator: Elevator.t() | nil
          }

    @enforce_keys ~w[id alert_id name station_id periods elevator]a
    defstruct @enforce_keys
  end

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
      elevator_alerts = relevant_alerts(alerts)

      icon_map = get_icon_map(elevator_alerts, parent_station_id)

      elevator_closures =
        elevator_alerts
        |> Enum.flat_map(&elevator_closure/1)

      elevator_closure_ids =
        elevator_closures
        |> Enum.filter(&relevant_closure?(&1, elevator_closures))
        |> Enum.map(fn %Closure{alert_id: alert_id} -> alert_id end)

      [
        %ElevatorStatusWidget{
          alerts:
            elevator_alerts
            |> Enum.filter(fn %Alert{id: id} -> id in elevator_closure_ids end),
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

  defp elevator_closure(%Alert{
         id: alert_id,
         active_period: active_periods,
         effect: :elevator_closure,
         informed_entities: entities
       }) do
    # We expect there is a 1:1 relationship between `elevator_closure` alerts and individual
    # out-of-service elevators. Log a warning if our assumptions don't hold.
    stations_and_facilities =
      entities
      |> Enum.filter(&(InformedEntity.parent_station?(&1) and not is_nil(&1.facility)))
      |> Enum.map(fn %{facility: facility, stop: station_id} -> {station_id, facility} end)
      |> Enum.uniq()

    case stations_and_facilities do
      [] ->
        []

      [{station_id, %{id: id, name: name}}] ->
        [
          %Closure{
            id: id,
            alert_id: alert_id,
            name: name,
            station_id: station_id,
            periods: active_periods,
            elevator: @elevator.get(id)
          }
        ]

      _multiple ->
        Report.warning("elevator_closure_affects_multiple", alert_id: alert_id)
        []
    end
  end

  # If we couldn't find alternate/redundancy data for an elevator, assume it's relevant.
  defp relevant_closure?(%Closure{elevator: nil}, _closures), do: true

  # If any of a closed elevator's alternates are also closed, it's always relevant.
  defp relevant_closure?(
         %Closure{
           elevator: %Elevator{alternate_ids: alternate_ids, exiting_redundancy: redundancy}
         },
         closures
       ) do
    Enum.any?(closures, fn %Closure{id: id} -> id in alternate_ids end) or redundancy != :nearby
  end
end
