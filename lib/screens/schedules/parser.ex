defmodule Screens.Schedules.Parser do
  @moduledoc false

  def parse_result(result) do
    included_data =
      result
      |> Map.get("included")
      |> parse_included_data()

    result
    |> Map.get("data")
    |> parse_data(included_data)
  end

  def parse_data(data, included_data) do
    data
    |> Enum.map(fn item -> parse_schedule(item, included_data) end)
    |> Enum.reject(&is_nil(&1.time))
  end

  defp parse_included_data(data) do
    data
    |> Enum.map(fn item ->
      {{Map.get(item, "type"), Map.get(item, "id")}, parse_included(item)}
    end)
    |> Enum.into(%{})
  end

  defp parse_included(%{"type" => "trip"} = item) do
    Screens.Trips.Parser.parse_trip(item)
  end

  defp parse_included(%{"type" => "route"} = item) do
    Screens.Routes.Parser.parse_route(item)
  end

  def parse_schedule(
        %{"id" => id, "attributes" => attributes, "relationships" => relationships},
        included_data
      ) do
    %{"departure_time" => time_string} = attributes
    time = parse_time(time_string)

    %{
      "trip" => %{"data" => %{"id" => trip_id}},
      "route" => %{"data" => %{"id" => route_id}}
    } = relationships

    trip = Map.get(included_data, {"trip", trip_id})
    route = Map.get(included_data, {"route", route_id})

    %Screens.Schedules.Schedule{
      id: id,
      trip: trip,
      route: route,
      time: time
    }
  end

  defp parse_time(nil), do: nil

  defp parse_time(s) do
    {:ok, time, _} = DateTime.from_iso8601(s)
    time
  end
end
