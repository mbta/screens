defmodule Screens.DupScreenData.Data do
  @moduledoc false

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
        if alert_region_match?(to_set(informed), to_set(not_informed), informed_stop_ids),
          do: {:boundary, headsign},
          else: false
      end)

    %{
      cause: alert.cause,
      effect: alert.effect,
      region: region,
      headsign: headsign,
      pill: pill
    }
  end

  def alert_routes_at_station(alert, [parent_stop_id]) do
    filter_fn = fn
      %{stop: stop_id} -> stop_id == parent_stop_id
      _ -> false
    end

    route_fn = fn
      %{route: route_id} -> [route_id]
      _ -> []
    end

    alert.informed_entities
    |> Enum.filter(filter_fn)
    |> Enum.flat_map(route_fn)
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

  defp to_set(stop_id) when is_binary(stop_id), do: MapSet.new([stop_id])
  defp to_set(stop_ids) when is_list(stop_ids), do: MapSet.new(stop_ids)
  defp to_set(%MapSet{} = already_a_set), do: already_a_set

  defp alert_region_match?(informed, not_informed, informed_stop_ids) do
    MapSet.subset?(informed, informed_stop_ids) and
      MapSet.disjoint?(not_informed, informed_stop_ids)
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
