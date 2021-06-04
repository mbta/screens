defmodule Screens.Config.V2.GlEink do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode

  alias Screens.Config.V2.{Alerts, Departures, Footer, LineMap}
  alias Screens.Config.V2.Header.Destination
  alias Screens.Util

  @type t :: %__MODULE__{
          departures: Departures.t(),
          footer: Footer.t(),
          header: Destination.t(),
          alerts: Alerts.t(),
          line_map: LineMap.t()
        }

  @enforce_keys [:departures, :footer, :header, :alerts, :line_map]
  defstruct departures: nil,
            footer: nil,
            header: nil,
            alerts: nil,
            line_map: nil

  use Screens.Config.Struct,
    children: [departures: Departures, footer: Footer, header: Destination, alerts: Alerts, line_map: LineMap]
end
