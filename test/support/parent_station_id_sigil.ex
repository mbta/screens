defmodule Screens.TestSupport.ParentStationIdSigil do
  @doc ~S"""
  Makes a single `"place-#{term}"` string, or a list of them if term contains 2+ words.
  Can be used in patterns and guards.

  ```
  iex> import Screens.TestSupport.ParentStationIdSigil

  iex> ~P"haecl"
  "place-haecl"

  iex> ~P[alfcl davis portr]
  ["place-alfcl", "place-davis", "place-portr"]

  # The use of "" vs [] doesn't make a difference, they just help to indicate the type.
  iex> ~P[haecl]
  "place-haecl"

  iex> ~P"alfcl davis portr"
  ["place-alfcl", "place-davis", "place-portr"]
  ```
  """
  defmacro sigil_P({:<<>>, _meta, [term]}, _modifiers) when is_binary(term) do
    case String.split(term) do
      [place_id] -> "place-#{place_id}"
      place_ids -> :lists.map(&"place-#{&1}", place_ids)
    end
  end
end
