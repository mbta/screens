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
  alias Screens.Config.Screen
  alias Screens.LocationContext
  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Util

  @type t :: %{
    alert: %Alert{},
    location_context: %LocationContext{}
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

  Returns nil if either of the following is true:
  - the home stop is not on the boundary of the alert's affected region.
  - the widget does not have a map of headsign matchers (`SingleAlertWidget.headsign_matchers(t)` returns nil)
  """
  @spec get_headsign_from_informed_entities(t()) :: headsign | nil
  def get_headsign_from_informed_entities(%{screen: %Screen{app_id: app_id}} = t) when app_id in [:dup_v2, :pre_fare_v2] do
    with headsign_matchers when is_map(headsign_matchers) <- headsign_matchers(t) do
      informed_stop_ids = MapSet.new(informed_entities(t), & &1.stop)

      headsign_matchers
      |> Map.get(t.location_context.home_stop)
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

  defp headsign_matchers(%{screen: %Screen{app_id: :dup_v2}}), do: Application.get_env(:screens, :dup_alert_headsign_matchers)
  defp headsign_matchers(%{screen: %Screen{app_id: :pre_fare_v2}}), do: Application.get_env(:screens, :prefare_alert_headsign_matchers)

  defp alert_region_match?(informed, not_informed, informed_stop_ids) do
    MapSet.subset?(informed, informed_stop_ids) and
      MapSet.disjoint?(not_informed, informed_stop_ids)
  end

  def informed_entities(%{alert: %Alert{informed_entities: informed_entities}}) do
    informed_entities
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
    if route in context.route_ids_at_stop, do: [:upstream, :home_stop, :downstream], else: []
  end

  # Both stop and route are not nil (route type ignored)
  defp informed_entity_to_zone(%{stop: _stop, route: route} = informed_entity, context) do
    if route in context.route_ids_at_stop do
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
  def location(%{alert: %Alert{} = alert, location_context: %LocationContext{} = location_context} = t, is_terminal_station \\ false) do
    informed_entities = informed_entities(t)

    IO.inspect(location_context, label: "location context")

    informed_zones_set =
      informed_entities
      # |> IO.inspect(label: "informed entities")
      |> Enum.flat_map(&informed_entity_to_zone(&1, location_context))
      |> Enum.uniq()
      |> Enum.sort()
      # |> IO.inspect(label: "informed zones")

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

  # Only used to decide "takeover_alert" for bus shelter, bus einks, and prefare screens
  def informs_all_active_routes_at_home_stop?(t) do
    MapSet.subset?(active_routes_at_stop(t), MapSet.new(informed_routes_at_home_stop(t)))
  end

  @spec active_routes_at_stop(t()) :: MapSet.t(route_id())
  def active_routes_at_stop(%{location_context: %{routes: routes}}) do
    routes
    |> Enum.filter(& &1.active?)
    |> MapSet.new(& &1.route_id)
  end

  def informed_subway_routes(%{screen: %Screen{app_id: app_id}} = t) do
    t
    |> informed_entities() 
    |> Enum.map(fn %{route: route} -> route end)
    # If the alert impacts CR or other lines, weed that out
    |> Enum.filter(fn e ->
      Enum.member?(["Red", "Orange", "Green", "Blue"] ++ @green_line_branches, e)
    end)
    |> Enum.uniq()
    |> consolidate_GL(app_id)
  end

  @spec consolidate_GL(list(String.t()), atom()) :: list(String.t())
  # GL E-ink consolidates the GL branches to Green Line if there are > 2 branches
  # We wdant to list all affected branches for the alert and not just the one serving the home stop
  defp consolidate_GL(affected_routes, :gl_eink_v2) do
    green_routes = Enum.filter(affected_routes, fn
        "Green" <> _ -> true
        _ -> false
      end)

    if length(green_routes) > 2, do: ["Green"], else: green_routes
  end
  # PreFare consolidates the GL branches if all branches are present
  defp consolidate_GL(affected_routes, :pre_fare_v2) do
    if MapSet.subset?(MapSet.new(@green_line_branches), MapSet.new(affected_routes)) do
      affected_routes
      |> Enum.reject(fn route -> String.contains?(route, "Green") end)
      |> Enum.concat(["Green"])
    else
      affected_routes
    end
  end

  defp consolidate_GL(affected_routes, _), do: affected_routes

  # This gets used by bus shelter, bus eink, DUP, prefare
  #  - to help decide if we need a high-stakes takeover alert (bus, dup, prefare)
  #  - to serialize route pills on an alert (bus shelter & bus eink)

  # Gets the routes affected by an alert that also exist at the current stop.
  # NO downstream
  @spec informed_routes_at_home_stop(t()) :: MapSet.t(Route.id())
  def informed_routes_at_home_stop(t) do
    rts = t.location_context.alert_route_types
    home_stop = t.location_context.stop_id
    route_set = t.location_context.routes

    # allows us to pattern match against the empty set
    empty_set = MapSet.new()

    uninformed_routes =
      Enum.reduce_while(informed_entities(t), route_set, fn
        _ie, ^empty_set ->
          {:halt, empty_set}

        # If entity has no route indicator, don't mark any route as informed
        %{route_type: nil, stop: nil, route: nil}, uninformed ->
          {:cont, uninformed}

        # For a systemwide alert (affecting all bus or all subway/light rail)
        # entity has route type, but no stop or route
        # BUG: currently breaks for pre-fare, dups (because they are multimodal, and alerts UI lumps
        # together subway and light rail)
        %{route_type: route_type_id, stop: nil, route: nil}, uninformed ->
          if RouteType.from_id(route_type_id) in rts,
            do: {:halt, empty_set},
            else: {:cont, uninformed}

        # If entity is home stop and NO route, indicate all routes are informed
        # Might not be feasible with Alerts UI
        %{stop: ^home_stop, route: nil}, _uninformed -> {:halt, empty_set}

        # If entity is home stop AND a route, then just that route is marked informed
        %{stop: ^home_stop, route: route}, uninformed ->
          {:cont, MapSet.delete(uninformed, route)}

        # Removed the case with downstream alerts because:
        #  - we don't want to consider downstream alerts for a takeover (bus, prefare, dup)
        #  - we don't want ever show downstream alerts on bus shelter / bus e-ink

        # If the entity has a route, but no stop, that route is marked informed
        %{stop: nil, route: route}, uninformed ->
          {:cont, MapSet.delete(uninformed, route)}

        _ie, uninformed ->
          {:cont, uninformed}
      end)

    MapSet.difference(route_set, uninformed_routes)
    |> Enum.to_list()
  end
end
