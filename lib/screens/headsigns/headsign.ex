defmodule Screens.Headsigns.Headsign do
  @moduledoc """
  Module for managing headsign abbreviations.
  """

  @data_module Application.compile_env(:screens, :headsigns_data_module, Screens.Headsigns.Data)

  @headsign_abbreviations @data_module.abbreviations()
  @word_abbreviations @data_module.word_abbreviations()

  @spec abbreviations(String.t()) :: [String.t()]
  def abbreviations(base_headsign) do
    case(Map.get(@headsign_abbreviations, base_headsign, [])) do
      [] -> abbreviate_by_word(base_headsign)
      abbreviations -> abbreviations |> Enum.uniq()
    end
  end

  @spec abbreviate_by_word(String.t()) :: [String.t()]
  defp abbreviate_by_word(base_headsign) do
    # Fallback case for when we don't have explicitly defined abbreviations for a headsign
    # Returns a single abbreviated headsign in which all words are abbreviated if possible, otherwise the original word is used.
    base_headsign
    |> String.trim()
    |> String.split(" ")
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&Map.get(@word_abbreviations, &1, String.trim(&1)))
    |> Enum.join(" ")
    |> List.wrap()
  end
end
