defmodule Screens.Vehicles.Vehicle do
  @moduledoc false

  defstruct id: nil,
            direction_id: nil,
            current_status: nil,
            trip_id: nil,
            stop_id: nil,
            parent_stop_id: nil,
            occupancy_status: nil,
            carriages: nil

  @type current_status :: :incoming_at | :stopped_at | :in_transit_to | nil
  @type occupancy_status ::
          :many_seats_available
          | :few_seats_available
          | :standing_room_only
          | :crushed_standing_room_only
          | :full
          | :no_data_available
          | :not_accepting_passengers
          | nil

  @type t :: %__MODULE__{
          id: String.t(),
          direction_id: 0 | 1,
          current_status: current_status,
          trip_id: Screens.Trips.Trip.id() | nil,
          stop_id: Screens.Stops.Stop.id() | nil,
          parent_stop_id: Screens.Stops.Stop.id() | nil,
          occupancy_status: occupancy_status,
          carriages: list(occupancy_status) | nil
        }

  def by_route_and_direction(route_id, direction_id) do
    case Screens.V3Api.get_json("vehicles", %{
           "filter[route]" => route_id,
           "filter[direction_id]" => direction_id
         }) do
      {:ok, result} -> Screens.Vehicles.Parser.parse_result(result)
      _ -> []
    end
  end
end
