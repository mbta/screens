defmodule Screens.DupScreenData.Data do
  @moduledoc false

  alias Screens.Config.Dup

  def choose_alert([]), do: nil

  def choose_alert(alerts) do
    # Prioritize shuttle alerts when one exists; otherwise just choose the first in the list.
    Enum.find(alerts, hd(alerts), &(&1.effect == :shuttle))
  end

  def interpret_alert(alert, [parent_stop_id], pill) do
    informed_stop_ids = Enum.into(alert.informed_entities, MapSet.new(), & &1.stop)

    {region, headsign} =
      :screens
      |> Application.get_env(:dup_alert_headsign_matchers)
      |> Map.get(parent_stop_id)
      |> Enum.find_value({:inside, nil}, fn {informed, not_informed, headsign} ->
        if alert_region_match?(informed, not_informed, informed_stop_ids), do: {:boundary, headsign}, else: false
      end)

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

  defp alert_region_match?(%MapSet{} = informed, %MapSet{} = not_informed, %MapSet{} = informed_stop_ids) do
    MapSet.subset?(informed, informed_stop_ids) and MapSet.disjoint?(not_informed, informed_stop_ids)
  end

  defp alert_region_match?(informed, not_informed, informed_stop_ids) when is_binary(informed) do
    alert_region_match?(MapSet.new([informed]), not_informed, informed_stop_ids)
  end

  defp alert_region_match?(informed, not_informed, informed_stop_ids) when is_binary(not_informed) do
    alert_region_match?(informed, MapSet.new([not_informed]), informed_stop_ids)
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
