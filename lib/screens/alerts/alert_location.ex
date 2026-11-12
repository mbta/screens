defmodule Screens.Alerts.AlertLocation do
  @moduledoc """
  Helper for calculating the location of an Alert in the context of a
  Screen at a specific stop and potentially serving specific destinations/routes.

  Takes in either the old LocationContext, or takes in a single RoutePattern along with
  extra information to calculate the AlertLocation Context and then make a calculation on
  the location of the Alert relative to the provided stop. 
  """
  alias Screens.Alerts.{Alert, InformedEntity}
  alias Screens.LocationContext
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.Util
  alias ScreensConfig.Departures.Mode

  @type zone :: :upstream | :home_stop | :downstream

  @type t ::
          :boundary_downstream
          | :boundary_upstream
          | :downstream
          | :elsewhere
          | :inside
          | :upstream

  defmodule Context do
    @moduledoc """
    The information describing the current location created by passing in either the old LocationContext
    or the RoutePattern along with some extra information. Used to calculate the location of the Alert
    associated with the Context
    """
    @enforce_keys [:home_stop_id]
    defstruct home_stop_id: "",
              alert_route_types: [],
              direction_id: nil,
              downstream_stops: MapSet.new(),
              upstream_stops: MapSet.new(),
              route_ids: [],
              is_terminal_station: false

    @type t :: %__MODULE__{
            home_stop_id: String.t(),
            alert_route_types: [RouteType.t()],
            direction_id: Trip.direction() | nil,
            downstream_stops: MapSet.t(),
            upstream_stops: MapSet.t(),
            route_ids: [Route.id()],
            is_terminal_station: boolean()
          }
  end

  @spec location_from_context(Alert.t(), LocationContext.t(), boolean()) :: t()
  def location_from_context(alert, location_context, is_terminal_station) do
    location(
      alert,
      %Context{
        alert_route_types: location_context.alert_route_types,
        home_stop_id: location_context.home_stop,
        downstream_stops: location_context.downstream_stops,
        upstream_stops: location_context.upstream_stops,
        route_ids: location_context.routes |> Enum.map(& &1.route_id),
        is_terminal_station: is_terminal_station
      }
    )
  end

  @spec location_from_route_pattern(Alert.t(), RoutePattern.t(), Stop.t(), Mode.t()) :: t()
  def location_from_route_pattern(
        alert,
        %RoutePattern{route: %Route{id: id}, stops: stops, direction_id: direction_id},
        %Stop{id: home_stop_id},
        mode
      ) do
    stop_sequences = [Enum.map(stops, & &1.id)]

    location(
      alert,
      %Context{
        home_stop_id: home_stop_id,
        alert_route_types: [Mode.to_route_type(mode)],
        direction_id: direction_id,
        downstream_stops: downstream_stop_id_set([home_stop_id], stop_sequences),
        upstream_stops: upstream_stop_id_set([home_stop_id], stop_sequences),
        route_ids: [id],
        is_terminal_station: terminal?(home_stop_id, stop_sequences)
      }
    )
  end

  defp location(
         %Alert{effect: effect, informed_entities: informed_entities},
         %Context{
           is_terminal_station: is_terminal_station
         } = alert_location_context
       ) do
    informed_entities
    |> Enum.flat_map(&informed_entity_to_zone(&1, alert_location_context))
    |> Enum.uniq()
    |> Enum.sort()
    |> get_location_atom(effect, is_terminal_station)
  end

  @spec upstream_stop_id_set([Stop.id()], [[Stop.id()]]) :: MapSet.t(Stop.id())
  def upstream_stop_id_set(stop_ids, stop_sequences),
    do: sliced_stop_id_set(stop_ids, stop_sequences, &Util.slice_before/2)

  @spec downstream_stop_id_set([Stop.id()], [[Stop.id()]]) :: MapSet.t(Stop.id())
  def downstream_stop_id_set(stop_ids, stop_sequences),
    do: sliced_stop_id_set(stop_ids, stop_sequences, &Util.slice_after/2)

  defp sliced_stop_id_set(stop_ids, stop_sequences, slice_fn) do
    stop_ids
    |> Enum.flat_map(fn stop_id ->
      Enum.flat_map(stop_sequences, fn stop_sequence -> slice_fn.(stop_sequence, stop_id) end)
    end)
    |> MapSet.new()
  end

  @spec informed_entity_to_zone(InformedEntity.t(), Context.t()) :: list(zone())
  # All values nil
  defp informed_entity_to_zone(
         %InformedEntity{stop: nil, route: nil, route_type: nil},
         _alert_location_context
       ) do
    []
  end

  # Directions are opposite
  defp informed_entity_to_zone(
         %InformedEntity{direction_id: direction_id},
         %Context{direction_id: alert_direction_id}
       )
       when direction_id == 1 - alert_direction_id do
    []
  end

  # Only route type is not nil--this is the only time we consider route type,
  # since it's implied by other values when they are not nil
  defp informed_entity_to_zone(
         %InformedEntity{stop: nil, route: nil, route_type: route_type_id},
         %Context{alert_route_types: alert_route_types}
       ) do
    if RouteType.from_id(route_type_id) in alert_route_types do
      [:upstream, :home_stop, :downstream]
    else
      []
    end
  end

  # Only stop is not nil (route type ignored)
  defp informed_entity_to_zone(
         %InformedEntity{stop: %Stop{id: stop_id}, route: nil},
         %Context{
           home_stop_id: home_stop_id,
           downstream_stops: downstream_stops,
           upstream_stops: upstream_stops
         }
       )
       when not is_nil(stop_id) do
    cond do
      stop_id == home_stop_id -> [:home_stop]
      # Stops can be both upstream and downstream simultaneously, on different routes through the home stop.
      # We check whether it's downstream first, since that takes priority.
      stop_id in downstream_stops -> [:downstream]
      stop_id in upstream_stops -> [:upstream]
      true -> []
    end
  end

  # Only route is not nil (route type ignored)
  defp informed_entity_to_zone(
         %InformedEntity{stop: nil, route: %Route{id: route_id}},
         %Context{route_ids: route_ids}
       ) do
    if route_id in route_ids, do: [:upstream, :home_stop, :downstream], else: []
  end

  # Both stop and route are not nil (route type ignored)
  defp informed_entity_to_zone(
         %InformedEntity{stop: stop, route: route} = informed_entity,
         %Context{route_ids: route_ids} = alert_location_context
       )
       when not is_nil(stop) and not is_nil(route) do
    if route.id in route_ids do
      informed_entity_to_zone(%{informed_entity | route: nil}, alert_location_context)
    else
      []
    end
  end

  defp get_location_atom(informed_zones_set, _, _) when informed_zones_set == [:upstream],
    do: :upstream

  defp get_location_atom(informed_zones_set, _, _) when informed_zones_set == [:downstream],
    do: :downstream

  defp get_location_atom(informed_zones_set, _, _) when informed_zones_set == [:home_stop],
    do: :inside

  defp get_location_atom(informed_zones_set, _, _)
       when informed_zones_set == [:downstream, :home_stop, :upstream],
       do: :inside

  # If station closure, then a boundary_upstream / _downstream is actually :inside
  defp get_location_atom(informed_zones_set, effect, _)
       when informed_zones_set == [:home_stop, :upstream] and effect === :station_closure,
       do: :inside

  defp get_location_atom(informed_zones_set, effect, _)
       when informed_zones_set == [:downstream, :home_stop] and effect === :station_closure,
       do: :inside

  defp get_location_atom(informed_zones_set, effect, true)
       when informed_zones_set in [[:home_stop, :upstream], [:downstream, :home_stop]] and
              effect in [:suspension, :shuttle],
       do: :inside

  defp get_location_atom(informed_zones_set, _, _)
       when informed_zones_set == [:home_stop, :upstream],
       do: :boundary_upstream

  defp get_location_atom(informed_zones_set, _, _)
       when informed_zones_set == [:downstream, :home_stop],
       do: :boundary_downstream

  defp get_location_atom(informed_zones_set, _, _)
       when informed_zones_set == [:downstream, :upstream],
       do: :downstream

  defp get_location_atom(_, _, _), do: :elsewhere

  def terminal?(stop_id, stop_sequences) do
    # Can't use Enum.any, because then Govt Center will be seen as a terminal
    # Using all is ok because no station is the terminal of one line and NOT the terminal of another line
    # excluding GL branches
    Enum.all?(stop_sequences, fn stop_sequence ->
      List.first(stop_sequence) == stop_id or List.last(stop_sequence) == stop_id
    end)
  end
end
