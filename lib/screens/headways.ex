defmodule Screens.Headways do
  @moduledoc false

  alias Screens.Schedules.Schedule

  @dayparts [
    {:late_night, ~T[00:00:00], :close},
    {:early_morning, :open, ~T[06:30:00]},
    {:am_peak, ~T[06:30:00], ~T[09:00:00]},
    {:midday, ~T[09:00:00], ~T[15:30:00]},
    {:pm_peak, ~T[15:30:00], ~T[18:30:00]},
    {:evening, ~T[18:30:00], ~T[20:00:00]},
    {:late_night, ~T[20:00:00], :midnight}
  ]

  def by_route_id(route_id, stop_id, direction_id, service_level, time \\ DateTime.utc_now()) do
    current_schedule = schedule_with_override(time, service_level)
    current_daypart = daypart(time, stop_id, direction_id)
    headway(route_id, current_schedule, current_daypart)
  end

  defp headway(_, _, :overnight), do: nil

  # Weekday
  defp headway("Green-B", :weekday, :early_morning), do: 10
  defp headway("Green-B", :weekday, :am_peak), do: 6
  defp headway("Green-B", :weekday, :midday), do: 8
  defp headway("Green-B", :weekday, :pm_peak), do: 6
  defp headway("Green-B", :weekday, :evening), do: 7
  defp headway("Green-B", :weekday, :late_night), do: 9

  defp headway("Green-C", :weekday, :early_morning), do: 10
  defp headway("Green-C", :weekday, :am_peak), do: 6
  defp headway("Green-C", :weekday, :midday), do: 9
  defp headway("Green-C", :weekday, :pm_peak), do: 7
  defp headway("Green-C", :weekday, :evening), do: 7
  defp headway("Green-C", :weekday, :late_night), do: 10

  defp headway("Green-D", :weekday, :early_morning), do: 11
  defp headway("Green-D", :weekday, :am_peak), do: 6
  defp headway("Green-D", :weekday, :midday), do: 8
  defp headway("Green-D", :weekday, :pm_peak), do: 6
  defp headway("Green-D", :weekday, :evening), do: 8
  defp headway("Green-D", :weekday, :late_night), do: 11

  defp headway("Green-E", :weekday, :early_morning), do: 10
  defp headway("Green-E", :weekday, :am_peak), do: 6
  defp headway("Green-E", :weekday, :midday), do: 8
  defp headway("Green-E", :weekday, :pm_peak), do: 7
  defp headway("Green-E", :weekday, :evening), do: 9
  defp headway("Green-E", :weekday, :late_night), do: 9

  # Saturday
  defp headway("Green-B", :saturday, :early_morning), do: 14
  defp headway("Green-B", :saturday, _), do: 9

  defp headway("Green-C", :saturday, :early_morning), do: 14
  defp headway("Green-C", :saturday, _), do: 9

  defp headway("Green-D", :saturday, :early_morning), do: 14
  defp headway("Green-D", :saturday, :am_peak), do: 13
  defp headway("Green-D", :saturday, _), do: 9

  defp headway("Green-E", :saturday, :early_morning), do: 13
  defp headway("Green-E", :saturday, _), do: 10

  # Sunday
  defp headway("Green-B", :sunday, :early_morning), do: 12
  defp headway("Green-B", :sunday, :am_peak), do: 12
  defp headway("Green-B", :sunday, _), do: 9

  defp headway("Green-C", :sunday, :early_morning), do: 12
  defp headway("Green-C", :sunday, _), do: 10

  defp headway("Green-D", :sunday, :early_morning), do: 14
  defp headway("Green-D", :sunday, :am_peak), do: 13
  defp headway("Green-D", :sunday, _), do: 11

  defp headway("Green-E", :sunday, :early_morning), do: 15
  defp headway("Green-E", :sunday, _), do: 12

  defp schedule_with_override(time, service_level) do
    # Level 3 turns weekday into Saturday schedule
    # Level 4 is always Sunday schedule
    # Otherwise, use normal schedule
    case {service_level, schedule(time)} do
      {3, :weekday} -> :saturday
      {4, _} -> :sunday
      {_, schedule} -> schedule
    end
  end

  defp schedule(utc_time) do
    # Note: This is a hack.
    # Split the service day at 3am by shifting to Pacific Time.
    # Midnight at Pacific Time is always 3am here.
    {:ok, pacific_time} = DateTime.shift_zone(utc_time, "America/Los_Angeles")
    service_date = DateTime.to_date(pacific_time)

    case Date.day_of_week(service_date) do
      7 -> :sunday
      6 -> :saturday
      _ -> :weekday
    end
  end

  defp daypart(utc_time, stop_id, direction_id) do
    {:ok, local_time} = DateTime.shift_zone(utc_time, "America/New_York")
    local_time = DateTime.to_time(local_time)

    {daypart, _, _} =
      Enum.find(
        @dayparts,
        {:overnight, nil, nil},
        &match(&1, local_time, {stop_id, direction_id})
      )

    daypart
  end

  defp match({daypart, :open, t_end}, local_time, {stop_id, direction_id}) do
    t_start = service_start(stop_id, direction_id)

    case t_start do
      %Time{} -> match({daypart, t_start, t_end}, local_time, nil)
      nil -> false
    end
  end

  defp match({daypart, t_start, :close}, local_time, {stop_id, direction_id}) do
    t_end = service_end(stop_id, direction_id)

    case t_end do
      %Time{} -> match({daypart, t_start, t_end}, local_time, nil)
      nil -> false
    end
  end

  defp match({_daypart, t_start, :midnight}, local_time, _) do
    Time.compare(t_start, local_time) == :lt
  end

  defp match({_daypart, t_start, t_end}, local_time, _) do
    Enum.member?([:lt, :eq], Time.compare(t_start, local_time)) and
      Time.compare(local_time, t_end) == :lt
  end

  defp service_start_or_end(stop_id, direction_id, min_or_max_fn) do
    with {:ok, schedules} <- Schedule.fetch(%{stop_ids: [stop_id], direction_id: direction_id}),
         [_ | _] = arrival_times <- get_arrival_times(schedules) do
      {:ok, local_dt} =
        arrival_times
        |> min_or_max_fn.()
        |> DateTime.shift_zone("America/New_York")

      DateTime.to_time(local_dt)
    else
      _ -> nil
    end
  end

  defp get_arrival_times(schedules) do
    schedules
    |> Enum.map(& &1.arrival_time)
    |> Enum.reject(&is_nil(&1))
  end

  # Time to stop showing Good Night screen if there are no predictions
  defp service_start(stop_id, direction_id) do
    service_start_or_end(stop_id, direction_id, &Enum.min/1)
  end

  # Time to begin showing Good Night screen if there are no predictions
  defp service_end(stop_id, direction_id) do
    service_start_or_end(stop_id, direction_id, &Enum.max/1)
  end
end
