defmodule Screens.V2.CandidateGenerator.PreFareTest do
  use ExUnit.Case, async: true

  alias Screens.Config.{Screen, V2}
  alias Screens.V2.CandidateGenerator.PreFare
  alias Screens.V2.WidgetInstance.NormalHeader

  setup do
    config = %Screen{
      app_params: %V2.PreFare{
        header: %V2.Header.CurrentStopName{stop_name: "Test Station"},
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
                screen_normal: [
                  :header,
                  {:body,
                   %{
                     body_normal: [
                       body_left: %{
                         body_left_normal: [:main_content_left],
                         body_left_takeover: [:full_body_left]
                       },
                       body_right: %{
                         body_right_normal: [
                           {{0, :upper_right},
                            %{
                              one_large: [{0, :large}],
                              two_medium: [{0, :medium_left}, {0, :medium_right}]
                            }},
                           {{1, :upper_right},
                            %{
                              one_large: [{1, :large}],
                              two_medium: [{1, :medium_left}, {1, :medium_right}]
                            }},
                           :lower_right
                         ],
                         body_right_takeover: [:full_body_right]
                       }
                     ],
                     body_takeover: [:full_body]
                   }}
                ],
                screen_takeover: [:full_screen]
              }} == PreFare.screen_template()
    end
  end

  describe "candidate_instances/3" do
    test "returns expected header", %{config: config} do
      now = ~U[2020-04-06T10:00:00Z]
      elevator_status_instances_fn = fn _, _ -> [] end

      expected_header = [
        %NormalHeader{
          screen: config,
          icon: nil,
          text: "Test Station",
          time: ~U[2020-04-06T10:00:00Z]
        },
        %NormalHeader{
          screen: config,
          icon: nil,
          text: "Test Station",
          time: ~U[2020-04-06T10:00:00Z]
        }
      ]

      actual_instances =
        PreFare.candidate_instances(
          config,
          now,
          elevator_status_instances_fn
        )

      assert Enum.all?(expected_header, fn x -> x in actual_instances end)
    end
  end
end
