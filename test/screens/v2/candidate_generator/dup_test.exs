defmodule Screens.V2.CandidateGenerator.DupTest do
  use ExUnit.Case, async: true

  alias Screens.Config.{Screen, V2}
  alias Screens.V2.CandidateGenerator.Dup
  alias Screens.V2.WidgetInstance.NormalHeader

  setup do
    config = %Screen{
      app_params: %V2.Dup{
        header: %V2.Header.CurrentStopId{stop_id: "place-gover"},
        primary_departures: %V2.Departures{sections: []},
        secondary_departures: %V2.Departures{sections: []}
      },
      vendor: :outfront,
      device_id: "TEST",
      name: "TEST",
      app_id: :dup_v2
    }

    %{config: config}
  end

  describe "screen_template/0" do
    test "returns template" do
      assert {:screen,
              %{
                screen_normal: [
                  {:rotation_zero,
                   %{
                     body_normal_zero: [
                       :header_zero,
                       :main_content_primary_zero,
                       :inline_alert_zero
                     ],
                     screen_takeover_zero: [:full_screen_zero]
                   }},
                  {:rotation_one,
                   %{
                     body_normal_one: [
                       :header_one,
                       :main_content_primary_one
                     ],
                     screen_takeover_one: [:full_screen_one]
                   }},
                  {:rotation_two,
                   %{
                     body_normal_two: [
                       :header_two,
                       :main_content_secondary_two,
                       :inline_alert_two
                     ],
                     screen_takeover_two: [:full_screen_two]
                   }}
                ]
              }} == Dup.screen_template()
    end
  end

  describe "header_instances/3" do
    test "returns expected header", %{config: config} do
      now = ~U[2020-04-06T10:00:00Z]
      fetch_stop_name_fn = fn _ -> "Test Stop" end

      expected_header = [
        %NormalHeader{
          screen: config,
          icon: nil,
          text: "Test Stop",
          time: ~U[2020-04-06T10:00:00Z]
        }
      ]

      actual_instances =
        Dup.header_instances(
          config,
          now,
          fetch_stop_name_fn
        )

      assert Enum.all?(expected_header, fn x -> x in actual_instances end)
    end
  end
end
