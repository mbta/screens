defmodule Screens.Headways do
  @moduledoc false

  @dayparts [
    {:early_morning, :open, ~T[06:30:00]},
    {:am_peak, ~T[06:30:00], ~T[09:00:00]},
    {:midday, ~T[09:00:00], ~T[15:30:00]},
    {:pm_peak, ~T[15:30:00], ~T[18:30:00]},
    {:evening, ~T[18:30:00], ~T[20:00:00]},
    {:late_night, ~T[20:00:00], :close}
  ]

  def by_route_id(route_id) do
    current_daypart = daypart(DateTime.utc_now(), route_id)
    by_route_id_and_daypart(route_id, current_daypart)
  end

  defp by_route_id_and_daypart("Green-B", :early_morning), do: 10
  defp by_route_id_and_daypart("Green-B", :am_peak), do: 6
  defp by_route_id_and_daypart("Green-B", :midday), do: 8
  defp by_route_id_and_daypart("Green-B", :pm_peak), do: 6
  defp by_route_id_and_daypart("Green-B", :evening), do: 7
  defp by_route_id_and_daypart("Green-B", :late_night), do: 9

  defp by_route_id_and_daypart("Green-C", :early_morning), do: 10
  defp by_route_id_and_daypart("Green-C", :am_peak), do: 6
  defp by_route_id_and_daypart("Green-C", :midday), do: 9
  defp by_route_id_and_daypart("Green-C", :pm_peak), do: 7
  defp by_route_id_and_daypart("Green-C", :evening), do: 7
  defp by_route_id_and_daypart("Green-C", :late_night), do: 10

  defp by_route_id_and_daypart("Green-D", :early_morning), do: 11
  defp by_route_id_and_daypart("Green-D", :am_peak), do: 6
  defp by_route_id_and_daypart("Green-D", :midday), do: 8
  defp by_route_id_and_daypart("Green-D", :pm_peak), do: 6
  defp by_route_id_and_daypart("Green-D", :evening), do: 8
  defp by_route_id_and_daypart("Green-D", :late_night), do: 11

  defp by_route_id_and_daypart("Green-E", :early_morning), do: 10
  defp by_route_id_and_daypart("Green-E", :am_peak), do: 6
  defp by_route_id_and_daypart("Green-E", :midday), do: 8
  defp by_route_id_and_daypart("Green-E", :pm_peak), do: 7
  defp by_route_id_and_daypart("Green-E", :evening), do: 9
  defp by_route_id_and_daypart("Green-E", :late_night), do: 9

  # TODO: handle overnight

  defp daypart(utc_time, route_id) do
    {:ok, local_time} = DateTime.shift_zone(utc_time, "America/New_York")
    local_time = DateTime.to_time(local_time)

    {daypart, _, _} =
      Enum.find(@dayparts, fn _ -> {:overnight, nil, nil} end, &match(&1, local_time, route_id))

    daypart
  end

  # TODO: fix handling of times past midnight, perhaps by splitting the service day at 3am.

  defp match({daypart, :open, t_end}, local_time, route_id) do
    t_start = ~T[05:00:00]
    match({daypart, t_start, t_end}, local_time, route_id)
  end

  defp match({daypart, t_start, :close}, local_time, route_id) do
    t_end = ~T[23:59:00]
    match({daypart, t_start, t_end}, local_time, route_id)
  end

  defp match({_daypart, t_start, t_end}, local_time, _route_id) do
    Enum.member?([:lt, :eq], Time.compare(t_start, local_time)) and
      Time.compare(local_time, t_end) == :lt
  end
end
