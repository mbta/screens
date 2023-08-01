defmodule Screens.TestSupport.ParentStationIdSigil do
  @doc ~S"""
  Makes a single "place-#{term}" string, or a list of them if term contains 2+ words.
  """
  defmacro sigil_P(term, _modifiers) do
    quote do
      case String.split(unquote(term)) do
        [place_id] -> "place-#{place_id}"
        place_ids -> Enum.map(place_ids, &"place-#{&1}")
      end
    end
  end
end
