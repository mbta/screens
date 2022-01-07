defmodule Screens.V2.CandidateGenerator.PreFareTest do
  use ExUnit.Case, async: true

  alias Screens.Config.{Screen, V2}
  alias Screens.V2.CandidateGenerator.PreFare

  setup do
    config = %Screen{
      app_params: %V2.PreFare{},
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
                     ]
                   }},
                  {:right,
                   %{
                     screen_normal_right: [
                       :header_right,
                       {:body,
                        %{
                          body_normal: [:main_content_right, :secondary_content],
                          body_takeover: [:full_body]
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
