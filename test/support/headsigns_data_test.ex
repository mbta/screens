defmodule Screens.Headsigns.Data.Test do
  @moduledoc false

  @headsign_abbreviations %{
    "Alewife" => ["Alewife"],
    "Back of the Hill" => ["Back of the Hill", "Back of Hill", "Back o'Hill"],
    "Boston University East" => ["Boston University East", "BU East"],
    "Brookline Village" => ["Brookline Village", "Brookline Vill", "B'kline Vil"],
    "Washington Street" => ["Washington St", "Washington"]
  }
  # TODO: Remove some
  @word_abbreviations %{
    "Avenue" => "Ave",
    "Boulevard" => "Blvd",
    "Center" => "Ctr",
    "Circle" => "Cir",
    "Cleveland" => "Clvlnd",
    "College" => "Coll",
    "Corner" => "Cn",
    "Court" => "Ct",
    "Drive" => "Dr",
    "East" => "E",
    "Express" => "Exp",
    "Government" => "Gov't",
    "Heights" => "Hts",
    "Landing" => "Ldg",
    "Lane" => "Ln",
    "Limited" => "Ltd",
    "One" => "1",
    "Park" => "Pk",
    "Parkway" => "Pkwy",
    "Place" => "Pl",
    "Point" => "Pt",
    "Road" => "Rd",
    "Saint" => "St.",
    "South" => "So",
    "Square" => "Sq",
    "Station" => "Stn",
    "Street" => "St",
    "Terrace" => "Ter",
    "Village" => "Vill",
    "Washington" => "Wash",
    "Way" => "Wy",
    "West" => "W"
  }

  def abbreviations, do: @headsign_abbreviations
  def word_abbreviations, do: @word_abbreviations
end
