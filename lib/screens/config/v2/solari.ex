defmodule Screens.Config.V2.Solari do
  @moduledoc false

  alias Screens.Config.V2.Departures
  alias Screens.Config.V2.Header.CurrentStopName

  @type t :: %__MODULE__{
          departures: Departures.t(),
          header: CurrentStopName.t()
        }

  @enforce_keys [:departures, :header]
  defstruct departures: nil,
            header: nil

  use Screens.Config.Struct, children: [departures: Departures, header: CurrentStopName]
end
