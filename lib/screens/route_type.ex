defmodule Screens.RouteType do
  @moduledoc false

  @type t :: :light_rail | :subway | :rail | :bus | :ferry

  @route_type_mapping %{light_rail: 0, subway: 1, rail: 2, bus: 3, ferry: 4}
  @inverted_mapping Enum.into(@route_type_mapping, %{}, fn {k, v} -> {v, k} end)

  @route_types Map.keys(@route_type_mapping)
  @route_type_ids Map.values(@route_type_mapping)

  defguard is_route_type(term) when term in @route_types
  defguard is_route_type_id(term) when term in @route_type_ids

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
