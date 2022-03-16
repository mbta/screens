defmodule Screens.V2.WidgetInstance.Common.BaseAlert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{Alerts, BusEink, BusShelter, GlEink, PreFare}
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.RouteType
  alias Screens.Util
  alias Screens.V2.WidgetInstance.Alert, as: AlertWidget
  alias Screens.V2.WidgetInstance.ReconstructedAlert

  @type stop_id :: String.t()

  @type route_id :: String.t()

  @spec home_stop_id(AlertWidget.t() | ReconstructedAlert.t()) :: String.t()
  def home_stop_id(%{
        screen: %Screen{app_params: %app{alerts: %Alerts{stop_id: stop_id}}}
      })
      when app in [BusShelter, GlEink, BusEink] do
    stop_id
  end

  def home_stop_id(%{
        screen: %Screen{app_params: %app{header: %CurrentStopId{stop_id: stop_id}}}
      })
      when app in [PreFare] do
    stop_id
  end

  @spec upstream_stop_id_set(AlertWidget.t() | ReconstructedAlert.t()) ::
          MapSet.t(stop_id())
  def upstream_stop_id_set(%{stop_sequences: stop_sequences} = t) do
    home_stop_id = home_stop_id(t)

    stop_sequences
    |> Enum.flat_map(fn stop_sequence -> Util.slice_before(stop_sequence, home_stop_id) end)
    |> MapSet.new()
  end

  @spec downstream_stop_id_set(AlertWidget.t() | ReconstructedAlert.t()) ::
          MapSet.t(stop_id())
  def downstream_stop_id_set(%{stop_sequences: stop_sequences} = t) do
    home_stop_id = home_stop_id(t)

    stop_sequences
    |> Enum.flat_map(fn stop_sequence -> Util.slice_after(stop_sequence, home_stop_id) end)
    |> MapSet.new()
  end

  def all_routes_at_stop(%{routes_at_stop: routes}) do
    MapSet.new(routes, & &1.route_id)
  end

  def route_type(%{screen: %Screen{app_id: :bus_shelter_v2}}), do: :bus
  def route_type(%{screen: %Screen{app_id: :bus_eink_v2}}), do: :bus
  def route_type(%{screen: %Screen{app_id: :gl_eink_v2}}), do: :light_rail

  def route_type(%{
        screen: %Screen{app_id: :pre_fare_v2},
        routes_at_stop: routes_at_stop
      }) do
    routes_at_stop
    |> Enum.map(& &1.type)
    |> Enum.dedup()
  end

  @spec informed_entities(AlertWidget.t() | ReconstructedAlert.t()) ::
          list(Alert.informed_entity())
  def informed_entities(%{alert: %Alert{informed_entities: informed_entities}}) do
    informed_entities
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
         route_type: route_type
       })
       when is_list(route_type) do
    if RouteType.from_id(route_type_id) in route_type do
      [:upstream, :home_stop, :downstream]
    else
      []
    end
  end

  defp informed_entity_to_zone(%{stop: nil, route: nil, route_type: route_type_id}, context) do
    if RouteType.from_id(route_type_id) == context.route_type do
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

  @spec location(AlertWidget.t() | ReconstructedAlert.t()) ::
          :upstream
          | :boundary_upstream
          | :boundary_downstream
          | :inside
          | :downstream
          | :elsewhere
  def location(%{} = t) do
    location_context = %{
      home_stop: home_stop_id(t),
      upstream_stops: upstream_stop_id_set(t),
      downstream_stops: downstream_stop_id_set(t),
      routes: all_routes_at_stop(t),
      route_type: route_type(t)
    }

    informed_entities = informed_entities(t)

    informed_zones_set =
      informed_entities
      |> Enum.flat_map(&informed_entity_to_zone(&1, location_context))
      |> MapSet.new()

    import MapSet, only: [equal?: 2, new: 1]

    cond do
      equal?(informed_zones_set, new([:upstream])) -> :upstream
      equal?(informed_zones_set, new([:downstream])) -> :downstream
      equal?(informed_zones_set, new([:home_stop])) -> :inside
      equal?(informed_zones_set, new([:upstream, :home_stop, :downstream])) -> :inside
      equal?(informed_zones_set, new([:upstream, :home_stop])) -> :boundary_upstream
      equal?(informed_zones_set, new([:home_stop, :downstream])) -> :boundary_downstream
      # An edge case that occurs most often when home_stop is a terminus, and some other cases
      equal?(informed_zones_set, new([:downstream, :upstream])) -> :downstream
      true -> :elsewhere
    end
  end

  def active?(%{alert: alert, now: now}, happening_now? \\ &Alert.happening_now?/2) do
    happening_now?.(alert, now)
  end

  @spec effect(%{alert: Alert.t()}) :: Alert.effect()
  def effect(%{alert: %Alert{effect: effect}}), do: effect

  def informs_all_active_routes_at_home_stop?(t) do
    MapSet.subset?(active_routes_at_stop(t), informed_routes_at_home_stop(t))
  end

  def active_routes_at_stop(%{routes_at_stop: routes}) do
    routes
    |> Enum.filter(& &1.active?)
    |> MapSet.new(& &1.route_id)
  end

  defp informed_routes_at_home_stop(t) do
    rt = route_type(t)
    home_stop = home_stop_id(t)
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
          # Route type might be a single atom or list of atoms
          cond do
            is_list(rt) and RouteType.from_id(route_type_id) in rt ->
              {:halt, empty_set}

            RouteType.from_id(route_type_id) == rt ->
              {:halt, empty_set}

            true ->
              {:cont, uninformed}
          end

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
