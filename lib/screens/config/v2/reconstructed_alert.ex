defmodule Screens.Config.V2.ReconstructedAlert do
  @moduledoc false

  @type t :: %__MODULE__{alert: String.t()}

  @enforce_keys [:alert]
  defstruct @enforce_keys

  use Screens.Config.Struct

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
