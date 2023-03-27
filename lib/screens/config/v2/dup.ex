defmodule Screens.Config.V2.Dup do
  @moduledoc false

  alias Screens.Config.V2.Header.{CurrentStopId, CurrentStopName}
  alias Screens.Config.V2.{Departures, EvergreenContentItem}

  @type t :: %__MODULE__{
          header: CurrentStopId.t() | CurrentStopName.t(),
          evergreen_content: list(EvergreenContentItem.t()),
          primary_departures: Departures.t(),
          secondary_departures: Departures.t()
        }

  @enforce_keys [:primary_departures, :secondary_departures, :header]
  defstruct primary_departures: nil,
            secondary_departures: nil,
            header: nil,
            evergreen_content: []

  use Screens.Config.Struct,
    children: [
      primary_departures: Departures,
      secondary_departures: Departures,
      evergreen_content: {:list, EvergreenContentItem}
    ]

  defp value_from_json("header", %{"stop_name" => _} = header) do
    CurrentStopName.from_json(header)
  end

  defp value_from_json("header", %{"stop_id" => _} = header) do
    CurrentStopId.from_json(header)
  end

  defp value_to_json(:header, %CurrentStopId{} = header) do
    CurrentStopId.to_json(header)
  end

  defp value_to_json(:header, %CurrentStopName{} = header) do
    CurrentStopName.to_json(header)
  end
end
