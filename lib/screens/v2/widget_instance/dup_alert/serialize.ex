defmodule Screens.V2.WidgetInstance.DupAlert.Serialize do
  @moduledoc """
  Functions to serialize data for the DUP alert widget.
  """

  alias Screens.Alerts.Alert
  alias Screens.Config.V2.FreeTextLine
  alias Screens.V2.WidgetInstance.Common.BaseAlert
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

  # TO BE DONE: Move these closer to the FreeText modules and make public so they're generally available
  #       https://app.asana.com/0/1185117109217422/1204252210980218/f
  # Provides a pattern-matchable shorthand for bolding some text
  defmacrop bold(str) do
    quote do
      %{format: :bold, text: unquote(str)}
    end
  end

  # Provides a pattern-matchable shorthand for shrinking some text
  defmacrop small(str) do
    quote do
      %{format: :small, text: unquote(str)}
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

  defp get_line_text_builder(t) do
    case DupAlert.get_affected_lines(t) do
      [line_color] ->
        fn _ -> [bold("#{line_color} Line")] end

      [line_color1, line_color2] ->
        fn and_or -> [bold("#{line_color1} Line"), and_or, bold("#{line_color2} Line")] end
    end
  end

  defp partial_alert_free_text(t) do
    build_line_text = get_line_text_builder(t)

    affected_line_count = length(DupAlert.get_affected_lines(t))

    case {affected_line_count, t.alert.effect, BaseAlert.location(t)} do
      {1, :delay, _} ->
        build_line_text.("and") ++ ["delays"]

      {1, _, :inside} ->
        ["No"] ++ build_line_text.("or") ++ ["trains"]

      {1, _, boundary} when boundary in [:boundary_upstream, :boundary_downstream] ->
        headsign = get_headsign(t)

        ["No", bold(headsign), "trains"]
        |> partial_headsign_special_cases()

      {2, :delay, _} ->
        ["Train delays"]

      {2, _, _} ->
        ["No train service"]
    end
  end

  defp partial_alert_icon(t) when t.alert.effect == :delay, do: :delay

  defp partial_alert_icon(t),
    do: if(line_color(t) === :yellow, do: :warning_negative, else: :warning)

  defp issue_free_text(t) do
    build_line_text = get_line_text_builder(t)

    case length(DupAlert.get_affected_lines(t)) do
      1 ->
        if BaseAlert.location(t) in [:boundary_upstream, :boundary_downstream] do
          headsign = get_headsign(t)

          ["No"] ++ build_line_text.("or") ++ ["trains to #{headsign}"]
        else
          ["No"] ++
            build_line_text.("or") ++ ["trains", small(Alert.get_cause_string(t.alert.cause))]
        end

      2 ->
        ["No"] ++ build_line_text.("or") ++ ["trains"]
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
    text =
      case t.alert.effect do
        :shuttle -> "Use shuttle bus"
        _ -> "Seek alternate route"
      end

    [bold(text)]
  end

  defp get_headsign(t) do
    headsign = BaseAlert.get_headsign_from_informed_entities(t)

    if is_nil(headsign) do
      raise(
        "[DUP v2 no headsign] Could not determine headsign for DUP alert alert_id=#{t.alert.id}"
      )
    end

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
