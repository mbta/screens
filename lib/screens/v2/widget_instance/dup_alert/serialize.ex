defmodule Screens.V2.WidgetInstance.DupAlert.Serialize do
  @moduledoc """
  Functions to serialize data for the DUP alert widget.
  """

  alias Screens.Alerts.Alert
  alias Screens.Report
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.WidgetInstance.DupAlert
  alias ScreensConfig.FreeText
  alias ScreensConfig.FreeTextLine

  @type full_screen_alert_map :: %{
          text: FreeTextLine.t(),
          remedy: FreeTextLine.t(),
          header: %{
            text: String.t(),
            color: :red | :orange | :green | :blue | :yellow
          }
        }

  @type banner_alert_map :: %{
          text: FreeTextLine.t(),
          color: :red | :orange | :green | :blue
        }

  @gl_westbound_platforms ["Boston College", "Cleveland Circle", "Riverside", "Heath Street"]
  @gl_westbound_direction_name "Copley & West"

  @spec serialize_full_screen(DupAlert.t()) :: full_screen_alert_map
  def serialize_full_screen(t) do
    %{
      text: %FreeTextLine{icon: full_screen_issue_icon(t), text: full_screen_issue_free_text(t)},
      remedy: remedy_free_text_line(t),
      header: %{
        text: t.stop_name,
        color: line_color(t)
      }
    }
  end

  @spec serialize_banner(DupAlert.t()) :: banner_alert_map()
  def serialize_banner(t) do
    %{
      text: %FreeTextLine{icon: banner_icon(t), text: banner_free_text(t)},
      color: line_color(t)
    }
  end

  # TO BE DONE: Move these closer to the FreeText modules and make public so they're generally available.
  #             Also define similar macros for other free-text elements, e.g. `small`
  #       https://app.asana.com/0/1185117109217422/1204252210980218/f

  # Provides a pattern-matchable shorthand for bolding some text
  defmacrop bold(str) do
    quote do
      %{format: :bold, text: unquote(str)}
    end
  end

  # Provides a pattern-matchable shorthand for an inline route/line pill icon
  defmacrop free_text_pill(pill_atom) do
    quote do
      %{route: unquote(pill_atom)}
    end
  end

  defp line_color(t) do
    case DupAlert.get_affected_lines(t) do
      ["Red"] -> :red
      ["Orange"] -> :orange
      ["Green"] -> :green
      ["Blue"] -> :blue
      _multiple_lines -> :yellow
    end
  end

  defp line_to_pill_atom(line_string) do
    line_string
    |> String.downcase()
    |> String.to_existing_atom()
  end

  defp get_affected_lines_as_strings(t) do
    t
    |> DupAlert.get_affected_lines()
    |> Enum.map(&"#{&1} Line")
  end

  @spec get_affected_lines_as_pills(DupAlert.t()) :: [FreeText.t()]
  defp get_affected_lines_as_pills(t) do
    t
    |> DupAlert.get_affected_lines()
    |> Enum.map(fn line ->
      line
      |> line_to_pill_atom()
      |> free_text_pill()
    end)
  end

  defp banner_free_text(t) do
    affected_lines = get_affected_lines_as_strings(t)

    case {affected_lines, t.alert.effect, LocalizedAlert.location(t), affected_platform(t)} do
      {[line], :delay, _, _} ->
        [bold(line), "delays"]

      {[line], _, :inside, nil} ->
        ["No", bold(line), "trains"]

      {[_line], _, boundary, nil} when boundary in [:boundary_upstream, :boundary_downstream] ->
        headsign = get_headsign(t)

        ["No", bold(headsign), "trains"]
        |> partial_headsign_special_cases()

      {[_line1, _line2], :delay, _, nil} ->
        ["Train delays"]

      {[_line1, _line2], _, _, nil} ->
        ["No train service"]

      {_, :station_closure, _, platform_name} ->
        ["No", bold(platform_name)]
    end
  end

  defp banner_icon(t) when t.alert.effect == :delay,
    do: if(line_color(t) == :yellow, do: :delay_negative, else: :delay)

  defp banner_icon(t),
    do: if(line_color(t) == :yellow, do: :warning_negative, else: :warning)

  defp full_screen_issue_icon(t) when t.alert.effect == :delay, do: :delay
  defp full_screen_issue_icon(_t), do: :warning

  defp full_screen_issue_free_text(%DupAlert{alert: %Alert{effect: :delay} = alert} = t) do
    get_affected_lines_as_pills(t) ++
      [bold("delays"), alert |> Alert.delay_description() |> bold()] ++ cause_description(alert)
  end

  defp full_screen_issue_free_text(t) do
    affected_platform_name = affected_platform(t)
    affected_lines = get_affected_lines_as_pills(t)

    case {affected_platform_name, affected_lines} do
      # All platforms for a single line
      {nil, [line_pill]} ->
        no_trains = [bold("No"), line_pill, bold("trains")]

        if LocalizedAlert.location(t) in [:boundary_upstream, :boundary_downstream] do
          headsign = get_headsign(t)

          no_trains ++ [bold("to #{headsign}")]
        else
          no_trains ++ cause_description(t.alert)
        end

      # Only consider up to 2 routes - the alert widget only displays subway alerts
      # and there are no stations served by more than 2
      {nil, [line_pill1, line_pill2]} ->
        ["No", line_pill1, "or", line_pill2, "trains"]

      # Special case for GL westbound in which we include pill and direction
      {@gl_westbound_direction_name, [line_pill]} ->
        [bold("No"), line_pill, bold(@gl_westbound_direction_name)]

      # Single platform
      {platform_name, [_line_pill]} ->
        [bold("#{platform_name} platform closed")]
    end
  end

  defp cause_description(%Alert{cause: :unknown}), do: []
  defp cause_description(alert), do: ["due to", Alert.cause_description(alert)]

  defp remedy_free_text_line(t) do
    icon = remedy_icon(t)
    text = remedy_free_text(t)

    %FreeTextLine{icon: icon, text: text}
  end

  defp remedy_icon(t) do
    case t.alert.effect do
      :shuttle -> :shuttle
      _ -> nil
    end
  end

  defp remedy_free_text(t) do
    cond do
      t.alert.effect == :shuttle -> [bold("Use shuttle bus")]
      t.alert.cause == :single_tracking -> []
      true -> ["Seek alternate route"]
    end
  end

  defp get_headsign(t) do
    headsign = LocalizedAlert.get_headsign_from_informed_entities(t)

    case headsign do
      {:adj, hs} -> hs
      hs -> hs
    end
  end

  defp partial_headsign_special_cases(["No", bold("Ashmont/Braintree"), "trains"]) do
    ["No", bold("Ashmont/Braintree")]
  end

  defp partial_headsign_special_cases(["No", bold("Boston College"), "trains"]) do
    ["No", bold("Boston Coll"), "trains"]
  end

  defp partial_headsign_special_cases(["No", bold("Cleveland Circle"), "trains"]) do
    ["No", bold("Cleveland Cir"), "trains"]
  end

  defp partial_headsign_special_cases(["No", bold("North Station & North"), "trains"]) do
    ["No", bold("Northbound"), "trains"]
  end

  defp partial_headsign_special_cases(other), do: other

  @spec affected_platform(DupAlert.t()) :: String.t() | nil
  defp affected_platform(t) do
    if DupAlert.partial_station_closure?(t) do
      get_closed_platform_name(t)
    else
      # Returns nil if all platforms at station are affected
      nil
    end
  end

  @spec get_closed_platform_name(DupAlert.t()) :: String.t() | nil
  defp get_closed_platform_name(t) do
    stops_in_alert = Enum.map(t.alert.informed_entities, & &1.stop)

    platform_names =
      t
      |> DupAlert.child_stops_for_affected_line()
      |> Enum.filter(&(&1.id in stops_in_alert and &1.platform_name))
      |> Enum.map(& &1.platform_name)

    case platform_names do
      [platform_name] ->
        platform_name

      [] ->
        nil

      multiple_platforms ->
        if Enum.all?(multiple_platforms, &(&1 in @gl_westbound_platforms)) do
          @gl_westbound_direction_name
        else
          # We should not end up in this state, barring an unexpected type of alert
          Report.warning("unexpected_platform_closure_dup",
            alert_id: t.alert.id,
            home_stop: t.location_context.home_stop
          )

          nil
        end
    end
  end
end
