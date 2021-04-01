defmodule Screens.V2.CandidateGenerator.BusShelterTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.BusShelter

  describe "screen_template/0" do
    test "returns template" do
      assert {:screen,
              %{
                normal: [
                  :header,
                  :main_content,
                  {:flex_zone,
                   %{
                     one_large: [:large],
                     one_medium_two_small: [:medium_left, :small_upper_right, :small_lower_right],
                     two_medium: [:medium_left, :medium_right]
                   }},
                  :footer
                ],
                takeover: [:full_screen]
              }} == BusShelter.screen_template()
    end
  end
end
