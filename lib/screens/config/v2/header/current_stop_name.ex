defmodule Screens.Config.V2.Header.CurrentStopName do
  @moduledoc false

  @type t :: %__MODULE__{stop_name: String.t()}

  @enforce_keys [:stop_name]
  defstruct stop_name: nil

  use Screens.Config.Struct

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
