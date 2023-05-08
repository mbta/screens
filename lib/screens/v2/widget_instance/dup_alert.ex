defmodule Screens.V2.WidgetInstance.DupAlert do
  @moduledoc """
  A widget that displays an alert (either full-screen or partial) on a DUP screen.
  """

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.LocationContext
  alias Screens.V2.WidgetInstance.Common.BaseAlert
  alias Screens.V2.WidgetInstance.DupAlert.Serialize

  require Logger

  @enforce_keys [
    :screen,
    :alert,
    :location_context,
    :primary_section_count,
    :rotation_index,
    :stop_name
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          screen: Screen.t(),
          alert: Alert.t(),
          location_context: LocationContext.t(),
          primary_section_count: pos_integer(),
          rotation_index: rotation_index,
          stop_name: String.t()
        }

  @type route_id :: String.t()
  @type stop_id :: String.t()
  @type rotation_index :: :zero | :one | :two

  @spec priority(t()) :: Screens.V2.WidgetInstance.priority()
  def priority(t) do
    # For DUP alerts, priority is based on layout.
    # Overnight mode should take priority over partial alerts but not full_screen.
    # Giving full_screen the highest priority so it will always show over overnight.
    if alert_layout(t) == :full_screen do
      [1]
    else
      [1, 2]
    end
  end

  @spec serialize(t()) :: map()
  def serialize(t) do
    case alert_layout(t) do
      :full_screen -> Serialize.serialize_full_screen(t)
      :partial -> Serialize.serialize_partial(t)
      # This case will never match since it would be filtered out at `valid_candidate?`,
      # but Dialyzer doesn't know that.
      :no_render -> %{}
    end
  end

  @spec slot_names(t()) :: list(Screens.V2.WidgetInstance.slot_id())
  def slot_names(t) do
    base_slot_name =
      case alert_layout(t) do
        :full_screen -> "full_rotation"
        :partial -> "bottom_pane"
        # This case will never match since it would be filtered out at `valid_candidate?`,
        # but Dialyzer doesn't know that.
        :no_render -> "bottom_pane"
      end

    # Returns e.g. [:full_rotation_zero], [:bottom_pane_one], ...
    [:"#{base_slot_name}_#{t.rotation_index}"]
  end

  @spec widget_type(t()) :: :takeover_alert | :partial_alert
  def widget_type(%__MODULE__{} = t) do
    case alert_layout(t) do
      :full_screen -> :takeover_alert
      :partial -> :partial_alert
      # This case will never match since it would be filtered out at `valid_candidate?`,
      # but Dialyzer doesn't know that.
      :no_render -> :partial_alert
    end
  end

  @spec valid_candidate?(t()) :: boolean()
  def valid_candidate?(%__MODULE__{} = t) do
    alert_layout(t) != :no_render
  end

  # Inputs/output are stored as a table for readability.
  # Table is adapted from the one in the product spec: https://www.notion.so/mbta-downtown-crossing/DUP-Alert-Widget-Specification-a82acff850ed4f2eb98a04e5f3e0fe52
  # Compile-time code converts each table row to a key-value pair in a map.
  # PrimarySections refers to the number of sections in `primary_departures` of DUP config.
  #
  # Delay alerts are handled separately, see `delay_alert_layout` below.
  # Layouts for rotations one and two are derived from the layout for rotation zero, see `non_delay_alert_layout` below.
  layout_zero_table = """
  # INPUTS                                                            || OUTPUT
  # Effect          Location            AffectedLines PrimarySections || LayoutZero
    station_closure inside              1             1                  full_screen
    station_closure inside              1             2                  partial
    station_closure inside              2             2                  full_screen
  # "Boundary" location is not possible for station closures.
    shuttle         inside              1             1                  full_screen
    shuttle         inside              1             2                  partial
    shuttle         inside              2             2                  full_screen
    shuttle         boundary_upstream   1             1                  partial
    shuttle         boundary_downstream 1             1                  partial
    shuttle         boundary_upstream   1             2                  partial
    shuttle         boundary_downstream 1             2                  partial
    suspension      inside              1             1                  full_screen
    suspension      inside              1             2                  partial
    suspension      inside              2             2                  full_screen
    suspension      boundary_upstream   1             1                  partial
    suspension      boundary_downstream 1             1                  partial
    suspension      boundary_upstream   1             2                  partial
    suspension      boundary_downstream 1             2                  partial
  """

  @parameters_to_layout_zero layout_zero_table
                             |> String.split("\n", trim: true)
                             |> Enum.reject(&String.starts_with?(&1, "#"))
                             |> Enum.into(%{}, fn line ->
                               [
                                 effect,
                                 location,
                                 affected_line_count,
                                 primary_section_count,
                                 layout_zero
                               ] = String.split(line, ~r/\s+/, trim: true)

                               # Convert strings to appropriate types
                               [effect, location, layout_zero] =
                                 Enum.map(
                                   [effect, location, layout_zero],
                                   &String.to_existing_atom/1
                                 )

                               [affected_line_count, primary_section_count] =
                                 Enum.map(
                                   [affected_line_count, primary_section_count],
                                   &String.to_integer/1
                                 )

                               parameters = %{
                                 effect: effect,
                                 location: location,
                                 affected_line_count: affected_line_count,
                                 primary_section_count: primary_section_count
                               }

                               {parameters, layout_zero}
                             end)

  defp get_layout_parameters(t) do
    %{
      effect: t.alert.effect,
      location: BaseAlert.location(t),
      affected_line_count: length(get_affected_lines(t)),
      primary_section_count: t.primary_section_count
    }
  end

  @spec alert_layout(t()) :: :full_screen | :partial | :no_render
  defp alert_layout(t) do
    if t.alert.effect == :delay,
      do: delay_alert_layout(t),
      else: non_delay_alert_layout(t)
  end

  defp delay_alert_layout(t) do
    delay_severity = t.alert.severity

    if delay_severity >= 5 do
      # All delays >= 20 minutes get a partial alert on all 3 rotations
      :partial
    else
      # We don't show delays < 20 minutes
      log_layout_mismatch(t, delay_severity)
      :no_render
    end
  end

  defp non_delay_alert_layout(t) do
    parameters = get_layout_parameters(t)

    lookup_result = Map.fetch(@parameters_to_layout_zero, parameters)

    case {t.rotation_index, lookup_result} do
      {:zero, {:ok, layout_zero}} ->
        # The first page's layout maps directly from `parameters`.
        layout_zero

      {:one, {:ok, _layout_zero}} ->
        # The second page always uses full-screen layout, as long as the alert is relevant.
        :full_screen

      {:two, {:ok, layout_zero}} ->
        # The third page's layout depends on whether or not the screen has secondary departures configured.
        #
        # If the screen has secondary departures configured, it always gets a partial alert.
        # If the screen does not have secondary departures configured, it gets the same layout as the first page.
        #
        # This is because we do not want to hide secondary departures (e.g. bus, CR) if they exist.
        has_secondary_departures = t.screen.app_params.secondary_departures.sections != []

        if has_secondary_departures,
          do: :partial,
          else: layout_zero

      {_rotation_index, :error} ->
        # We don't know what to do under these conditions.
        # Log it, and prevent the alert from appearing.
        log_layout_mismatch(t, :not_applicable)
        :no_render
    end
  end

  # The widget _should_ always be valid given the constraints of what alerts
  # we generate DUP alert widgets for, but in case one slips through, we
  # should know about it!
  defp log_layout_mismatch(t, delay_severity) do
    log_fields =
      t
      |> get_layout_parameters()
      |> Map.merge(%{
        delay_severity: delay_severity,
        rotation_index: t.rotation_index,
        alert_id: t.alert.id,
        stop_id: t.screen.app_params.alerts.stop_id
      })

    Logger.warn(
      "[DUP alert no matching layout] " <>
        Enum.map_join(log_fields, " ", fn {label, value} -> "#{label}=#{value}" end)
    )
  end

  def get_affected_lines(t) do
    t
    |> BaseAlert.informed_routes_at_home_stop()
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
