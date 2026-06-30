defmodule Screens.Headsigns.HeadsignTest do
  alias Screens.Headsigns.Headsign

  use ExUnit.Case

  describe "abbreviate_by_word/1" do
    test "single word with abbreviation" do
      assert Headsign.abbreviate_by_word("Street") == ["St"]
    end

    test "single word without abbreviation" do
      assert Headsign.abbreviate_by_word("Terminal") == ["Terminal"]
    end

    test "multiple words, all with abbreviations" do
      assert Headsign.abbreviate_by_word("Cleveland Street Avenue South") == [
               "Clvlnd St Ave So"
             ]
    end

    test "multiple words, mixed abbreviations and non-abbreviations" do
      assert Headsign.abbreviate_by_word("Main Street") == ["Main St"]
    end

    test "words with leading and trailing whitespace" do
      assert Headsign.abbreviate_by_word(" Tappan Street  ") == ["Tappan St"]
    end

    test "multiple spaces between words" do
      assert Headsign.abbreviate_by_word("Street  Avenue") == ["St Ave"]
    end

    test "special abbreviations with numbers" do
      assert Headsign.abbreviate_by_word("One") == ["1"]
    end

    test "special abbreviations with periods" do
      assert Headsign.abbreviate_by_word("Saint") == ["St."]
    end

    test "complex abbreviations with special characters" do
      assert Headsign.abbreviate_by_word("Government") == ["Gov't"]
    end
  end
end
