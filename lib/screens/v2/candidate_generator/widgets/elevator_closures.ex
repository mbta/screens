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
  @route injected(Route)
  @stop injected(Stop)

  defmodule Closure do
    @moduledoc false
    # Internal struct used while generating widgets. Represents a single elevator which is closed.

    @type t :: %__MODULE__{
            id: Facility.id(),
            alert_id: String.t(),
            elevator: Elevator.t() | nil,
            station_id: Stop.id()
          }

    @enforce_keys ~w[id alert_id elevator station_id]a
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
         {:ok, parent_station_map} <- @stop.fetch_parent_station_name_map(),
         {:ok, alerts} <- fetch_elevator_alerts_with_facilities_fn.() do
      elevator_closures =
        alerts
        |> elevator_alerts()
        |> Enum.flat_map(&closure_details/1)

      elevator_closure_ids =
        elevator_closures
        |> Enum.filter(&relevant_closure?(&1, elevator_closures, parent_station_id))
        |> Enum.map(fn %{alert_id: alert_id} -> alert_id end)
        |> MapSet.new()

      [
        %ElevatorStatusWidget{
          alerts:
            alerts
            |> Enum.filter(fn %Alert{id: id} -> id in elevator_closure_ids end),
          location_context: location_context,
          screen: config,
          now: now,
          station_id_to_name: parent_station_map,
          station_id_to_icons: get_icon_map(elevator_closures, parent_station_id)
        }
      ]
    else
      :error -> []
    end
  end

  defp elevator_alerts(alerts) do
    Enum.filter(alerts, fn
      %Alert{effect: :elevator_closure} = alert -> alert
      _ -> false
    end)
  end

  defp get_icon_map(elevator_closures, home_parent_station_id) do
    elevator_closures
    |> Enum.map(fn %Closure{station_id: station_id} -> station_id end)
    |> MapSet.new()
    |> MapSet.put(home_parent_station_id)
    |> Enum.map(fn station_id ->
      {station_id, station_id |> routes_serving_stop() |> routes_to_icons()}
    end)
    |> Enum.into(%{})
  end

  defp routes_serving_stop(stop_id) do
    case @route.fetch(%{stop_id: stop_id}) do
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

  defp closure_details(%Alert{
         id: alert_id,
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

      [{station_id, %{id: id}}] ->
        [
          %Closure{
            id: id,
            alert_id: alert_id,
            station_id: station_id,
            elevator: @elevator.get(id)
          }
        ]

      _multiple ->
        Report.warning("elevator_closure_affects_multiple", alert_id: alert_id)
        []
    end
  end

  # If we couldn't find alternate/redundancy data for an elevator, assume it's relevant.
  defp relevant_closure?(%{elevator: nil}, _closures, _parent_station_id), do: true

  # If any of a closed elevator's alternates are also closed, it's always relevant.
  defp relevant_closure?(
         %Closure{
           station_id: station_id,
           elevator: %Elevator{alternate_ids: alternate_ids, exiting_redundancy: redundancy}
         },
         closures,
         parent_station_id
       ) do
    Enum.any?(closures, fn %{id: id} -> id in alternate_ids end) or redundancy != :nearby or
      station_id == parent_station_id
  end
end
