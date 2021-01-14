defmodule Screens.DupScreenData.Response do
  @moduledoc false

  @pill_to_specifier %{
    red: "Red Line",
    orange: "Orange Line",
    green: "Green Line",
    blue: "Blue Line",
    mattapan: "Mattapan Line"
  }

  def render_headway_lines(pill, {lo, hi}, num_rows) do
    case num_rows do
      2 ->
        %{icon: pill, text: ["every", %{format: :bold, text: "#{lo}-#{hi}"}, "minutes"]}

      4 ->
        %{
          icon: "subway-negative-black",
          text: [
            %{color: pill, text: @pill_to_specifier |> Map.get(pill) |> String.upcase()},
            %{special: :break},
            "every",
            %{format: :bold, text: "#{lo}-#{hi}"},
            "minutes"
          ]
        }
    end
  end

  def render_partial_alerts([alert]) do
    [
      %{
        affected: alert.pill,
        content: render_partial_alert_content(alert)
      }
    ]
  end

  defp render_partial_alert_content(alert) do
    {specifier, service_or_trains} = partial_alert_specifier(alert)

    %{
      icon: :warning,
      text: [%{format: :bold, text: "No #{specifier}"}, service_or_trains]
    }
  end

  for {pill, specifier} <- @pill_to_specifier do
    defp partial_alert_specifier(%{headsign: nil, pill: unquote(pill)}) do
      {unquote(specifier), "service"}
    end
  end

  defp partial_alert_specifier(%{headsign: headsign}) do
    {headsign, "trains"}
  end

  def pattern(_, :delay, _), do: :hatched
  def pattern(_, :shuttle, 1), do: :x
  def pattern(_, :shuttle, 2), do: :chevron
  def pattern(:inside, :suspension, 1), do: :x
  def pattern(_, :suspension, _), do: :chevron
  def pattern(_, :station_closure, _), do: :x

  def color(_, _, 2, 2), do: :yellow
  def color(pill, :station_closure, 1, _), do: line_color(pill)
  def color(_, :station_closure, 2, _), do: :yellow
  def color(pill, _, _, _), do: line_color(pill)

  @alert_cause_mapping %{
    an_earlier_mechanical_problem: "due to an earlier mechanical problem",
    an_earlier_signal_problem: "due to an earlier signal problem",
    construction: "for construction",
    crossing_malfunction: "due to a crossing malfunction",
    demonstration: "due to a nearby demonstration",
    disabled_train: "due to a disabled train",
    electrical_work: "for electrical work",
    fire: "due to a fire",
    hazmat_condition: "due to hazardous conditions",
    heavy_ridership: "due to heavy ridership",
    high_winds: "due to high winds",
    holiday: "for the holiday",
    hurricane: "due to severe weather",
    maintenance: "for maintenance",
    mechanical_problem: "due to a mechanical problem",
    medical_emergency: "due to a medical emergency",
    parade: "for a parade",
    police_action: "due to police action",
    power_problem: "due to a power issue",
    severe_weather: "due to severe weather",
    signal_problem: "due to a signal problem",
    slippery_rail: "due to slippery rails",
    snow: "due to snow conditions",
    special_event: "for a special event",
    speed_restriction: "due to a speed restriction",
    switch_problem: "due to a switch problem",
    tie_replacement: "for maintenance",
    track_problem: "due to a track problem",
    track_work: "for track work",
    unruly_passenger: "due to an unruly passenger",
    weather: "due to weather conditions"
  }

  for {cause, cause_text} <- @alert_cause_mapping do
    defp render_alert_cause(unquote(cause)) do
      unquote(cause_text)
    end
  end

  defp render_alert_cause(_) do
    ""
  end

  def alert_issue(%{effect: :delay, cause: cause}) do
    %{
      icon: :warning,
      text: [%{format: :bold, text: "SERVICE DISRUPTION"}, render_alert_cause(cause)]
    }
  end

  def alert_issue(%{region: :inside, cause: cause}) do
    %{icon: :x, text: [%{format: :bold, text: "STATION CLOSED"}, render_alert_cause(cause)]}
  end

  def alert_issue(%{region: :boundary, pill: pill, headsign: headsign}) do
    %{
      icon: :warning,
      text: [
        %{format: :bold, text: "No #{@pill_to_specifier[pill]}"},
        "service to #{headsign}"
      ]
    }
  end

  def alert_remedy(alert) do
    icon = alert_remedy_icon(alert.effect)
    line = [%{format: :bold, text: alert_remedy_text(alert.effect)}]

    %{icon: icon, text: line}
  end

  @alert_remedy_text_mapping %{
    delay: "Expect delays",
    shuttle: "Use shuttle bus",
    suspension: "Seek alternate route",
    station_closure: "Seek alternate route"
  }

  for {effect, remedy} <- @alert_remedy_text_mapping do
    defp alert_remedy_text(unquote(effect)) do
      unquote(remedy)
    end
  end

  @alert_remedy_icon_mapping %{
    delay: nil,
    shuttle: :shuttle,
    suspension: nil,
    station_closure: nil
  }

  for {effect, icon} <- @alert_remedy_icon_mapping do
    defp alert_remedy_icon(unquote(effect)) do
      unquote(icon)
    end
  end

  defp line_color(:mattapan), do: :red
  defp line_color(pill), do: pill
end
