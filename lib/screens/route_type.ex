defmodule Screens.RouteType do
  @moduledoc false

  @type t :: :light_rail | :subway | :rail | :bus | :ferry

  @route_types [:light_rail, :subway, :rail, :bus, :ferry]
  @route_type_ids 0..4

  @route_type_mapping Enum.zip(@route_types, @route_type_ids) |> Enum.into(%{})
  @inverted_mapping Enum.zip(@route_type_ids, @route_types) |> Enum.into(%{})

  defguard is_route_type(term) when term in @route_types
  defguard is_route_type_id(term) when term in @route_type_ids

  @spec to_id(t()) :: non_neg_integer() | nil
  def to_id(t) when is_route_type(t) do
    Map.get(@route_type_mapping, t)
  end

  @spec from_id(non_neg_integer()) :: t() | nil
  def from_id(id) when is_route_type_id(id) do
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
