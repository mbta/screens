defmodule Screens.DupScreenData.Data do
  @moduledoc false

  alias Screens.Config.Dup

  def choose_alert([]), do: nil

  def choose_alert(alerts) do
    # Prioritize shuttle alerts when one exists; otherwise just choose the first in the list.
    Enum.find(alerts, hd(alerts), &(&1.effect == :shuttle))
  end

  def interpret_alert(alert, stop_ids, pill) do
    [
      %{adjacent_stops: adjacent_stops1, headsign: headsign1},
      %{adjacent_stops: adjacent_stops2, headsign: headsign2}
    ] =
      Enum.map(stop_ids, fn id ->
        :screens
        |> Application.get_env(:dup_constants)
        |> Map.get(id)
      end)

    informed_stop_ids = Enum.map(alert.informed_entities, & &1.stop)

    alert_region =
      Screens.AdjacentStops.alert_region(informed_stop_ids, adjacent_stops1, adjacent_stops2)

    {region, headsign} =
      case alert_region do
        :disruption_toward_1 -> {:boundary, headsign1}
        :disruption_toward_2 -> {:boundary, headsign2}
        :middle -> {:inside, nil}
      end

    %{
      cause: alert.cause,
      effect: alert.effect,
      region: region,
      headsign: headsign,
      pill: pill
    }
  end

  def station_line_count(%Dup.Departures{sections: [section | _]}) do
    stop_id = hd(section.stop_ids)
    if stop_id in Application.get_env(:screens, :two_line_stops), do: 2, else: 1
  end

  def limit_three_departures([[d1, d2], [d3, _d4]]), do: [[d1, d2], [d3]]
  def limit_three_departures([[d1, d2, d3, _d4]]), do: [[d1, d2, d3]]
  def limit_three_departures(sections), do: sections

  def response_type([], _, _), do: :departures

  def response_type(alerts, line_count, rotation_index) do
    if Enum.any?(alerts, &(&1.effect == :station_closure)) do
      :fullscreen_alert
    else
      response_type_helper(alerts, line_count, rotation_index)
    end
  end

  defp response_type_helper([alert], 1, rotation_index) do
    case {alert.region, rotation_index} do
      {:inside, _} -> :fullscreen_alert
      {:boundary, "0"} -> :partial_alert
      {:boundary, "1"} -> :fullscreen_alert
    end
  end

  defp response_type_helper([_alert], 2, rotation_index) do
    case rotation_index do
      "0" -> :partial_alert
      "1" -> :fullscreen_alert
    end
  end

  defp response_type_helper([_alert1, _alert2], 2, _rotation_index) do
    :fullscreen_alert
  end
end
