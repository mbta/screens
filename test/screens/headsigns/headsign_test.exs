defmodule Screens.Headsigns.HeadsignTest do
  alias Screens.Headsigns.Headsign

  use ExUnit.Case

  describe "abbreviations/1" do
    test "headsign with explicit abbreviations" do
      assert Headsign.abbreviations("Alewife") == ["Alewife"]

      assert Headsign.abbreviations("Back of the Hill") == [
               "Back of the Hill",
               "Back of Hill",
               "Back o'Hill"
             ]

      assert Headsign.abbreviations("Brookline Village") == [
               "Brookline Village",
               "Brookline Vill",
               "B'kline Vil"
             ]

      assert Headsign.abbreviations("Boston University East") == [
               "Boston University East",
               "BU East"
             ]
    end

    test "single word with abbreviation" do
      assert Headsign.abbreviations("Street") == ["St"]
    end

    test "single word without abbreviation" do
      assert Headsign.abbreviations("Terminal") == ["Terminal"]
    end

    test "multiple words, all with abbreviations" do
      assert Headsign.abbreviations("Cleveland Street Avenue South") == [
               "Clvlnd St Ave So"
             ]
    end

    test "multiple words, mixed abbreviations and non-abbreviations" do
      assert Headsign.abbreviations("Main Street") == ["Main St"]
    end

    test "words with leading and trailing whitespace" do
      assert Headsign.abbreviations(" Tappan Street  ") == ["Tappan St"]
    end

    test "multiple spaces between words" do
      assert Headsign.abbreviations("Street  Avenue") == ["St Ave"]
    end

    test "special abbreviations with numbers" do
      assert Headsign.abbreviations("One") == ["1"]
    end

    test "special abbreviations with periods" do
      assert Headsign.abbreviations("Saint") == ["St."]
    end

    test "complex abbreviations with special characters" do
      assert Headsign.abbreviations("Government") == ["Gov't"]
    end
  end
end
