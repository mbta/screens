defmodule Screens.RouteType do
  @moduledoc false

  @type t :: :light_rail | :subway | :rail | :bus | :ferry

  @route_type_mapping %{light_rail: 0, subway: 1, rail: 2, bus: 3, ferry: 4}
  @inverted_mapping Enum.into(@route_type_mapping, %{}, fn {k, v} -> {v, k} end)

  @spec to_id(t()) :: non_neg_integer() | nil
  def to_id(t) do
    Map.get(@route_type_mapping, t)
  end

  @spec from_id(non_neg_integer()) :: t() | nil
  def from_id(id) do
    Map.get(@inverted_mapping, id)
  end

  @spec from_string(String.t()) :: t()
  for t <- Map.keys(@route_type_mapping) do
    string_t = Atom.to_string(t)

    def from_string(unquote(string_t)) do
      unquote(t)
    end
  end
end
