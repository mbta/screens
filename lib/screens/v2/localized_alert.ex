defmodule Screens.V2.LocalizedAlert do
  @moduledoc """
  Common logic for Alerts with location and screen context.
  """

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.LocationContext
  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Util
  alias Screens.V2.WidgetInstance.Alert, as: AlertWidget
  alias Screens.V2.WidgetInstance.{DupAlert, ElevatorStatus, ReconstructedAlert}

  @type t ::
          AlertWidget.t()
          | DupAlert.t()
          | ReconstructedAlert.t()
          | ElevatorStatus.t()
          | %{
              optional(:screen) => Screen.t(),
              alert: Alert.t(),
              location_context: LocationContext.t()
            }

  @type stop_id :: String.t()

  @type route_id :: String.t()

  @green_line_branches ["Green-B", "Green-C", "Green-D", "Green-E"]

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
  """
  @spec get_headsign_from_informed_entities(t()) :: headsign
  def get_headsign_from_informed_entities(
        %{screen: %Screen{app_id: app_id}, location_context: location_context, alert: alert} = t
      )
      when app_id in [:dup_v2, :pre_fare_v2] do
    with headsign_matchers when is_map(headsign_matchers) <- headsign_matchers(t) do
      informed_stop_ids = MapSet.new(Alert.informed_entities(alert), & &1.stop)

      headsign_matchers
      |> Map.get(location_context.home_stop)
      |> Enum.find_value(fn %{
                              informed: informed,
                              not_informed: not_informed,
                              alert_headsign: headsign
                            } ->
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

  defp headsign_matchers(%{screen: %Screen{app_id: :dup_v2}}),
    do: Application.get_env(:screens, :dup_alert_headsign_matchers)

  defp headsign_matchers(%{screen: %Screen{app_id: :pre_fare_v2}}),
    do: Application.get_env(:screens, :prefare_alert_headsign_matchers)

  defp alert_region_match?(informed, not_informed, informed_stop_ids) do
    MapSet.subset?(informed, informed_stop_ids) and
      MapSet.disjoint?(not_informed, informed_stop_ids)
  end

  @spec informed_entity_to_zone(Alert.informed_entity(), LocationContext.t()) ::
          list(:upstream | :home_stop | :downstream)
  defp informed_entity_to_zone(informed_entity, location_context)

  # All values nil
  defp informed_entity_to_zone(%{stop: nil, route: nil, route_type: nil}, _location_context) do
    []
  end

  # Only route type is not nil--this is the only time we consider route type,
  # since it's implied by other values when they are not nil
  defp informed_entity_to_zone(%{stop: nil, route: nil, route_type: route_type_id}, %{
         alert_route_types: alert_route_types
       }) do
    if RouteType.from_id(route_type_id) in alert_route_types do
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
    route_ids = Route.route_ids(context.routes)
    if route in route_ids, do: [:upstream, :home_stop, :downstream], else: []
  end

  defp informed_entity_to_zone(%{stop: _stop} = entity, context) do
    informed_entity_to_zone(Map.put(entity, :route, nil), context)
  end

  # Both stop and route are not nil (route type ignored)
  defp informed_entity_to_zone(%{stop: _stop, route: route} = informed_entity, context) do
    route_ids = Route.route_ids(context.routes)

    if route in route_ids do
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
  def location(
        %{alert: alert, location_context: location_context},
        is_terminal_station \\ false
      ) do
    informed_entities = Alert.informed_entities(alert)

    informed_zones_set =
      informed_entities
      |> Enum.flat_map(&informed_entity_to_zone(&1, location_context))
      |> Enum.uniq()
      |> Enum.sort()

    get_location_atom(informed_zones_set, alert.effect, is_terminal_station)
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

  @doc """
  Returns all routes affected by an alert.
  Used to build route pills for GL e-ink and text for Pre-fare alerts
  """
  @spec informed_subway_routes(t()) :: list(String.t())
  def informed_subway_routes(%{screen: %Screen{app_id: app_id}, alert: alert}) do
    alert
    |> Alert.informed_entities()
    |> Enum.map(fn %{route: route} -> route end)
    # If the alert impacts CR or other lines, weed that out
    |> Enum.filter(fn e ->
      Enum.member?(["Red", "Orange", "Green", "Blue"] ++ @green_line_branches, e)
    end)
    |> Enum.uniq()
    |> consolidate_gl(app_id)
  end

  # Different screens may consolidate the GL branch alerts
  @spec consolidate_gl(list(String.t()), atom()) :: list(String.t())
  # GL E-ink consolidates the GL branches to Green Line if there are > 2 branches
  defp consolidate_gl(affected_routes, :gl_eink_v2) do
    green_routes =
      Enum.filter(affected_routes, fn
        "Green" <> _ -> true
        _ -> false
      end)

    if length(green_routes) > 2, do: ["Green"], else: green_routes
  end

  # PreFare consolidates the GL branches if all branches are present
  defp consolidate_gl(affected_routes, :pre_fare_v2) do
    if MapSet.subset?(MapSet.new(@green_line_branches), MapSet.new(affected_routes)) do
      affected_routes
      |> Enum.reject(fn route -> String.contains?(route, "Green") end)
      |> Enum.concat(["Green"])
    else
      affected_routes
    end
  end

  defp consolidate_gl(affected_routes, _), do: affected_routes

  @doc """
  Used by bus shelter, bus einks, and prefare screens to decide whether an alert affects
  all active routes, and therefore should be a takeover alert
  """
  @spec informs_all_active_routes_at_home_stop?(t()) :: boolean()
  def informs_all_active_routes_at_home_stop?(t) do
    MapSet.subset?(active_routes_at_stop(t), MapSet.new(informed_routes_at_home_stop(t)))
  end

  @spec active_routes_at_stop(t()) :: MapSet.t(route_id())
  defp active_routes_at_stop(%{location_context: %{routes: routes}}) do
    routes
    |> Enum.filter(& &1.active?)
    |> MapSet.new(& &1.route_id)
  end

  @doc """
  This gets used by bus shelter, bus eink, DUP, prefare:
  - to help decide if we need a high-stakes takeover alert (bus, dup, prefare)
  - to serialize route pills on an alert (bus shelter & bus eink)

  Gets the routes affected by an alert that also exist at the current stop. No downstream
  """
  @spec informed_routes_at_home_stop(t()) :: list(Route.id())
  def informed_routes_at_home_stop(%{location_context: location_context, alert: alert}) do
    rts = location_context.alert_route_types
    home_stop = location_context.home_stop

    route_set =
      location_context.routes
      |> Route.route_ids()
      |> MapSet.new()

    # allows us to pattern match against the empty set
    empty_set = MapSet.new()

    uninformed_routes =
      Enum.reduce_while(Alert.informed_entities(alert), route_set, fn
        _ie, ^empty_set ->
          {:halt, empty_set}

        # If entity has no route indicator, don't mark any route as informed
        %{route_type: nil, stop: nil, route: nil}, uninformed ->
          {:cont, uninformed}

        # For a systemwide alert (affecting all bus or all subway/light rail)
        # entity has route type, but no stop or route
        # credo:disable-for-next-line
        # TODO bug: currently breaks for pre-fare, dups (because they are multimodal, and alerts UI lumps
        # together subway and light rail)
        %{route_type: route_type_id, stop: nil, route: nil}, uninformed ->
          if RouteType.from_id(route_type_id) in rts,
            do: {:halt, empty_set},
            else: {:cont, uninformed}

        # If entity is home stop and NO route, indicate all routes are informed
        # Might not be feasible with Alerts UI
        %{stop: ^home_stop, route: nil}, _uninformed ->
          {:halt, empty_set}

        # If entity is home stop AND a route, then just that route is marked informed
        %{stop: ^home_stop, route: route}, uninformed ->
          {:cont, MapSet.delete(uninformed, route)}

        # Removed the case with downstream alerts because:
        #  - we don't want to consider downstream alerts for a takeover (bus, prefare, dup)
        #  - we don't want to ever show downstream alerts on bus shelter / bus e-ink

        # If the entity has a route, but no stop, that route is marked informed
        %{stop: nil, route: route}, uninformed ->
          {:cont, MapSet.delete(uninformed, route)}

        _ie, uninformed ->
          {:cont, uninformed}
      end)

    route_set
    |> MapSet.difference(uninformed_routes)
    |> Enum.to_list()
  end
end
