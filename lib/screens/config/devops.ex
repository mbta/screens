defmodule Screens.Config.Devops do
  @moduledoc false

  @typep mode :: :subway | :light_rail | :commuter_rail | :bus | :ferry

  @type t :: %__MODULE__{
          disabled_modes: [mode]
        }

  @modes ~w[subway light_rail commuter_rail bus ferry]a

  defstruct disabled_modes: []

  @spec from_json(map() | :default) :: t()
  def from_json(%{"disabled_modes" => mode_string_list}) do
    mode_atom_list = Enum.map(mode_string_list, &mode_string_to_atom/1)
    %__MODULE__{disabled_modes: mode_atom_list}
  end

  def from_json(:default), do: %__MODULE__{}

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = t) do
    Map.from_struct(t)
  end

  for mode <- @modes do
    mode_string = Atom.to_string(mode)
    defp mode_string_to_atom(unquote(mode_string)), do: unquote(mode)
  end
end
