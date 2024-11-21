defmodule Screens.Predictions.Parser do
  @moduledoc false

  alias Screens.{Routes, Stops, Trips, Vehicles}
  alias Screens.Predictions.{Prediction, ScheduleRelationship}

  def parse(%{"data" => data} = response) do
    included =
      response
      |> Map.get("included", [])
      |> Map.new(fn %{"id" => id, "type" => type} = resource -> {{id, type}, resource} end)

    Enum.map(data, &parse_prediction(&1, included))
  end

  def parse_prediction(
        %{
          "id" => id,
          "attributes" => %{
            "arrival_time" => arrival_time_string,
            "departure_time" => departure_time_string,
            "schedule_relationship" => schedule_relationship
          },
          "relationships" =>
            %{
              "route" => %{"data" => %{"id" => route_id}},
              "stop" => %{"data" => %{"id" => stop_id}},
              "trip" => %{"data" => %{"id" => trip_id}}
            } = relationships
        },
        included
      ) do
    trip = included |> Map.fetch!({trip_id, "trip"}) |> Trips.Parser.parse_trip(included)
    stop = included |> Map.fetch!({stop_id, "stop"}) |> Stops.Parser.parse_stop(included)
    route = included |> Map.fetch!({route_id, "route"}) |> Routes.Parser.parse_route(included)

    vehicle =
      case get_in(relationships, ~w[vehicle data id]) do
        nil ->
          nil

        vehicle_id ->
          included |> Map.fetch!({vehicle_id, "vehicle"}) |> Vehicles.Parser.parse_vehicle()
      end

    %Prediction{
      id: id,
      trip: trip,
      stop: stop,
      route: route,
      vehicle: vehicle,
      arrival_time: parse_time(arrival_time_string),
      departure_time: parse_time(departure_time_string),
      track_number: stop.platform_code,
      schedule_relationship: ScheduleRelationship.parse(schedule_relationship)
    }
  end

  defp parse_time(nil), do: nil

  defp parse_time(s) do
    {:ok, time, _} = DateTime.from_iso8601(s)
    time
  end
end
