defmodule Screens.V2.CandidateGenerator.SolariLargeTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.SolariLarge

  describe "screen_template/0" do
    test "returns correct template" do
      assert {:screen,
              %{
                normal: [:header, :main_content],
                takeover: [:full_screen]
              }} == SolariLarge.screen_template()
    end
  end
end
