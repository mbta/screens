defmodule Screens.Config.V2.BusEink do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode

  alias Screens.Config.V2.{Departures, Footer}
  alias Screens.Config.V2.Header.CurrentStopId

  @type t :: %__MODULE__{
          departures: Departures.t(),
          footer: Footer.t(),
          header: CurrentStopId.t()
        }

  @enforce_keys [:departures, :footer, :header]
  defstruct departures: nil,
            footer: nil,
            header: nil

  use Screens.Config.Struct,
    children: [departures: Departures, footer: Footer, header: CurrentStopId]
end
