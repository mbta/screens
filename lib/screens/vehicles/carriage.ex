defmodule Screens.Vehicles.Carriage do
  @moduledoc false

  defstruct car_number: nil,
            occupancy_status: nil

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
          car_number: String.t(),
          occupancy_status: occupancy_status | nil
        }
end
