defmodule Screens.Config.V2.Departures.Section do
  @moduledoc false

  alias Screens.Config.V2.Departures.{Filter, Headway, Query}
  alias Screens.Util

  @type t :: %__MODULE__{
          query: Query.t(),
          filter: Filter.t(),
          headway: Headway.t()
        }

  @enforce_keys [:query]
  defstruct query: nil,
            filter: [],
            headway: Headway.from_json(:default)

  @spec from_json(map()) :: t()
  def from_json(%{} = json) do
    struct_map =
      json
      |> Map.take(Util.struct_keys(__MODULE__))
      |> Enum.into(%{}, fn {k, v} -> {String.to_existing_atom(k), value_from_json(k, v)} end)

    struct!(__MODULE__, struct_map)
  end

  defp value_from_json("query", query) do
    Query.from_json(query)
  end

  defp value_from_json("filter", filter) do
    Enum.map(filter, &Filter.from_json/1)
  end

  defp value_from_json("headway", headway) do
    Headway.from_json(headway)
  end

  @spec to_json(t()) :: map()
  def to_json(%__MODULE__{} = t) do
    t
    |> Map.from_struct()
    |> Enum.into(%{}, fn {k, v} -> {k, value_to_json(k, v)} end)
  end

  defp value_to_json(:query, query) do
    Query.to_json(query)
  end

  defp value_to_json(:filter, filter) do
    Enum.map(filter, &Filter.to_json/1)
  end

  defp value_to_json(:headway, headway) do
    Headway.to_json(headway)
  end
end
