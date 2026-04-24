defmodule Screens.Lines.Line do
  @moduledoc false

  defstruct ~w[id long_name short_name sort_order]a

  @type id :: String.t()

  @type t :: %__MODULE__{
          id: id(),
          long_name: String.t(),
          short_name: String.t(),
          sort_order: integer()
        }
end
