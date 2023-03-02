defmodule Screens.V2.WidgetInstance.DupAlert do
  @moduledoc """
  A widget that displays an alert (either full-screen or partial) on a DUP screen.
  """

  require Logger

  alias Screens.Config.Dup.Override.FreeText
  alias Screens.Config.Dup.Override.FreeTextLine
  alias Screens.Config.Screen
  alias Screens.Alerts.Alert
  alias Screens.V2.WidgetInstance.Common.BaseAlert
  alias Screens.V2.WidgetInstance.DupAlert.Serialize

  @enforce_keys [:screen, :alert, :stop_sequences, :routes_at_stop, :rotation_index, :stop_name]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          screen: Screen.t(),
          alert: Alert.t(),
          stop_sequences: list(list(stop_id)),
          # Only subway routes are listed in this field.
          # TODO: rename to something more descriptive once BaseAlert
          # is updated to not directly access struct fields of alert widgets
          # by name (it expects the field to be named `routes_at_stop`).
          routes_at_stop: list(%{route_id: route_id, active?: boolean}),
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
      :full_screen -> serialize_full_screen(t)
      :partial -> serialize_partial(t)
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

  @spec serialize_full_screen(t()) :: %{
          alert_text: %FreeTextLine{icon: :warning, text: list(FreeText.t())},
          color: :red | :orange | :green | :blue,
          remedy: %FreeTextLine{icon: :shuttle | nil, text: list(FreeText.t())},
          header: %{
            icon: :logo,
            text: String.t(),
            pattern: :hatched,
            color: :red | :orange | :green | :blue
          }
        }
  defp serialize_full_screen(t) do
    color = Serialize.route_color(t)
    remedy_icon = Serialize.remedy_icon(t)
    issue_text = Serialize.issue_free_text(t)
    remedy_text = Serialize.remedy_free_text(t)

    %{
      alert_text: %FreeTextLine{icon: :warning, text: issue_text},
      color: color,
      remedy: %FreeTextLine{icon: remedy_icon, text: remedy_text},
      header: %{
        text: t.stop_name,
        pattern: :hatched,
        color: color
      }
    }
  end

  @spec serialize_partial(t()) :: %{
          alert_text: %FreeTextLine{icon: :warning, text: list(FreeText.t())},
          color: :red | :orange | :green | :blue
        }
  defp serialize_partial(t) do
    text = Serialize.partial_alert_free_text(t)
    color = Serialize.route_color(t)

    %{
      alert_text: %FreeTextLine{icon: :warning, text: text},
      color: color
    }
  end

  @spec alert_layout(t()) :: :full_screen | :partial | :no_render
  defp alert_layout(t) do
    effect = t.alert.effect
    location = BaseAlert.location(t)
    affected_lines = MapSet.size(BaseAlert.informed_routes_at_home_stop(t))
    total_lines = MapSet.size(BaseAlert.active_routes_at_stop(t))
    rotation_index = t.rotation_index

    parameters = {effect, location, affected_lines, total_lines, rotation_index}

    delay_severity = t.alert.severity

    if effect == :delay and delay_severity < 5 do
      # We don't show delays < 20 minutes
      log_layout_mismatch(t, parameters, delay_severity)
      :no_render
    else
      case do_alert_layout(parameters) do
        :no_render ->
          log_layout_mismatch(t, parameters, delay_severity)
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
    {effect, location, affected_lines, total_lines, rotation_index} = parameters

    labeled_parameters = [
      effect: effect,
      delay_severity: delay_severity,
      location: location,
      affected_lines: affected_lines,
      total_lines: total_lines,
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
  alert_layout_table = """
  # INPUTS                                                       || OUTPUTS
  # Effect          Location            AffectedLines TotalLines || LayoutZero  LayoutOne   LayoutTwo
    station_closure inside              1             1             full_screen full_screen partial
    station_closure inside              1             2             partial     full_screen partial
    station_closure inside              2             2             full_screen full_screen partial
  # "Boundary" location is not possible for station closures.
    shuttle         inside              1             1             full_screen full_screen partial
    shuttle         inside              1             2             partial     full_screen partial
    shuttle         inside              2             2             full_screen full_screen partial
    shuttle         boundary_upstream   1             1             partial     full_screen partial
    shuttle         boundary_downstream 1             1             partial     full_screen partial
    shuttle         boundary_upstream   1             2             partial     full_screen partial
    shuttle         boundary_downstream 1             2             partial     full_screen partial
    suspension      inside              1             1             full_screen full_screen partial
    suspension      inside              1             2             partial     full_screen partial
    suspension      inside              2             2             full_screen full_screen partial
    suspension      boundary_upstream   1             1             partial     full_screen partial
    suspension      boundary_downstream 1             1             partial     full_screen partial
    suspension      boundary_upstream   1             2             partial     full_screen partial
    suspension      boundary_downstream 1             2             partial     full_screen partial
  # Delay alerts are handled separately, see `defp do_alert_layout({:delay, ...` below.
  """

  parameters_to_layout =
    alert_layout_table
    |> String.split("\n", trim: true)
    |> Enum.reject(&String.starts_with?(&1, "#"))
    |> Enum.flat_map(fn line ->
      [
        effect,
        location,
        affected_lines,
        total_lines,
        layout_zero,
        layout_one,
        layout_two
      ] = String.split(line, ~r/\s+/, trim: true)

      # Convert strings to appropriate types
      [effect, location, layout_zero, layout_one, layout_two] =
        Enum.map(
          [effect, location, layout_zero, layout_one, layout_two],
          &String.to_existing_atom/1
        )

      [affected_lines, total_lines] =
        Enum.map([affected_lines, total_lines], &String.to_integer/1)

      base_parameters = {effect, location, affected_lines, total_lines}

      [
        {Tuple.append(base_parameters, :zero), layout_zero},
        {Tuple.append(base_parameters, :one), layout_one},
        {Tuple.append(base_parameters, :two), layout_two}
      ]
    end)
    |> Enum.into(%{})

  @type layout_parameters ::
          {Alert.effect(), location :: atom, affected_lines :: 1..2, total_lines :: 1..2,
           rotation_index}

  # Now, define function clauses for each row in the table.
  @spec do_alert_layout(layout_parameters) :: :full_screen | :partial | :no_render
  for {parameters, layout} <- parameters_to_layout do
    parameters_ast = Macro.escape(parameters)
    defp do_alert_layout(unquote(parameters_ast)), do: unquote(layout)
  end

  # Delays always use partial alerts on all 3 rotations of the screen.
  defp do_alert_layout({:delay, _location, _affected_lines, _total_lines, _rotation_index}) do
    :partial
  end

  # If matching inputs aren't found in the table, we assume the alert isn't relevant and do not render it.
  defp do_alert_layout(_parameters), do: :no_render

  def alert_id(%__MODULE__{} = t), do: t.alert.id

  ### Required audio callbacks. The widget does not have audio equivalence, so these are "stubbed".

  def audio_serialize(_t) do
    nil
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

  defimpl Screens.V2.AlertWidgetInstance do
    alias Screens.V2.WidgetInstance.DupAlert

    def alert_id(instance), do: DupAlert.alert_id(instance)
  end
end
