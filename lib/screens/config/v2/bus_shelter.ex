defmodule Screens.Config.V2.BusShelter do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode

  alias Screens.Config.V2.{Alerts, Audio, Departures, EvergreenContentItem, Footer, Survey}
  alias Screens.Config.V2.Header.{CurrentStopId, CurrentStopName}

  @type t :: %__MODULE__{
          departures: Departures.t(),
          footer: Footer.t(),
          header: CurrentStopId.t() | CurrentStopName.t(),
          alerts: Alerts.t(),
          evergreen_content: list(EvergreenContentItem.t()),
          survey: Survey.t(),
          audio: Audio.t() | nil
        }

  @enforce_keys [:departures, :footer, :header, :alerts]
  defstruct departures: nil,
            footer: nil,
            header: nil,
            alerts: nil,
            evergreen_content: [],
            survey: Survey.from_json(:default),
            audio: Audio.from_json(:default)

  use Screens.Config.Struct,
    children: [
      departures: Departures,
      footer: Footer,
      alerts: Alerts,
      evergreen_content: {:list, EvergreenContentItem},
      survey: Survey,
      audio: Audio
    ]

  defp value_from_json("header", %{"type" => "current_stop_id"} = header) do
    CurrentStopId.from_json(header)
  end

  defp value_from_json("header", %{"type" => "current_stop_name"} = header) do
    CurrentStopName.from_json(header)
  end

  # Fallback for previous config definition that only allowed CurrentStopId
  # and did not specify header type
  defp value_from_json("header", header) do
    CurrentStopId.from_json(header)
  end

  defp value_to_json(:header, %CurrentStopId{} = header) do
    header
    |> CurrentStopId.to_json()
    |> Map.put(:type, :current_stop_id)
  end

  defp value_to_json(:header, %CurrentStopName{} = header) do
    header
    |> CurrentStopName.to_json()
    |> Map.put(:type, :current_stop_name)
  end
end
