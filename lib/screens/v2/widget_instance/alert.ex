defmodule Screens.V2.WidgetInstance.Alert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.Departures.Query.Params
  alias Screens.Config.V2.{BusEink, BusShelter, GlEink}
  alias Screens.RouteType

  defstruct ~w[screen alert stop_sequences active_routes_at_stop]a

  @type stop_id :: String.t()

  @type route_id :: String.t()

  @type t :: %__MODULE__{
          screen: Screens.Config.Screen.t(),
          alert: Alert.t(),
          stop_sequences: list(list(stop_id())),
          active_routes_at_stop: list(route_id())
        }

  def active?(%__MODULE__{alert: alert}, happening_now? \\ &Alert.happening_now?/1) do
    happening_now?.(alert)
  end

  @spec seconds_from_onset(t(), DateTime.t()) :: integer() | :infinity
  def seconds_from_onset(t, now \\ DateTime.utc_now())

  def seconds_from_onset(%__MODULE__{alert: %Alert{active_period: [{start, _} | _]}}, now)
      when not is_nil(start) do
    DateTime.diff(now, start, :second)
  end

  def seconds_from_onset(_t, _now), do: :infinity

  @spec seconds_to_next_active_period(t(), DateTime.t()) :: integer() | :infinity
  def seconds_to_next_active_period(t, now \\ DateTime.utc_now())

  def seconds_to_next_active_period(
        %__MODULE__{alert: %Alert{active_period: active_periods}},
        now
      )
      when not is_nil(active_periods) do
    next_active_period =
      Enum.find(active_periods, fn {start, _} ->
        not is_nil(start) and DateTime.compare(now, start) in [:lt, :eq]
      end)

    case next_active_period do
      nil -> :infinity
      {start, _} -> DateTime.diff(start, now, :second)
    end
  end

  def seconds_to_next_active_period(_t, _now), do: :infinity

  @spec home_stop_id(t()) :: String.t()
  def home_stop_id(%__MODULE__{
        screen: %Screen{
          app_params: %app{
            departures: %{sections: [%{query: %{params: %Params{stop_ids: [stop_id]}}}]}
          }
        }
      })
      when app in [BusShelter, GlEink, BusEink] do
    stop_id
  end

  @spec informed_entities(t()) :: list(Alert.informed_entity())
  def informed_entities(%__MODULE__{alert: %Alert{informed_entities: informed_entities}}) do
    informed_entities
  end

  @spec upstream_stop_id_set(t()) :: MapSet.t(stop_id())
  def upstream_stop_id_set(%__MODULE__{} = t) do
    home_stop_id = home_stop_id(t)

    t.stop_sequences
    |> Enum.flat_map(fn stop_sequence -> slice_before(stop_sequence, home_stop_id) end)
    |> MapSet.new()
  end

  @spec downstream_stop_id_set(t()) :: MapSet.t(stop_id())
  def downstream_stop_id_set(%__MODULE__{} = t) do
    home_stop_id = home_stop_id(t)

    t.stop_sequences
    |> Enum.flat_map(fn stop_sequence -> slice_after(stop_sequence, home_stop_id) end)
    |> MapSet.new()
  end

  @spec location(t()) ::
          :upstream
          | :boundary_upstream
          | :boundary_downstream
          | :inside
          | :downstream
          | :elsewhere
  def location(%__MODULE__{} = t) do
    location_context = %{
      home_stop: home_stop_id(t),
      upstream_stops: upstream_stop_id_set(t),
      downstream_stops: downstream_stop_id_set(t),
      active_routes: t.active_routes_at_stop,
      screen: t.screen
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
      true -> :elsewhere
    end
  end

  @spec effect(t()) :: Alert.effect()
  def effect(%__MODULE__{alert: %Alert{effect: effect}}), do: effect

  @spec informed_entity_to_zone(Alert.informed_entity(), map()) ::
          list(:upstream | :home_stop | :downstream)
  defp informed_entity_to_zone(informed_entity, location_context)

  # All values nil
  defp informed_entity_to_zone(%{stop: nil, route: nil, route_type: nil}, _location_context) do
    []
  end

  # Only route type is not nil--this is the only time we consider route type,
  # since it's implied by other values when they are not nil
  defp informed_entity_to_zone(%{stop: nil, route: nil, route_type: route_type_id}, context) do
    route_type = RouteType.from_id(route_type_id)

    case {route_type, context.screen.app_id} do
      {:bus, :bus_shelter_v2} -> [:upstream, :home_stop, :downstream]
      {:bus, :bus_eink_v2} -> [:upstream, :home_stop, :downstream]
      {:light_rail, :gl_eink_v2} -> [:upstream, :home_stop, :downstream]
      _ -> []
    end
  end

  # Only stop is not nil (route type ignored)
  defp informed_entity_to_zone(%{stop: stop, route: nil}, context) do
    cond do
      stop == context.home_stop -> [:home_stop]
      stop in context.upstream_stops -> [:upstream]
      stop in context.downstream_stops -> [:downstream]
      true -> []
    end
  end

  # Only route is not nil (route type ignored)
  defp informed_entity_to_zone(%{stop: nil, route: route}, context) do
    # Should we consider whether the stop is a terminus?
    # If so, an alert that informs a route through the stop might not always be all 3 zones.
    if route in context.active_routes, do: [:upstream, :home_stop, :downstream], else: []
  end

  # Both stop and route are not nil (route type ignored)
  defp informed_entity_to_zone(%{stop: _stop, route: route} = informed_entity, context) do
    if route in context.active_routes do
      informed_entity_to_zone(%{informed_entity | route: nil}, context)
    else
      []
    end
  end

  defp slice_before(list, target) do
    case Enum.find_index(list, &(&1 == target)) do
      nil -> []
      i -> Enum.take(list, i)
    end
  end

  defp slice_after(list, target) do
    case Enum.find_index(list, &(&1 == target)) do
      nil -> []
      i -> Enum.drop(list, i + 1)
    end
  end

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance) do
      [1]
    end

    def serialize(_instance) do
      %{}
    end

    def slot_names(_instance) do
      [:medium_left, :medium_right]
    end

    def widget_type(_instance) do
      :alert
    end
  end
end
