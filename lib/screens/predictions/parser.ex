defmodule Screens.Predictions.Parser do
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

  defp parse_data(data, included_data) do
    data
    |> Enum.map(fn item -> parse_prediction(item, included_data) end)
    |> Enum.reject(&is_nil(&1.time))
  end

  defp parse_included_data(data) do
    data
    |> Enum.map(fn item ->
      {{Map.get(item, "type"), Map.get(item, "id")}, parse_included(item)}
    end)
    |> Enum.into(%{})
  end

  defp parse_included(%{"type" => "stop"} = item) do
    Screens.Stops.Parser.parse_stop(item)
  end

  defp parse_included(%{"type" => "route"} = item) do
    Screens.Routes.Parser.parse_route(item)
  end

  defp parse_included(%{"type" => "trip"} = item) do
    Screens.Trips.Parser.parse_trip(item)
  end

  def parse_prediction(
        %{"id" => id, "attributes" => attributes, "relationships" => relationships},
        included_data
      ) do
    %{"departure_time" => time_string} = attributes
    time = parse_time(time_string)

    %{
      "route" => %{"data" => %{"id" => route_id}},
      "stop" => %{"data" => %{"id" => stop_id}},
      "trip" => %{"data" => %{"id" => trip_id}}
    } = relationships

    trip = Map.get(included_data, {"trip", trip_id})
    stop = Map.get(included_data, {"stop", stop_id})
    route = Map.get(included_data, {"route", route_id})

    %Screens.Predictions.Prediction{
      id: id,
      trip: trip,
      stop: stop,
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
