defmodule Screens.Config.V2.Departures do
  @moduledoc false

  alias Screens.Config.V2.Departures.Section

  @type t :: %__MODULE__{sections: list(Section.t())}

  @enforce_keys [:sections]
  defstruct sections: []

  use Screens.Config.Struct, children: [sections: {:list, Section}]
end
