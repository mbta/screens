defmodule Screens.Config.V2.BlueBikes.Station do
  @moduledoc false

  @type t :: %__MODULE__{
          id: String.t(),
          arrow: arrow(),
          walk_distance_minutes_range: String.t()
        }

  @type arrow :: :n | :ne | :e | :se | :s | :sw | :w | :nw | nil

  @enforce_keys [:id, :arrow, :walk_distance_minutes_range]
  defstruct @enforce_keys

  use Screens.Config.Struct

  for arrow <- ~w[n ne e se s sw w nw nil]a do
    arrow_string = Atom.to_string(arrow)
    defp value_from_json("arrow", unquote(arrow_string)), do: unquote(arrow)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(_, value), do: value
end
