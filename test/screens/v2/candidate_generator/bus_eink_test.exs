defmodule Screens.V2.CandidateGenerator.BusEinkTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.BusEink

  describe "screen_template/0" do
    test "returns correct template" do
      assert {:screen,
              %{
                normal: [
                  :header,
                  :main_content,
                  :medium_flex,
                  :footer
                ],
                bottom_takeover: [
                  :header,
                  :main_content,
                  :bottom_screen
                ],
                full_takeover: [:full_screen]
              }} == BusEink.screen_template()
    end
  end
end
