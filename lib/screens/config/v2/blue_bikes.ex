defmodule Screens.Config.V2.BlueBikes do
  @moduledoc false

  alias Screens.V2.WidgetInstance
  alias Screens.Config.V2.BlueBikes.Station

  @type t :: %__MODULE__{
          enabled: boolean(),
          stations: list(Station.t()),
          destination: String.t(),
          minutes_range_to_destination: String.t(),
          priority: WidgetInstance.priority()
        }

  defstruct enabled: false,
            stations: [],
            destination: nil,
            minutes_range_to_destination: nil,
            priority: [99]

  use Screens.Config.Struct,
    with_default: true,
    children: [stations: {:list, Station}]

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
