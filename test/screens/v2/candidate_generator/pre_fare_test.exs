defmodule Screens.V2.CandidateGenerator.PreFareTest do
  use ExUnit.Case, async: true

  alias Screens.Config.{Screen, V2}
  alias Screens.V2.CandidateGenerator.PreFare

  setup do
    config = %Screen{
      app_params: %V2.PreFare{
        elevator_status: %V2.ElevatorStatus{parent_station_id: "111"}
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
                top_level: [
                  {:left,
                   %{
                     screen_normal_left: [
                       :header_left,
                       :main_content_left
                     ],
                     screen_takeover_left: [
                       :full_screen_left
                     ],
                     body_takeover_left: [:full_body_left]
                   }},
                  {:right,
                   %{
                     screen_normal_right: [
                       :header_right,
                       {:body,
                        %{
                          body_normal: [
                            :lower_right,
                            {{0, :upper_right},
                             %{
                               one_large: [{0, :large}],
                               two_medium: [{0, :medium_left}, {0, :medium_right}]
                             }},
                            {{1, :upper_right},
                             %{
                               one_large: [{1, :large}],
                               two_medium: [{1, :medium_left}, {1, :medium_right}]
                             }}
                          ],
                          body_takeover_right: [:full_body_right]
                        }}
                     ],
                     screen_takeover_right: [
                       :full_screen_right
                     ]
                   }}
                ]
              }} == PreFare.screen_template()
    end
  end
end
