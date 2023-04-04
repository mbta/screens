defmodule Screens.V2.WidgetInstance.DupAlert do
  @moduledoc """
  A widget that displays an alert (either full-screen or partial) on a DUP screen.
  """

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.V2.WidgetInstance.Common.BaseAlert
  alias Screens.V2.WidgetInstance.DupAlert.Serialize

  require Logger

  @enforce_keys [
    :screen,
    :alert,
    :stop_sequences,
    :subway_routes_at_stop,
    :primary_section_count,
    :rotation_index,
    :stop_name
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          screen: Screen.t(),
          alert: Alert.t(),
          stop_sequences: list(list(stop_id)),
          subway_routes_at_stop: list(%{route_id: route_id, active?: boolean}),
          primary_section_count: pos_integer(),
          rotation_index: rotation_index,
          stop_name: String.t()
        }

  @type route_id :: String.t()
  @type stop_id :: String.t()
  @type rotation_index :: :zero | :one | :two

  @spec priority(t()) :: Screens.V2.WidgetInstance.priority()
  def priority(_t) do
    # For DUP alerts, priority is constant.
    # Barring manually configured override content, a valid alert will appear
    # on screen and is the sole decider of what template layout is used for
    # each rotation.
    [1, 2]
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

  def valid_candidate?(%__MODULE__{} = t) do
    alert_layout(t) != :no_render
  end

  @spec alert_layout(t()) :: :full_screen | :partial | :no_render
  defp alert_layout(t) do
    effect = t.alert.effect
    location = BaseAlert.location(t)
    affected_line_count = length(get_affected_lines(t))
    rotation_index = t.rotation_index

    parameters = {effect, location, affected_line_count, t.primary_section_count, rotation_index}

    special_case = alert_layout_special_case(t, parameters)

    if special_case do
      special_case
    else
      case do_alert_layout(parameters) do
        :no_render ->
          log_layout_mismatch(t, parameters, :not_applicable)
          :no_render

        layout ->
          layout
      end
    end
  end

  # The widget _should_ always be valid given the constraints of what alerts
  # we generate DUP alert widgets for, but in case one slips through, we
  # should know about it!
  defp log_layout_mismatch(t, parameters, delay_severity) do
    {effect, location, affected_line_count, total_section_count, rotation_index} = parameters

    labeled_parameters = [
      effect: effect,
      delay_severity: delay_severity,
      location: location,
      affected_line_count: affected_line_count,
      total_section_count: total_section_count,
      rotation_index: rotation_index
    ]

    identifiers = [alert_id: t.alert.id, stop_ids: Enum.join(t.screen.alerts.stop_ids, ",")]
    log_fields = identifiers ++ labeled_parameters

    Logger.info(
      "[DUP alert no matching layout] " <>
        Enum.map_join(log_fields, " ", fn {label, value} -> "#{label}=#{value}" end)
    )
  end

  # Inputs/outputs are stored as a table for readability.
  # Table is adapted from the one in the product spec: https://www.notion.so/mbta-downtown-crossing/DUP-Alert-Widget-Specification-a82acff850ed4f2eb98a04e5f3e0fe52
  # Compile-time code converts each table row to `do_alert_layout` function clauses.
  # TotalSections refers to the number of sections in `primary_departures` of DUP configs.
  alert_layout_table = """
  # INPUTS                                                          || OUTPUTS
  # Effect          Location            AffectedLines TotalSections || LayoutZero  LayoutOne
    station_closure inside              1             1                full_screen full_screen
    station_closure inside              1             2                partial     full_screen
    station_closure inside              2             2                full_screen full_screen
  # "Boundary" location is not possible for station closures.
    shuttle         inside              1             1                full_screen full_screen
    shuttle         inside              1             2                partial     full_screen
    shuttle         inside              2             2                full_screen full_screen
    shuttle         boundary_upstream   1             1                partial     full_screen
    shuttle         boundary_downstream 1             1                partial     full_screen
    shuttle         boundary_upstream   1             2                partial     full_screen
    shuttle         boundary_downstream 1             2                partial     full_screen
    suspension      inside              1             1                full_screen full_screen
    suspension      inside              1             2                partial     full_screen
    suspension      inside              2             2                full_screen full_screen
    suspension      boundary_upstream   1             1                partial     full_screen
    suspension      boundary_downstream 1             1                partial     full_screen
    suspension      boundary_upstream   1             2                partial     full_screen
    suspension      boundary_downstream 1             2                partial     full_screen
  # Other cases are handled separately, see `alert_layout_special_case` below.
  """

  parameters_to_layout =
    alert_layout_table
    |> String.split("\n", trim: true)
    |> Enum.reject(&String.starts_with?(&1, "#"))
    |> Enum.flat_map(fn line ->
      [effect, location, affected_line_count, total_section_count, layout_zero, layout_one] =
        String.split(line, ~r/\s+/, trim: true)

      # Convert strings to appropriate types
      [effect, location, layout_zero, layout_one] =
        Enum.map(
          [effect, location, layout_zero, layout_one],
          &String.to_existing_atom/1
        )

      [affected_line_count, total_section_count] =
        Enum.map([affected_line_count, total_section_count], &String.to_integer/1)

      base_parameters = {effect, location, affected_line_count, total_section_count}

      [
        {Tuple.append(base_parameters, :zero), layout_zero},
        {Tuple.append(base_parameters, :one), layout_one}
      ]
    end)
    |> Enum.into(%{})

  @type layout_parameters ::
          {Alert.effect(), location :: atom, affected_line_count :: 1..2,
           total_section_count :: 1..2, rotation_index}

  # Now, define function clauses for each row in the table.
  @spec do_alert_layout(layout_parameters) :: :full_screen | :partial | :no_render
  for {parameters, layout} <- parameters_to_layout do
    parameters_ast = Macro.escape(parameters)
    defp do_alert_layout(unquote(parameters_ast)), do: unquote(layout)
  end

  # If matching inputs aren't found in the table, we assume the alert isn't relevant and do not render it.
  defp do_alert_layout(_parameters), do: :no_render

  # Handles special cases that don't directly adhere to the table-based approach.
  # Specifically, this determines the layout for:
  #  - All delay alerts
  #  - The third rotation
  defp alert_layout_special_case(t, parameters) do
    {effect, _location, _affected_line_count, _total_section_count, rotation_index} = parameters

    delay_severity = t.alert.severity

    cond do
      effect == :delay ->
        if delay_severity >= 5 do
          # All delays >= 20 minutes get a partial alert on all 3 rotations
          :partial
        else
          # We don't show delays < 20 minutes
          log_layout_mismatch(t, parameters, delay_severity)
          :no_render
        end

      rotation_index == :two ->
        # For the third rotation, the layout depends on whether or not
        # the screen has secondary departures configured.
        #
        # If the screen has secondary departures configured, it always gets a partial alert.
        # If the screen does not have secondary departures configured, it gets the same layout as the first rotation.
        #
        # This is because we do not want to hide secondary departures (e.g. bus, CR) if they exist.
        has_secondary_departures = t.screen.app_params.secondary_departures.sections != []

        if has_secondary_departures,
          do: :partial,
          else: alert_layout(%{t | rotation_index: :zero})

      true ->
        false
    end
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

  defimpl Screens.V2.SingleAlertWidget do
    def alert(instance), do: instance.alert

    def screen(instance), do: instance.screen

    def home_stop_id(instance), do: instance.screen.app_params.alerts.stop_id

    def routes_at_stop(instance), do: instance.subway_routes_at_stop

    def stop_sequences(instance), do: instance.stop_sequences

    def headsign_matchers(_instance) do
      Application.get_env(:screens, :dup_alert_headsign_matchers)
    end
  end

  defimpl Screens.V2.AlertsWidget do
    alias Screens.V2.WidgetInstance.DupAlert

    def alert_ids(instance), do: DupAlert.alert_ids(instance)
  end
end
