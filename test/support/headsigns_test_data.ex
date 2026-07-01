defmodule Screens.Headsigns.Data.Test do
  @moduledoc false

  @headsign_abbreviations %{
    "Alewife" => ["Alewife"],
    "Back of the Hill" => ["Back of the Hill", "Back of Hill", "Back o'Hill"],
    "Boston University East" => ["Boston University East", "BU East"],
    "Brookline Village" => ["Brookline Village", "Brookline Vill", "B'kline Vil"]
  }

  @word_abbreviations %{
    "Avenue" => "Ave",
    "Cleveland" => "Clvlnd",
    "East" => "E",
    "Government" => "Gov't",
    "One" => "1",
    "Place" => "Pl",
    "Saint" => "St.",
    "South" => "So",
    "Street" => "St"
  }

  def abbreviations, do: @headsign_abbreviations
  def word_abbreviations, do: @word_abbreviations
end
