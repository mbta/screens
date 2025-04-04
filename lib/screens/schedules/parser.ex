defmodule Screens.Schedules.Parser do
  @moduledoc false

  alias Screens.Schedules.Schedule
  alias Screens.V3Api

  def parse(
        %{
          "id" => id,
          "attributes" => %{
            "arrival_time" => arrival_time_string,
            "departure_time" => departure_time_string,
            "stop_headsign" => stop_headsign,
            "direction_id" => direction_id
          },
          "relationships" => %{"route" => route, "stop" => stop, "trip" => trip}
        },
        included
      ) do
    stop = V3Api.Parser.included!(stop, included)

    %Schedule{
      id: id,
      trip: V3Api.Parser.included!(trip, included),
      stop: stop,
      route: V3Api.Parser.included!(route, included),
      arrival_time: parse_time(arrival_time_string),
      departure_time: parse_time(departure_time_string),
      stop_headsign: stop_headsign,
      track_number: stop.platform_code,
      direction_id: direction_id
    }
  end

  defp parse_time(nil), do: nil

  defp parse_time(s) do
    {:ok, time, _} = DateTime.from_iso8601(s)
    time
  end
end
