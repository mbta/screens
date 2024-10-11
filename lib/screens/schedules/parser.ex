defmodule Screens.Schedules.Parser do
  @moduledoc false

  alias Screens.{Routes, Stops, Trips}
  alias Screens.Schedules.Schedule

  def parse(%{"data" => data} = response) do
    included =
      response
      |> Map.get("included", [])
      |> Map.new(fn %{"id" => id, "type" => type} = resource -> {{id, type}, resource} end)

    Enum.map(data, &parse_schedule(&1, included))
  end

  defp parse_schedule(
         %{
           "id" => id,
           "attributes" => %{
             "arrival_time" => arrival_time_string,
             "departure_time" => departure_time_string,
             "stop_headsign" => stop_headsign,
             "direction_id" => direction_id
           },
           "relationships" => %{
             "route" => %{"data" => %{"id" => route_id}},
             "stop" => %{"data" => %{"id" => stop_id}},
             "trip" => %{"data" => %{"id" => trip_id}}
           }
         },
         included
       ) do
    trip = included |> Map.fetch!({trip_id, "trip"}) |> Trips.Parser.parse_trip()
    stop = included |> Map.fetch!({stop_id, "stop"}) |> Stops.Parser.parse_stop()
    route = included |> Map.fetch!({route_id, "route"}) |> Routes.Parser.parse_route(included)

    %Schedule{
      id: id,
      trip: trip,
      stop: stop,
      route: route,
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
