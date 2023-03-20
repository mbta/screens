defmodule Screens.V2.WidgetInstance.Common.BaseAlert do
  @moduledoc """
  Common logic for structs that implement the `Screens.V2.SingleAlertWidget` protocol.

  ***
  None of the code in this module should access struct fields directly.

  In order to maintain clarity on what values these functions require,
  use only callbacks from `Screens.V2.SingleAlertWidget` to interact with inputs.
  If new values are required, add new callbacks to the protocol and update implementing modules accordingly.
  ***
  """

  alias Screens.Alerts.Alert
  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Util

  alias Screens.V2.SingleAlertWidget, as: SAW

  @type t :: SAW.t()

  @type stop_id :: String.t()

  @type route_id :: String.t()

  @spec upstream_stop_id_set(t()) :: MapSet.t(stop_id())
  def upstream_stop_id_set(t) do
    home_stop_id = SAW.home_stop_id(t)

    t
    |> SAW.stop_sequences()
    |> Enum.flat_map(fn stop_sequence -> Util.slice_before(stop_sequence, home_stop_id) end)
    |> MapSet.new()
  end

  @spec downstream_stop_id_set(t()) :: MapSet.t(stop_id())
  defp downstream_stop_id_set(t) do
    home_stop_id = SAW.home_stop_id(t)

    t
    |> SAW.stop_sequences()
    |> Enum.flat_map(fn stop_sequence -> Util.slice_after(stop_sequence, home_stop_id) end)
    |> MapSet.new()
  end

  @typedoc """
  A headsign indicating the direction a vehicle is headed in.

  In rare cases, an adjective form is used, e.g. "westbound".
  For these cases, the headsign is wrapped in a tagged `{:adj, headsign}` tuple
  to indicate that the headsign may need to be rendered differently.

  See the `*_headsign_matchers` values in config.exs for examples.
  """
  @type headsign :: String.t() | {:adj, String.t()}

  @doc """
  Determines the headsign of the affected direction of an alert using
  stop IDs in its informed entities.

  Returns nil if either of the following is true:
  - the home stop is not on the boundary of the alert's affected region.
  - the widget does not have a map of headsign matchers (`SingleAlertWidget.headsign_matchers(t)` returns nil)
  """
  @spec get_headsign_from_informed_entities(t()) :: headsign | nil
  def get_headsign_from_informed_entities(t) do
    with headsign_matchers when is_map(headsign_matchers) <- SAW.headsign_matchers(t) do
      informed_stop_ids = MapSet.new(informed_entities(t), & &1.stop)

      headsign_matchers
      |> Map.get(SAW.home_stop_id(t))
      |> Enum.find_value(fn {informed, not_informed, headsign} ->
        if alert_region_match?(
             Util.to_set(informed),
             Util.to_set(not_informed),
             informed_stop_ids
           ),
           do: headsign,
           else: false
      end)
    end
  end

  defp alert_region_match?(informed, not_informed, informed_stop_ids) do
    MapSet.subset?(informed, informed_stop_ids) and
      MapSet.disjoint?(not_informed, informed_stop_ids)
  end

  defp all_routes_at_stop(t) do
    t
    |> SAW.routes_at_stop()
    |> MapSet.new(& &1.route_id)
  end

  defp route_types(t) do
    case SAW.screen(t).app_id do
      :bus_shelter_v2 ->
        [:bus]

      :bus_eink_v2 ->
        [:bus]

      :gl_eink_v2 ->
        [:light_rail]

      multi_route_type_app when multi_route_type_app in [:pre_fare_v2, :dup_v2] ->
        t
        |> SAW.routes_at_stop()
        |> Enum.map(& &1.type)
        |> Enum.uniq()
    end
  end

  @spec informed_entities(t()) :: list(Alert.informed_entity())
  def informed_entities(t) do
    SAW.alert(t).informed_entities
  end

  @spec informed_entity_to_zone(Alert.informed_entity(), map()) ::
          list(:upstream | :home_stop | :downstream)
  defp informed_entity_to_zone(informed_entity, location_context)

  # All values nil
  defp informed_entity_to_zone(%{stop: nil, route: nil, route_type: nil}, _location_context) do
    []
  end

  # Only route type is not nil--this is the only time we consider route type,
  # since it's implied by other values when they are not nil
  defp informed_entity_to_zone(%{stop: nil, route: nil, route_type: route_type_id}, %{
         route_types: route_types
       }) do
    if RouteType.from_id(route_type_id) in route_types do
      [:upstream, :home_stop, :downstream]
    else
      []
    end
  end

  # Only stop is not nil (route type ignored)
  defp informed_entity_to_zone(%{stop: stop, route: nil}, context) do
    cond do
      stop == context.home_stop -> [:home_stop]
      # Stops can be both upstream and downstream simultaneously, on different routes through the home stop.
      # We check whether it's downstream first, since that takes priority.
      stop in context.downstream_stops -> [:downstream]
      stop in context.upstream_stops -> [:upstream]
      true -> []
    end
  end

  # Only route is not nil (route type ignored)
  defp informed_entity_to_zone(%{stop: nil, route: route}, context) do
    if route in context.routes, do: [:upstream, :home_stop, :downstream], else: []
  end

  # Both stop and route are not nil (route type ignored)
  defp informed_entity_to_zone(%{stop: _stop, route: route} = informed_entity, context) do
    if route in context.routes do
      informed_entity_to_zone(%{informed_entity | route: nil}, context)
    else
      []
    end
  end

  @spec location(t()) ::
          :boundary_downstream
          | :boundary_upstream
          | :downstream
          | :elsewhere
          | :inside
          | :upstream
  def location(%{} = t, is_terminal_station \\ false) do
    location_context = %{
      home_stop: SAW.home_stop_id(t),
      upstream_stops: upstream_stop_id_set(t),
      downstream_stops: downstream_stop_id_set(t),
      routes: all_routes_at_stop(t),
      route_types: route_types(t)
    }

    informed_entities = informed_entities(t)

    informed_zones_set =
      informed_entities
      |> Enum.flat_map(&informed_entity_to_zone(&1, location_context))
      |> Enum.uniq()
      |> Enum.sort()

    get_location_atom(informed_zones_set, SAW.alert(t).effect, is_terminal_station)
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

  def informs_all_active_routes_at_home_stop?(t) do
    MapSet.subset?(active_routes_at_stop(t), informed_routes_at_home_stop(t))
  end

  @spec active_routes_at_stop(t()) :: MapSet.t(route_id())
  def active_routes_at_stop(t) do
    t
    |> SAW.routes_at_stop()
    |> Enum.filter(& &1.active?)
    |> MapSet.new(& &1.route_id)
  end

  @spec informed_routes_at_home_stop(t()) :: MapSet.t(Route.id())
  def informed_routes_at_home_stop(t) do
    rts = route_types(t)
    home_stop = SAW.home_stop_id(t)
    route_set = all_routes_at_stop(t)

    # allows us to pattern match against the empty set
    empty_set = MapSet.new()

    uninformed_routes =
      Enum.reduce_while(informed_entities(t), route_set, fn
        _ie, ^empty_set ->
          {:halt, empty_set}

        %{route_type: nil, stop: nil, route: nil}, uninformed ->
          {:cont, uninformed}

        %{route_type: route_type_id, stop: nil, route: nil}, uninformed ->
          if RouteType.from_id(route_type_id) in rts,
            do: {:halt, empty_set},
            else: {:cont, uninformed}

        %{stop: ^home_stop, route: nil}, _uninformed ->
          {:halt, empty_set}

        %{stop: ^home_stop, route: route}, uninformed ->
          {:cont, MapSet.delete(uninformed, route)}

        %{stop: nil, route: route}, uninformed ->
          {:cont, MapSet.delete(uninformed, route)}

        _ie, uninformed ->
          {:cont, uninformed}
      end)

    MapSet.difference(route_set, uninformed_routes)
  end
end
