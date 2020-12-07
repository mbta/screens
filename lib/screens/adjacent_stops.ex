defmodule Screens.AdjacentStops do
  @moduledoc false

  @type t :: {adjacent_stop(), adjacent_stop()}

  @type adjacent_stop :: String.t()
    | MapSet.t(String.t())
    | nil

  def for_stop_id(stop_id) do
    :screens
    |> Application.get_env(:adjacent_stops)
    |> Map.get(stop_id)
  end

  @spec alert_region(list(String.t()), t(), t()) :: :middle | :disruption_toward_1 | :disruption_toward_2
  def alert_region(informed_stop_ids, adjacent_stops1, adjacent_stops2) do
    {prev_stop1, next_stop1} = adjacent_stops1
    {prev_stop2, next_stop2} = adjacent_stops2

    result1 = {
      in_informed_stop_ids?(informed_stop_ids, prev_stop1),
      in_informed_stop_ids?(informed_stop_ids, next_stop1)
    }

    result2 = {
      in_informed_stop_ids?(informed_stop_ids, prev_stop2),
      in_informed_stop_ids?(informed_stop_ids, next_stop2)
    }

    case {result1, result2} do
      # [disruption] <- [good service]
      {{true, false}, {false, true}} -> :disruption_toward_1
      # [good service] -> [disruption]
      {{false, true}, {true, false}} -> :disruption_toward_2
      # We might handle additional cases later,
      # but for now we consider everything else as middle of the region.
      _ -> :middle
    end
  end

  defp in_informed_stop_ids?(informed_stop_ids, adjacent_stop)

  defp in_informed_stop_ids?(informed_stop_ids, nil), do: false

  defp in_informed_stop_ids?(informed_stop_ids, adjacent_stop)
    when is_binary(adjacent_stop)
  do
    adjacent_stop in informed_stop_ids
  end

  defp in_informed_stop_ids?(informed_stop_ids, adjacent_stop_set) do
    Enum.any?(informed_stop_ids, &MapSet.member?(adjacent_stop_set, &1))
  end
end
