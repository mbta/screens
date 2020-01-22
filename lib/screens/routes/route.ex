defmodule Screens.Routes.Route do
  @moduledoc false

  defstruct id: nil,
            short_name: nil

  @type t :: %__MODULE__{
          id: String.t(),
          short_name: String.t()
        }
end
