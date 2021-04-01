defmodule Screens.V2.CandidateGenerator.DupTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.Dup

  describe "screen_template/0" do
    test "returns correct template" do
      assert {:screen,
              %{
                normal: [:header, :main_content],
                full_takeover: [:full_screen]
              }} == Dup.screen_template()
    end
  end
end
