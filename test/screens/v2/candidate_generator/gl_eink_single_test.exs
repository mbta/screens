defmodule Screens.V2.CandidateGenerator.GlEinkSingleTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.GlEinkSingle

  describe "screen_template/0" do
    test "returns correct template" do
      assert {:screen,
              %{
                normal: [
                  :header,
                  :main_content,
                  :footer
                ],
                full_takeover: [:full_screen]
              }} == GlEinkSingle.screen_template()
    end
  end
end
