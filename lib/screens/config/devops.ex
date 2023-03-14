defmodule Screens.Config.Devops do
  @moduledoc false

  @typep mode :: :subway | :light_rail | :rail | :bus | :ferry

  @type t :: %__MODULE__{
          disabled_modes: [mode]
        }

  @modes ~w[subway light_rail rail bus ferry]a

  defstruct disabled_modes: []

  use Screens.Config.Struct, with_default: true

  defp value_from_json("disabled_modes", modes) do
    Enum.map(modes, &mode_string_to_atom/1)
  end

  defp value_to_json(_, value), do: value

  for mode <- @modes do
    mode_string = Atom.to_string(mode)
    defp mode_string_to_atom(unquote(mode_string)), do: unquote(mode)
  end
end
