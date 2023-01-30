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
                     rotation_normal_zero: [
                       :header_zero,
                       {:body_zero,
                        %{
                          body_normal_zero: [:main_content_zero],
                          body_split_zero: [:main_content_reduced_zero, :bottom_pane_zero]
                        }}
                     ],
                     rotation_takeover_zero: [:full_rotation_zero]
                   }},
                  {:rotation_one,
                   %{
                     rotation_normal_one: [
                       :header_one,
                       {:body_one,
                        %{
                          body_normal_one: [:main_content_one],
                          body_split_one: [:main_content_reduced_one, :bottom_pane_one]
                        }}
                     ],
                     rotation_takeover_one: [:full_rotation_one]
                   }},
                  {:rotation_two,
                   %{
                     rotation_normal_two: [
                       :header_two,
                       {:body_two,
                        %{
                          body_normal_two: [:main_content_two],
                          body_split_two: [:main_content_reduced_two, :bottom_pane_two]
                        }}
                     ],
                     rotation_takeover_two: [:full_rotation_two]
                   }}
                ]
              }} == Dup.screen_template()
    end
  end

  describe "header_instances/3" do
    test "returns expected header", %{config: config} do
      now = ~U[2020-04-06T10:00:00Z]
      fetch_stop_name_fn = fn _ -> "Test Stop" end

      expected_headers =
        %NormalHeader{
          screen: config,
          icon: :logo,
          text: "Test Stop",
          time: now
        }
        |> List.duplicate(3)

      actual_instances =
        Dup.header_instances(
          config,
          now,
          fetch_stop_name_fn
        )

      assert expected_headers == actual_instances
    end
  end
end
