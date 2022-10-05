defmodule Screens.V2.WidgetInstance.Alert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.{Alerts, BusEink, BusShelter, GlEink, PreFare}
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.RouteType
  alias Screens.Util
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.Common.BaseAlert
  alias Screens.V2.WidgetInstance.ReconstructedAlert
  alias Screens.V2.WidgetInstance.Serializer.RoutePill

  defstruct screen: nil,
            alert: nil,
            stop_sequences: nil,
            routes_at_stop: nil,
            now: nil

  @type stop_id :: String.t()

  @type route_id :: String.t()

  @type t :: %__MODULE__{
          screen: Screen.t(),
          alert: Alert.t(),
          stop_sequences: list(list(stop_id())),
          routes_at_stop: list(%{route_id: route_id(), active?: boolean()}),
          now: DateTime.t()
        }

  @normal_content_priority 2
  @alert_base_priority 2
  @flex_zone_alert_base_priority [@normal_content_priority, @alert_base_priority]

  @automated_override_priority [1, 2]

  # Keep these in descending order of priority--highest priority (lowest integer value) first
  @relevant_effects ~w[shuttle stop_closure suspension station_closure detour stop_move stop_moved snow_route elevator_closure]a

  @effect_priorities Enum.with_index(@relevant_effects, 1)

  @effect_headers Enum.zip(
                    @relevant_effects,
                    Enum.map(@relevant_effects, fn
                      :stop_closure ->
                        "Stop Closed"

                      :station_closure ->
                        "Station Closed"

                      :elevator_closure ->
                        "Elevator Closed"

                      effect ->
                        effect
                        |> Atom.to_string()
                        |> String.split("_")
                        |> Enum.map_join(" ", &String.capitalize/1)
                    end)
                  )

  @effect_icons Enum.zip(
                  @relevant_effects,
                  Enum.map(@relevant_effects, fn
                    bus when bus in ~w[shuttle detour]a -> :bus
                    major when major in ~w[stop_closure suspension station_closure]a -> :x
                    minor when minor in ~w[stop_move stop_moved elevator_closure]a -> :warning
                    :snow_route -> :snowflake
                  end)
                )

  @spec priority(t()) :: nonempty_list(pos_integer()) | WidgetInstance.no_render()
  def priority(t) do
    tiebreakers =
      @flex_zone_alert_base_priority ++
        [
          tiebreaker_primary_timeframe(t),
          tiebreaker_location(t),
          tiebreaker_secondary_timeframe(t),
          tiebreaker_effect(t)
        ]

    cond do
      Enum.any?(tiebreakers, &(&1 == :no_render)) -> :no_render
      takeover_alert?(t) -> @automated_override_priority
      true -> tiebreakers
    end
  end

  @spec serialize(t()) :: map()
  def serialize(t) do
    e = effect(t)

    %{
      route_pills: serialize_route_pills(t),
      icon: serialize_icon(e),
      header: serialize_header(e),
      body: t.alert.header,
      url: clean_up_url(t.alert.url || "mbta.com/alerts")
    }
  end

  defp serialize_route_pills(t) do
    routes = informed_routes(t)

    if MapSet.size(routes) <= 3 do
      routes
      |> Enum.to_list()
      |> Enum.sort_by(fn route_id ->
        case Integer.parse(route_id) do
          # Bus route (including SL_, CT_)
          {route_number, ""} -> route_number
          # Non-bus route
          _ -> route_id
        end
      end)
      |> Enum.map(&RoutePill.serialize_route_for_alert/1)
    else
      t
      |> route_type()
      |> RoutePill.serialize_route_type_for_alert()
      |> List.wrap()
    end
  end

  for {e, header} <- @effect_headers do
    defp serialize_header(unquote(e)), do: unquote(header)
  end

  for {e, icon} <- @effect_icons do
    defp serialize_icon(unquote(e)), do: unquote(icon)
  end

  # Removes leading scheme specifier ("http[s]"), www. prefix, and trailing "/" from url.
  defp clean_up_url(url) do
    url
    |> String.replace(~r|^https?://|i, "")
    |> String.replace(~r|^www\.|i, "")
    |> String.replace(~r|/$|, "")
  end

  def slot_names(t) do
    if takeover_alert?(t), do: takeover_slot_names(t), else: normal_slot_names(t)
  end

  def takeover_alert?(%__MODULE__{screen: %Screen{app_id: bus_app_id}} = t)
      when bus_app_id in [:bus_shelter_v2, :bus_eink_v2] do
    active?(t) and effect(t) in [:stop_closure, :stop_move, :stop_moved, :suspension, :detour] and
      informs_all_active_routes_at_home_stop?(t)
  end

  def takeover_alert?(%__MODULE__{screen: %Screen{app_id: :gl_eink_v2}} = t) do
    active?(t) and effect(t) in [:station_closure, :suspension, :shuttle] and
      BaseAlert.location(t) == :inside
  end

  def takeover_alert?(
        %{screen: %Screen{app_id: :pre_fare_v2}, is_terminal_station: is_terminal_station} = t
      ) do
    active?(t) and effect(t) in [:station_closure, :suspension, :shuttle] and
      BaseAlert.location(t, is_terminal_station) == :inside and
      informs_all_active_routes_at_home_stop?(t)
  end

  defp takeover_slot_names(%__MODULE__{screen: %Screen{app_id: :bus_shelter_v2}}) do
    [:full_body]
  end

  defp takeover_slot_names(%__MODULE__{screen: %Screen{app_id: eink_app_id}})
       when eink_app_id in [:gl_eink_v2, :bus_eink_v2] do
    [:full_body_top_screen]
  end

  defp normal_slot_names(%__MODULE__{screen: %Screen{app_id: :bus_shelter_v2}}) do
    [:medium_left, :medium_right]
  end

  defp normal_slot_names(%__MODULE__{screen: %Screen{app_id: eink_app_id}})
       when eink_app_id in [:gl_eink_v2, :bus_eink_v2] do
    [:medium]
  end

  def widget_type(t) do
    if takeover_alert?(t), do: :full_body_alert, else: :alert
  end

  def valid_candidate?(%__MODULE__{screen: %Screen{app_id: screen_type}} = t)
      when screen_type in [:bus_shelter_v2, :bus_eink_v2] do
    priority(t) != :no_render and
      BaseAlert.location(t) == :inside and
      active?(t)
  end

  def valid_candidate?(t) do
    priority(t) != :no_render
  end

  def active?(%{alert: alert, now: now}, happening_now? \\ &Alert.happening_now?/2) do
    happening_now?.(alert, now)
  end

  @spec seconds_from_onset(t()) :: integer()
  def seconds_from_onset(%__MODULE__{alert: %Alert{active_period: [{start, _} | _]}, now: now})
      when not is_nil(start) do
    DateTime.diff(now, start, :second)
  end

  @spec seconds_to_next_active_period(t()) :: integer() | :infinity
  def seconds_to_next_active_period(%__MODULE__{
        alert: %Alert{active_period: active_periods},
        now: now
      })
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

  def seconds_to_next_active_period(_t), do: :infinity

  @spec home_stop_id(t()) :: String.t()
  def home_stop_id(%{
        screen: %Screen{app_params: %app{alerts: %Alerts{stop_id: stop_id}}}
      })
      when app in [BusShelter, GlEink, BusEink] do
    stop_id
  end

  def home_stop_id(%{
        screen: %Screen{
          app_params: %app{reconstructed_alert_widget: %CurrentStopId{stop_id: stop_id}}
        }
      })
      when app in [PreFare] do
    stop_id
  end

  @spec informed_entities(t()) :: list(Alert.informed_entity())
  def informed_entities(%{alert: %Alert{informed_entities: informed_entities}}) do
    informed_entities
  end

  @spec upstream_stop_id_set(t()) :: MapSet.t(stop_id())
  def upstream_stop_id_set(%{} = t) do
    home_stop_id = home_stop_id(t)

    t.stop_sequences
    |> Enum.flat_map(fn stop_sequence -> Util.slice_before(stop_sequence, home_stop_id) end)
    |> MapSet.new()
  end

  @spec downstream_stop_id_set(t()) :: MapSet.t(stop_id())
  def downstream_stop_id_set(%{} = t) do
    home_stop_id = home_stop_id(t)

    t.stop_sequences
    |> Enum.flat_map(fn stop_sequence -> Util.slice_after(stop_sequence, home_stop_id) end)
    |> MapSet.new()
  end

  @spec effect(t() | ReconstructedAlert.t()) :: Alert.effect()
  def effect(%{alert: %Alert{effect: effect}}), do: effect

  def all_routes_at_stop(%{routes_at_stop: routes}) do
    MapSet.new(routes, & &1.route_id)
  end

  def active_routes_at_stop(%{routes_at_stop: routes}) do
    routes
    |> Enum.filter(& &1.active?)
    |> MapSet.new(& &1.route_id)
  end

  def route_type(%__MODULE__{screen: %Screen{app_id: :bus_shelter_v2}}), do: :bus
  def route_type(%__MODULE__{screen: %Screen{app_id: :bus_eink_v2}}), do: :bus
  def route_type(%__MODULE__{screen: %Screen{app_id: :gl_eink_v2}}), do: :light_rail

  def route_type(%{
        screen: %Screen{app_id: :pre_fare_v2},
        routes_at_stop: routes_at_stop
      }) do
    routes_at_stop
    |> Enum.map(& &1.type)
    |> Enum.dedup()
  end

  # Time units in seconds
  @hour 60 * 60
  @week 24 * @hour * 7

  @spec tiebreaker_primary_timeframe(t()) :: pos_integer() | WidgetInstance.no_render()
  def tiebreaker_primary_timeframe(%__MODULE__{} = t) do
    if active?(t) do
      from_onset = seconds_from_onset(t)

      cond do
        from_onset < 4 * @week -> 1
        from_onset in (4 * @week)..(12 * @week - 1) -> 2
        from_onset in (12 * @week)..(24 * @week - 1) -> 4
        true -> :no_render
      end
    else
      to_next = seconds_to_next_active_period(t)

      cond do
        to_next < 36 * @hour -> 2
        to_next >= 36 * @hour -> 3
      end
    end
  end

  @spec tiebreaker_location(t()) :: pos_integer() | WidgetInstance.no_render()
  def tiebreaker_location(%__MODULE__{} = t) do
    case BaseAlert.location(t) do
      :inside -> 1
      :boundary_upstream -> 2
      :boundary_downstream -> 2
      :downstream -> 3
      _ -> :no_render
    end
  end

  @doc """
  This tiebreaker's only purpose is to split the two cases that produce a `primary_timeframe` of 2.
  In all other cases, it will have no effect.
  """
  @spec tiebreaker_secondary_timeframe(t()) :: pos_integer()
  def tiebreaker_secondary_timeframe(%__MODULE__{} = t) do
    cond do
      not active?(t) and seconds_to_next_active_period(t) < 36 * @hour ->
        1

      active?(t) and seconds_from_onset(t) in (4 * @week)..(12 * @week - 1) ->
        2

      true ->
        3
    end
  end

  @spec tiebreaker_effect(t()) :: pos_integer() | WidgetInstance.no_render()
  def tiebreaker_effect(%__MODULE__{} = t) do
    Keyword.get(@effect_priorities, effect(t), :no_render)
  end

  defp informs_all_active_routes_at_home_stop?(t) do
    MapSet.subset?(active_routes_at_stop(t), BaseAlert.informed_routes_at_home_stop(t))
  end

  defp informed_routes(t) do
    rt = route_type(t)
    home_stop = home_stop_id(t)
    downstream_stop_set = downstream_stop_id_set(t)
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

        # We can't handle this case properly until the struct is updated to record which routes serve which stops.
        # %{stop: stop, route: nil}, uninformed when stop in downstream_stops ->
        #   {:cont, MapSet.difference(uninformed, routes_by_stop[stop])}

        %{stop: ^home_stop, route: route}, uninformed ->
          {:cont, MapSet.delete(uninformed, route)}

        %{stop: stop, route: route}, uninformed when is_binary(stop) ->
          if stop in downstream_stop_set do
            {:cont, MapSet.delete(uninformed, route)}
          else
            {:cont, uninformed}
          end

        %{stop: nil, route: route}, uninformed ->
          {:cont, MapSet.delete(uninformed, route)}

        _ie, uninformed ->
          {:cont, uninformed}
      end)

    MapSet.difference(route_set, uninformed_routes)
  end

  def audio_serialize(_instance), do: %{}

  def audio_sort_key(_instance), do: [0]

  def audio_valid_candidate?(_instance), do: false

  def audio_view(_instance), do: ScreensWeb.V2.Audio.AlertView

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.Alert

    def priority(instance), do: Alert.priority(instance)
    def serialize(instance), do: Alert.serialize(instance)
    def slot_names(instance), do: Alert.slot_names(instance)
    def widget_type(instance), do: Alert.widget_type(instance)
    def valid_candidate?(instance), do: Alert.valid_candidate?(instance)
    def audio_serialize(instance), do: Alert.audio_serialize(instance)
    def audio_sort_key(instance), do: Alert.audio_sort_key(instance)
    def audio_valid_candidate?(instance), do: Alert.audio_valid_candidate?(instance)
    def audio_view(instance), do: Alert.audio_view(instance)
  end
end
