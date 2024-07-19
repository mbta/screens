defmodule Screens.V2.WidgetInstance.Alert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.Serializer.RoutePill
  alias ScreensConfig.Screen

  defstruct screen: nil,
            alert: nil,
            location_context: nil,
            now: nil

  @type stop_id :: String.t()

  @type route_id :: String.t()

  @type t :: %__MODULE__{
          screen: Screen.t(),
          alert: Alert.t(),
          location_context: LocationContext.t(),
          now: DateTime.t()
        }

  @normal_content_priority 2
  @alert_base_priority 2
  @flex_zone_alert_base_priority [@normal_content_priority, @alert_base_priority]

  @automated_override_priority [1, 2]

  # Keep these in descending order of priority--highest priority (lowest integer value) first
  @relevant_effects ~w[shuttle stop_closure suspension station_closure detour stop_moved snow_route elevator_closure]a

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

                      :shuttle ->
                        "Shuttle Buses"

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
                    minor when minor in ~w[stop_moved elevator_closure]a -> :warning
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
  def serialize(%{alert: alert} = t) do
    e = Alert.effect(alert)

    %{
      route_pills: serialize_route_pills(t),
      icon: serialize_icon(e),
      header: serialize_header(e),
      body: alert.header,
      url: clean_up_url(t.alert.url || "mbta.com/alerts")
    }
  end

  defp serialize_route_pills(%__MODULE__{screen: %Screen{app_id: app_id}} = t) do
    routes =
      if app_id === :gl_eink_v2 do
        # Get route pills for alert, including that on connecting GL branches
        LocalizedAlert.consolidated_informed_subway_routes(t)
      else
        # Get route pills for an alert, but only the routes that are at this stop
        LocalizedAlert.informed_routes_at_home_stop(t)
      end

    if length(routes) <= 3 do
      routes
      |> Enum.sort_by(fn route_id ->
        case Integer.parse(route_id) do
          # Bus route (including SL_, CT_)
          {route_number, ""} -> route_number
          # Non-bus route
          _ -> route_id
        end
      end)
      |> Enum.map(&RoutePill.serialize_route_for_alert(&1, length(routes) == 1))
    else
      t.location_context.alert_route_types
      # For bus shelter / e-ink, there's only 1 list item
      |> List.first()
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

  def takeover_alert?(%__MODULE__{screen: %Screen{app_id: bus_app_id}, alert: alert} = t)
      when bus_app_id in [:bus_shelter_v2, :bus_eink_v2] do
    Alert.effect(alert) in [:stop_closure, :stop_moved, :suspension, :detour] and
      LocalizedAlert.informs_all_active_routes_at_home_stop?(t)
  end

  def takeover_alert?(%__MODULE__{screen: %Screen{app_id: :gl_eink_v2}, alert: alert} = t) do
    Alert.effect(alert) in [:station_closure, :suspension, :shuttle] and
      LocalizedAlert.location(t) in [:inside, :boundary_upstream, :boundary_downstream]
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

  # Refer to https://mbta.sharepoint.com/:w:/s/CTDpublic/Eb_yKasCL9xKu_D9Xd1O5d0BG1GoHfplwoI-fpnru42M9w for how PIOs create alerts.
  # For bus alerts, we assume that alerts are created using this guide.

  # For bus suspensions, the endpoints of the alert are not directly affected by the suspension.
  # This means that `boundary_upstream` and `boundary_downstream` stops are present in the `informed_entities` of the alerts,
  # But the alert itself is not relevant for riders at the `boundary_upstream` stop.
  # Because of this, we will not show a suspension alert at on a screen if the current stop is located on the `boundary_upstream`.
  def valid_candidate?(
        %__MODULE__{screen: %Screen{app_id: screen_type}, alert: %Alert{effect: :suspension}} = t
      )
      when screen_type in [:bus_shelter_v2, :bus_eink_v2] do
    priority(t) != :no_render and
      LocalizedAlert.location(t) in [:inside, :boundary_downstream]
  end

  # For all other bus alert effects, all stops in the `informed_entities` are directly affected by the alert and would be useful for riders to see.
  def valid_candidate?(%__MODULE__{screen: %Screen{app_id: screen_type}} = t)
      when screen_type in [:bus_shelter_v2, :bus_eink_v2] do
    priority(t) != :no_render and
      LocalizedAlert.location(t) in [:inside, :boundary_upstream, :boundary_downstream]
  end

  # Any subway alert that is not filtered out in the candidate_generator is valid and should appear on screens›.
  def valid_candidate?(t) do
    priority(t) != :no_render
  end

  # Time units in seconds
  @hour 60 * 60
  @week 24 * @hour * 7

  @spec tiebreaker_primary_timeframe(t()) :: pos_integer() | WidgetInstance.no_render()
  def tiebreaker_primary_timeframe(%__MODULE__{} = t) do
    from_onset = seconds_from_onset(t)

    cond do
      from_onset < 4 * @week -> 1
      from_onset in (4 * @week)..(12 * @week - 1) -> 2
      from_onset in (12 * @week)..(24 * @week - 1) -> 4
      true -> :no_render
    end
  end

  @spec tiebreaker_location(t()) :: pos_integer() | WidgetInstance.no_render()
  def tiebreaker_location(%__MODULE__{} = t) do
    case LocalizedAlert.location(t) do
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
    if seconds_from_onset(t) in (4 * @week)..(12 * @week - 1) do
      1
    else
      2
    end
  end

  @spec tiebreaker_effect(t()) :: pos_integer() | WidgetInstance.no_render()
  def tiebreaker_effect(%__MODULE__{alert: alert}) do
    Keyword.get(@effect_priorities, Alert.effect(alert), :no_render)
  end

  @spec seconds_from_onset(t()) :: integer()
  def seconds_from_onset(%__MODULE__{alert: %Alert{active_period: [{start, _} | _]}, now: now})
      when not is_nil(start) do
    DateTime.diff(now, start, :second)
  end

  def audio_serialize(%__MODULE__{alert: %Alert{header: header}}),
    do: %{header: header}

  def audio_sort_key(%__MODULE__{} = t) do
    if takeover_alert?(t) do
      @automated_override_priority
    else
      @flex_zone_alert_base_priority
    end
  end

  def audio_valid_candidate?(%__MODULE__{screen: %Screen{app_id: :gl_eink_v2}}), do: true
  def audio_valid_candidate?(_instance), do: false

  def audio_view(_instance), do: ScreensWeb.V2.Audio.AlertView

  def alert_ids(%__MODULE__{} = instance), do: [instance.alert.id]

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

  defimpl Screens.V2.AlertsWidget do
    alias Screens.V2.WidgetInstance.Alert

    def alert_ids(instance), do: Alert.alert_ids(instance)
  end
end
