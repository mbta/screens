defmodule Screens.Vehicles.Parser do
  @moduledoc false

  def parse_result(%{"data" => data}) do
    data
    |> Enum.map(&parse_vehicle/1)
    |> Enum.reject(&is_nil(&1.stop_id))
  end

  def parse_vehicle(%{
        "attributes" => %{"direction_id" => direction_id, "current_status" => current_status},
        "id" => vehicle_id,
        "relationships" => %{"trip" => trip_data, "stop" => stop_data}
      }) do
    %Screens.Vehicles.Vehicle{
      id: vehicle_id,
      direction_id: direction_id,
      current_status: parse_current_status(current_status),
      trip_id: trip_id_from_trip_data(trip_data),
      stop_id: stop_id_from_stop_data(stop_data)
    }
  end

  defp trip_id_from_trip_data(%{"data" => %{"id" => trip_id}}), do: trip_id
  defp trip_id_from_trip_data(_), do: nil

  defp stop_id_from_stop_data(%{"data" => %{"id" => stop_id}}), do: stop_id
  defp stop_id_from_stop_data(_), do: nil

  defp parse_current_status("STOPPED_AT"), do: :stopped_at
  defp parse_current_status("INCOMING_AT"), do: :incoming_at
  defp parse_current_status("IN_TRANSIT_TO"), do: :in_transit_to
  defp parse_current_status(_), do: nil
end
