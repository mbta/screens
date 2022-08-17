defmodule Screens.Config.V2.CRDepartures do
  @moduledoc false

  alias Screens.V2.WidgetInstance

  @type t :: %__MODULE__{
          station: String.t(),
          destination_station: String.t(),
          direction_to_destination: 0 | 1,
          wayfinding_arrow: String.t(),
          priority: WidgetInstance.priority()
        }

  @enforce_keys [
    :station,
    :destination_station,
    :direction_to_destination,
    :wayfinding_arrow,
    :priority
  ]
  defstruct station: nil,
            destination_station: nil,
            direction_to_destination: nil,
            wayfinding_arrow: nil,
            priority: nil

  use Screens.Config.Struct

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
