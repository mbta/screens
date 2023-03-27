defmodule Screens.Config.V2.Dup do
  @moduledoc false

  alias Screens.Config.V2.Header.{CurrentStopId, CurrentStopName}
  alias Screens.Config.V2.{Alerts, Departures, EvergreenContentItem}

  @type t :: %__MODULE__{
          header: CurrentStopId.t() | CurrentStopName.t(),
          evergreen_content: list(EvergreenContentItem.t()),
          primary_departures: Departures.t(),
          secondary_departures: Departures.t(),
          alerts: Alerts.t()
        }

  @enforce_keys [:header, :primary_departures, :secondary_departures, :alerts]
  defstruct @enforce_keys ++ [evergreen_content: []]

  use Screens.Config.Struct,
    children: [
      header: CurrentStopId,
      primary_departures: Departures,
      secondary_departures: Departures,
      alerts: Alerts,
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
