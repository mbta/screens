defmodule Screens.V2.WidgetInstance.DupAlert.Serialize do
  @moduledoc """
  Functions to serialize data for the DUP alert widget.
  """

  alias Screens.Alerts.Alert
  alias ScreensConfig.V2.FreeTextLine
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.WidgetInstance.DupAlert

  @type full_screen_alert_map :: %{
          text: FreeTextLine.t(),
          remedy: FreeTextLine.t(),
          header: %{
            text: String.t(),
            color: :red | :orange | :green | :blue | :yellow
          }
        }

  @type partial_alert_map :: %{
          text: FreeTextLine.t(),
          color: :red | :orange | :green | :blue
        }

  @spec serialize_full_screen(DupAlert.t()) :: full_screen_alert_map
  def serialize_full_screen(t) do
    %{
      text: %FreeTextLine{icon: :warning, text: issue_free_text(t)},
      remedy: remedy_free_text_line(t),
      header: %{
        text: t.stop_name,
        color: line_color(t)
      }
    }
  end

  @spec serialize_partial(DupAlert.t()) :: partial_alert_map
  def serialize_partial(t) do
    %{
      text: %FreeTextLine{icon: partial_alert_icon(t), text: partial_alert_free_text(t)},
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

  defp get_affected_lines_as_pills(t) do
    t
    |> DupAlert.get_affected_lines()
    |> Enum.map(fn line ->
      line
      |> line_to_pill_atom()
      |> free_text_pill()
    end)
  end

  defp partial_alert_free_text(t) do
    affected_lines = get_affected_lines_as_strings(t)

    case {affected_lines, t.alert.effect, LocalizedAlert.location(t)} do
      {[line], :delay, _} ->
        [bold(line), "delays"]

      {[line], _, :inside} ->
        ["No", bold(line), "trains"]

      {[_line], _, boundary} when boundary in [:boundary_upstream, :boundary_downstream] ->
        headsign = get_headsign(t)

        ["No", bold(headsign), "trains"]
        |> partial_headsign_special_cases()

      {[_line1, _line2], :delay, _} ->
        ["Train delays"]

      {[_line1, _line2], _, _} ->
        ["No train service"]
    end
  end

  defp partial_alert_icon(t) when t.alert.effect == :delay, do: :delay

  defp partial_alert_icon(t),
    do: if(line_color(t) == :yellow, do: :warning_negative, else: :warning)

  defp issue_free_text(t) do
    affected_lines = get_affected_lines_as_pills(t)

    case affected_lines do
      [line_pill] ->
        no_trains = [bold("No"), line_pill, bold("trains")]

        if LocalizedAlert.location(t) in [:boundary_upstream, :boundary_downstream] do
          headsign = get_headsign(t)

          no_trains ++ [bold("to #{headsign}")]
        else
          no_trains ++ [Alert.get_cause_string(t.alert.cause)]
        end

      [line_pill1, line_pill2] ->
        ["No", line_pill1, "or", line_pill2, "trains"]
    end
  end

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
    case t.alert.effect do
      :shuttle -> [bold("Use shuttle bus")]
      _ -> ["Seek alternate route"]
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
end
