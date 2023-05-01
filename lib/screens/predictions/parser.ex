defmodule Screens.Predictions.Parser do
  @moduledoc false

  def parse_result(%{"data" => data, "included" => included}) do
    included_data = parse_included_data(included)
    parse_data(data, included_data)
  end

  def parse_result(%{"data" => []}) do
    []
  end

  defp parse_data(data, included_data) do
    Enum.map(data, &parse_prediction(&1, included_data))
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

  defp parse_included(%{"type" => "vehicle"} = item) do
    Screens.Vehicles.Parser.parse_vehicle(item)
  end

  defp parse_included(%{"type" => "alert"} = item) do
    Screens.Alerts.Parser.parse_alert(item)
  end

  def parse_prediction(
        %{"id" => id, "attributes" => attributes, "relationships" => relationships},
        included_data
      ) do
    %{"arrival_time" => arrival_time_string, "departure_time" => departure_time_string} =
      attributes

    arrival_time = parse_time(arrival_time_string)
    departure_time = parse_time(departure_time_string)

    %{
      "route" => %{"data" => %{"id" => route_id}},
      "stop" => %{"data" => %{"id" => stop_id}},
      "trip" => %{"data" => %{"id" => trip_id}}
    } = relationships

    trip = Map.get(included_data, {"trip", trip_id})
    stop = Map.get(included_data, {"stop", stop_id})
    route = Map.get(included_data, {"route", route_id})
    track_number = Map.get(included_data, {"stop", stop_id}).platform_code

    vehicle =
      case get_in(relationships, ["vehicle", "data", "id"]) do
        nil -> nil
        vehicle_id -> Map.get(included_data, {"vehicle", vehicle_id})
      end

    alerts =
      case get_in(relationships, ["alerts", "data"]) do
        nil ->
          []

        alerts_data ->
          Enum.map(alerts_data, fn %{"id" => alert_id} ->
            Map.get(included_data, {"alert", alert_id})
          end)
      end

    %Screens.Predictions.Prediction{
      id: id,
      trip: trip,
      stop: stop,
      route: route,
      vehicle: vehicle,
      alerts: alerts,
      arrival_time: arrival_time,
      departure_time: departure_time,
      track_number: track_number
    }
  end

  defp parse_time(nil), do: nil

  defp parse_time(s) do
    {:ok, time, _} = DateTime.from_iso8601(s)
    time
  end
end
