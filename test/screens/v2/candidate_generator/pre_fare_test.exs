defmodule Screens.V2.CandidateGenerator.PreFareTest do
  use ExUnit.Case, async: true

  alias Screens.Config.{Screen, V2}
  alias Screens.V2.CandidateGenerator.PreFare

  setup do
    config = %Screen{
      app_params: %V2.PreFare{
        header: %V2.Header.CurrentStopName{stop_name: "test"}
      },
      vendor: :gds,
      device_id: "TEST",
      name: "TEST",
      app_id: :pre_fare_v2
    }

    %{config: config}
  end

  describe "screen_template/0" do
    test "returns template" do
      assert {:screen,
              %{
                screen_normal: [
                  :left_header,
                  :right_header,
                  {:body,
                   %{
                     left_body_normal: [
                       :main_content
                     ],
                     right_body_normal: [
                       {{0, :flex_zone},
                        %{
                          one_extra_large_one_large: [{0, :extra_large}, {0, :large}],
                          one_extra_large_two_medium: [
                            {0, :extra_large},
                            {0, :medium_left},
                            {0, :medium_right}
                          ],
                          one_extra_large_one_medium_two_small: [
                            {0, :extra_large},
                            {0, :medium_left},
                            {0, :small_upper_right},
                            {0, :small_lower_right}
                          ]
                        }},
                       {{1, :flex_zone},
                        %{
                          one_extra_large_one_large: [{1, :extra_large}, {1, :large}],
                          one_extra_large_two_medium: [
                            {1, :extra_large},
                            {1, :medium_left},
                            {1, :medium_right}
                          ],
                          one_extra_large_one_medium_two_small: [
                            {1, :extra_large},
                            {1, :medium_left},
                            {1, :small_upper_right},
                            {1, :small_lower_right}
                          ]
                        }},
                       {{2, :flex_zone},
                        %{
                          one_extra_large_one_large: [{2, :extra_large}, {2, :large}],
                          one_extra_large_two_medium: [
                            {2, :extra_large},
                            {2, :medium_left},
                            {2, :medium_right}
                          ],
                          one_extra_large_one_medium_two_small: [
                            {2, :extra_large},
                            {2, :medium_left},
                            {2, :small_upper_right},
                            {2, :small_lower_right}
                          ]
                        }}
                     ],
                     right_body_takeover: [:full_body]
                   }}
                ],
                left_screen_takeover: [:full_screen],
                right_screen_takeover: [:full_screen]
              }} == PreFare.screen_template()
    end
  end
end
