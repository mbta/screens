defmodule Screens.Config.V2.Footer do
  @moduledoc false

  @type t :: %__MODULE__{stop_id: String.t()}

  defstruct stop_id: nil

  use Screens.Config.Struct

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
