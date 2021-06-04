defmodule Screens.Config.V2.GlEink do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode

  alias Screens.Config.V2.{Alerts, Departures, Footer}
  alias Screens.Config.V2.Header.Destination

  @type t :: %__MODULE__{
          departures: Departures.t(),
          footer: Footer.t(),
          header: Destination.t(),
          alerts: Alerts.t()
        }

  @enforce_keys [:departures, :footer, :header, :alerts]
  defstruct departures: nil,
            footer: nil,
            header: nil,
            alerts: nil

  use Screens.Config.Struct,
    children: [departures: Departures, footer: Footer, header: Destination, alerts: Alerts]
end
