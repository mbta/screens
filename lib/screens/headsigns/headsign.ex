defmodule Screens.Headsigns.Headsign do
  @moduledoc """
  Module for managing headsign abbreviations.
  """

  alias Screens.Headsigns.Data, as: HeadsignData

  @spec abbreviations(String.t()) :: [String.t()]
  def abbreviations(base_headsign) do
    case(Map.get(HeadsignData.abbreviations(), base_headsign, [])) do
      [] ->
        Enum.uniq([base_headsign, abbreviate_by_word(base_headsign)])

      abbreviations ->
        abbreviations |> Enum.uniq()
    end
  end

  @spec abbreviate_by_word(String.t()) :: String.t()
  defp abbreviate_by_word(base_headsign) do
    # Fallback case for when we don't have explicitly defined abbreviations for a headsign
    # Returns a single abbreviated headsign in which all words are abbreviated if possible, otherwise the original word is used.
    base_headsign
    |> String.trim()
    |> String.split(" ")
    |> Enum.reject(&(&1 == ""))
    |> Enum.map_join(" ", &Map.get(HeadsignData.word_abbreviations(), &1, String.trim(&1)))
  end
end
