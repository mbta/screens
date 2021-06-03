defmodule Screens.Config.V2.GlEink do
  @moduledoc false
  # credo:disable-for-this-file Credo.Check.Design.DuplicatedCode

  alias Screens.Config.V2.{Departures, Footer, LineMap}
  alias Screens.Config.V2.Header.Destination
  alias Screens.Util

  @type t :: %__MODULE__{
          departures: Departures.t(),
          footer: Footer.t(),
          header: Destination.t(),
          line_map: LineMap.t()
        }

  @enforce_keys [:departures, :footer, :header, :line_map]
  defstruct departures: nil,
            footer: nil,
            header: nil,
            line_map: nil

  use Screens.Config.Struct,
    children: [departures: Departures, footer: Footer, header: Destination, line_map: LineMap]
end
