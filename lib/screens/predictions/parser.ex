defmodule Screens.Predictions.Parser do
  @moduledoc false

  alias Screens.Predictions.{Prediction, ScheduleRelationship}
  alias Screens.V3Api

  def parse(
        %{
          "id" => id,
          "attributes" => %{
            "arrival_time" => arrival_time_string,
            "departure_time" => departure_time_string,
            "schedule_relationship" => schedule_relationship
          } = attributes,
          "relationships" => %{
            "route" => route,
            "stop" => stop,
            "trip" => trip,
            "vehicle" => vehicle
          }
        },
        included
      ) do
    stop = V3Api.Parser.included!(stop, included)

    %Prediction{
      id: id,
      trip: V3Api.Parser.included!(trip, included),
      stop: stop,
      route: V3Api.Parser.included!(route, included),
      vehicle: V3Api.Parser.included!(vehicle, included),
      arrival_time: parse_time(arrival_time_string),
      departure_time: parse_time(departure_time_string),
      track_number: stop.platform_code,
      schedule_relationship: ScheduleRelationship.parse(schedule_relationship),
      status: Map.get(attributes, "status")
    }
  end

  defp parse_time(nil), do: nil

  defp parse_time(s) do
    {:ok, time, _} = DateTime.from_iso8601(s)
    time
  end
end
