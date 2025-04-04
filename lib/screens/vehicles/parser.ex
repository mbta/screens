defmodule Screens.Vehicles.Parser do
  @moduledoc false

  def parse(
        %{
          "id" => id,
          "attributes" => %{
            "direction_id" => direction_id,
            "carriages" => carriages,
            "current_status" => current_status,
            "occupancy_status" => occupancy_status
          },
          "relationships" => %{"trip" => trip_data, "stop" => stop_data}
        },
        _included
      ) do
    %Screens.Vehicles.Vehicle{
      id: id,
      direction_id: direction_id,
      carriages: parse_carriages(carriages),
      current_status: parse_current_status(current_status),
      occupancy_status: parse_occupancy_status(occupancy_status),
      trip_id: trip_id_from_trip_data(trip_data),
      stop_id: stop_id_from_stop_data(stop_data)
    }
  end

  defp parse_carriages(data), do: Enum.map(data, &parse_car_crowding/1)

  defp parse_car_crowding(%{
         "label" => car_number,
         "occupancy_status" => occupancy_status,
         "occupancy_percentage" => occupancy_percentage
       }),
       do: %Screens.Vehicles.Carriage{
         car_number: car_number,
         occupancy_status: parse_occupancy_status(occupancy_status),
         occupancy_percentage: occupancy_percentage
       }

  defp trip_id_from_trip_data(%{"data" => %{"id" => trip_id}}), do: trip_id
  defp trip_id_from_trip_data(_), do: nil

  defp stop_id_from_stop_data(%{"data" => %{"id" => stop_id}}), do: stop_id
  defp stop_id_from_stop_data(_), do: nil

  defp parse_current_status("STOPPED_AT"), do: :stopped_at
  defp parse_current_status("INCOMING_AT"), do: :incoming_at
  defp parse_current_status("IN_TRANSIT_TO"), do: :in_transit_to
  defp parse_current_status(_), do: nil

  defp parse_occupancy_status("MANY_SEATS_AVAILABLE"), do: :many_seats_available
  defp parse_occupancy_status("FEW_SEATS_AVAILABLE"), do: :few_seats_available
  defp parse_occupancy_status("STANDING_ROOM_ONLY"), do: :standing_room_only
  defp parse_occupancy_status("CRUSHED_STANDING_ROOM_ONLY"), do: :crushed_standing_room_only
  defp parse_occupancy_status("FULL"), do: :full
  defp parse_occupancy_status("NO_DATA_AVAILABLE"), do: :no_data_available
  defp parse_occupancy_status("NOT_ACCEPTING_PASSENGERS"), do: :not_accepting_passengers
  defp parse_occupancy_status(_), do: nil
end
