defmodule Screens.V2.WidgetInstance.DupAlert do
  @moduledoc """
  A widget that displays an alert (either full-screen or partial) on a DUP screen.
  """

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.WidgetInstance.DupAlert.Serialize
  alias ScreensConfig.{Departures, Screen, Screen.Dup}

  @enforce_keys [:screen, :alert, :location_context, :rotation_index, :stop_name]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          screen: Screen.t(),
          alert: Alert.t(),
          location_context: LocationContext.t(),
          rotation_index: rotation_index,
          stop_name: String.t()
        }

  @type route_id :: String.t()
  @type stop_id :: String.t()
  @type rotation_index :: :zero | :one | :two

  @spec priority(t()) :: Screens.V2.WidgetInstance.priority()
  def priority(t) do
    # Overnight mode should take priority over partial alerts but not full_screen.
    # Giving full_screen the highest priority so it will always show over overnight.
    case alert_layout(t) do
      :full_screen -> [1]
      :partial -> [1, 2]
    end
  end

  @spec serialize(t()) :: map()
  def serialize(t) do
    case alert_layout(t) do
      :full_screen -> Serialize.serialize_full_screen(t)
      :partial -> Serialize.serialize_partial(t)
    end
  end

  @spec slot_names(t()) :: list(Screens.V2.WidgetInstance.slot_id())
  def slot_names(t) do
    base_slot_name =
      case alert_layout(t) do
        :full_screen -> "full_rotation"
        :partial -> "bottom_pane"
      end

    # Returns e.g. [:full_rotation_zero], [:bottom_pane_one], ...
    [:"#{base_slot_name}_#{t.rotation_index}"]
  end

  @spec widget_type(t()) :: :takeover_alert | :partial_alert
  def widget_type(%__MODULE__{} = t) do
    case alert_layout(t) do
      :full_screen -> :takeover_alert
      :partial -> :partial_alert
    end
  end

  @spec valid_candidate?(t()) :: boolean()
  def valid_candidate?(%__MODULE__{}), do: true

  # Determine the desired layout for this alert. Follows the rules documented here:
  # https://www.notion.so/mbta-downtown-crossing/DUP-Alert-Widget-Specification-17cf5d8d11ea80399a7fe3c4f13a511f
  @spec alert_layout(t()) :: :full_screen | :partial
  defp alert_layout(%__MODULE__{rotation_index: :zero} = t), do: rotation_zero_layout(t)

  defp alert_layout(%__MODULE__{rotation_index: :one} = t) do
    if eliminated_service_type(t) == :none, do: :partial, else: :full_screen
  end

  # When no secondary departures are configured, departures in this rotation will be the same as
  # those in rotation zero, so use the same layout.
  defp alert_layout(
         %__MODULE__{
           rotation_index: :two,
           screen: %Screen{app_params: %Dup{secondary_departures: %Departures{sections: []}}}
         } = t
       ),
       do: rotation_zero_layout(t)

  defp alert_layout(%__MODULE__{rotation_index: :two}), do: :partial

  defp rotation_zero_layout(t) do
    if eliminated_service_type(t) == :all, do: :full_screen, else: :partial
  end

  # Determine whether this alert "eliminates service" entirely, partially, or not at all, at the
  # screen's station, for the routes in primary departures.
  @spec eliminated_service_type(t()) :: :all | :some | :none
  defp eliminated_service_type(
         %__MODULE__{
           alert: %Alert{effect: effect},
           screen: %Screen{
             app_params: %Dup{primary_departures: %Departures{sections: primary_sections}}
           }
         } = t
       )
       when effect in [:shuttle, :station_closure, :suspension] do
    # Assume primary departures is always configured with a section for each subway line at the
    # screen's station. So if we're `inside` a disruption and it affects the same number of lines
    # as the number we show departures for, that means all service is eliminated. Otherwise, only
    # some is (either we're at a boundary and there's still service in one direction, or we're at
    # a transfer station and the alert only affects one line).
    if LocalizedAlert.location(t) == :inside and
         length(get_affected_lines(t)) == length(primary_sections),
       do: :all,
       else: :some
  end

  defp eliminated_service_type(_other), do: :none

  def get_affected_lines(t) do
    t
    |> LocalizedAlert.informed_routes_at_home_stop()
    |> routes_to_lines()
  end

  # For certain parts of the DUP alert logic, we're only interested in subway lines,
  # not routes. This merges all of the "Green-B/C/D/E" routes into just "Green".
  defp routes_to_lines(route_ids) do
    route_ids
    |> Enum.map(fn
      "Green-" <> _branch -> "Green"
      other_subway_route -> other_subway_route
    end)
    |> Enum.uniq()
  end

  def alert_ids(%__MODULE__{} = t), do: [t.alert.id]

  ### Required audio callbacks. The widget does not have audio equivalence, so these are "stubbed".

  def audio_serialize(_t) do
    %{}
  end

  def audio_sort_key(_t) do
    [0]
  end

  def audio_valid_candidate?(_t) do
    false
  end

  def audio_view(_t) do
    nil
  end

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.DupAlert

    def priority(instance), do: DupAlert.priority(instance)
    def serialize(instance), do: DupAlert.serialize(instance)
    def slot_names(instance), do: DupAlert.slot_names(instance)
    def widget_type(instance), do: DupAlert.widget_type(instance)
    def valid_candidate?(instance), do: DupAlert.valid_candidate?(instance)
    def audio_serialize(instance), do: DupAlert.audio_serialize(instance)
    def audio_sort_key(instance), do: DupAlert.audio_sort_key(instance)
    def audio_valid_candidate?(instance), do: DupAlert.audio_valid_candidate?(instance)
    def audio_view(instance), do: DupAlert.audio_view(instance)
  end

  defimpl Screens.V2.AlertsWidget do
    alias Screens.V2.WidgetInstance.DupAlert

    def alert_ids(instance), do: DupAlert.alert_ids(instance)
  end
end
