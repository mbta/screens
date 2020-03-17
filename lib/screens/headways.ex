defmodule Screens.Headways do
  @moduledoc false

  @dayparts [
    {:late_night, ~T[00:00:00], :close},
    {:early_morning, :open, ~T[06:30:00]},
    {:am_peak, ~T[06:30:00], ~T[09:00:00]},
    {:midday, ~T[09:00:00], ~T[15:30:00]},
    {:pm_peak, ~T[15:30:00], ~T[18:30:00]},
    {:evening, ~T[18:30:00], ~T[20:00:00]},
    {:late_night, ~T[20:00:00], :midnight}
  ]

  def by_route_id(route_id, stop_id, direction_id, time \\ DateTime.utc_now()) do
    current_schedule = schedule(time)
    current_daypart = daypart(time, stop_id, direction_id, current_schedule)
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

  defp daypart(utc_time, stop_id, direction_id, current_schedule) do
    {:ok, local_time} = DateTime.shift_zone(utc_time, "America/New_York")
    local_time = DateTime.to_time(local_time)

    {daypart, _, _} =
      Enum.find(
        @dayparts,
        {:overnight, nil, nil},
        &match(&1, local_time, {stop_id, direction_id, current_schedule})
      )

    daypart
  end

  defp match({daypart, :open, t_end}, local_time, {stop_id, direction_id, schedule}) do
    t_start = service_start(schedule, stop_id, direction_id)
    match({daypart, t_start, t_end}, local_time, nil)
  end

  defp match({daypart, t_start, :close}, local_time, {stop_id, direction_id, schedule}) do
    t_end = service_end(schedule, stop_id, direction_id)
    match({daypart, t_start, t_end}, local_time, nil)
  end

  defp match({_daypart, t_start, :midnight}, local_time, _) do
    Time.compare(t_start, local_time) == :lt
  end

  defp match({_daypart, t_start, t_end}, local_time, _) do
    Enum.member?([:lt, :eq], Time.compare(t_start, local_time)) and
      Time.compare(local_time, t_end) == :lt
  end

  # Time to stop showing Good Night screen if there are no predictions
  defp service_start(:sunday, "place-bland", 0), do: ~T[06:12:00]
  defp service_start(:sunday, "place-bland", 1), do: ~T[05:20:00]
  defp service_start(:sunday, "place-bcnwa", 0), do: ~T[06:06:00]
  defp service_start(:sunday, "place-bcnwa", 1), do: ~T[05:30:00]
  defp service_start(:sunday, "place-mfa", 0), do: ~T[05:35:00]
  # placeholder value
  defp service_start(:sunday, "place-mfa", 1), do: ~T[05:35:00]

  defp service_start(_, "place-bland", 0), do: ~T[05:40:00]
  defp service_start(_, "place-bland", 1), do: ~T[04:45:00]
  defp service_start(_, "place-bcnwa", 0), do: ~T[05:30:00]
  defp service_start(_, "place-bcnwa", 1), do: ~T[04:50:00]
  defp service_start(_, "place-mfa", 0), do: ~T[05:01:00]
  # placeholder value
  defp service_start(_, "place-mfa", 1), do: ~T[05:01:00]

  # Time to begin showing Good Night screen if there are no predictions
  defp service_end(:sunday, "place-bland", 0), do: ~T[01:12:00]
  defp service_end(:sunday, "place-bland", 1), do: ~T[00:37:00]
  defp service_end(:sunday, "place-bcnwa", 0), do: ~T[01:29:00]
  defp service_end(:sunday, "place-bcnwa", 1), do: ~T[00:14:00]
  defp service_end(:sunday, "place-mfa", 0), do: ~T[00:54:00]
  # placeholder value
  defp service_end(:sunday, "place-mfa", 1), do: ~T[00:54:00]

  defp service_end(_, "place-bland", 0), do: ~T[01:20:00]
  defp service_end(_, "place-bland", 1), do: ~T[00:39:00]
  defp service_end(_, "place-bcnwa", 0), do: ~T[01:16:00]
  defp service_end(_, "place-bcnwa", 1), do: ~T[00:34:00]
  defp service_end(_, "place-mfa", 0), do: ~T[00:55:00]
  # placeholder value
  defp service_end(_, "place-mfa", 1), do: ~T[00:55:00]
end
