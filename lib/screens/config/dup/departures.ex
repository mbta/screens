defmodule Screens.Config.Dup.Departures do
  @moduledoc false

  alias Screens.Config.Dup.Section
  alias Screens.Util

  @type t :: %__MODULE__{
          header: String.t(),
          sections: list(Section.t())
        }

  defstruct header: "",
            sections: []

  @spec from_json(map() | :default) :: t()
  def from_json(%{} = json) do
    struct_map =
      json
      |> Map.take(Util.struct_keys(__MODULE__))
      |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), value_from_json(k, v)} end)

    struct!(__MODULE__, struct_map)
  end

  def from_json(:default) do
    %__MODULE__{}
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = t) do
    t
    |> Map.from_struct()
    |> Enum.into(%{}, fn {k, v} -> {k, value_to_json(k, v)} end)
  end

  defp value_from_json("sections", sections) when is_list(sections) do
    Enum.map(sections, &Section.from_json/1)
  end

  defp value_from_json(_, value), do: value

  defp value_to_json(:sections, sections) do
    Enum.map(sections, &Section.to_json/1)
  end

  defp value_to_json(_, value), do: value
end
