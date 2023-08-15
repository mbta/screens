defmodule Screens.Config.V2.TrainCrowding do
  @moduledoc false

  @type t :: %__MODULE__{
          station_id: String.t(),
          route_id: String.t(),
          direction_id: 0 | 1,
          # temporarily going with float, but will adjust based on design
          platform_position: float(),
          front_car_direction: :left | :right
        }

  @enforce_keys [:station_id, :direction_id, :platform_position, :front_car_direction]
  defstruct station_id: nil,
            route_id: "Orange",
            direction_id: nil,
            platform_position: nil,
            front_car_direction: nil

  use Screens.Config.Struct

  defp value_from_json("direction_id", "left"), do: :left
  defp value_from_json("direction_id", "right"), do: :right
  
  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
