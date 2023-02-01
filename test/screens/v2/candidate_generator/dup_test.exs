defmodule Screens.V2.CandidateGenerator.DupTest do
  use ExUnit.Case, async: true

  alias Screens.Config.{Screen, V2}
  alias Screens.V2.CandidateGenerator.Dup
  alias Screens.V2.WidgetInstance.{Departures, NormalHeader}

  setup do
    config = %Screen{
      app_params: %V2.Dup{
        header: %V2.Header.CurrentStopId{stop_id: "place-gover"},
        primary_departures: %V2.Departures{
          sections: [
            %V2.Departures.Section{query: "query A", filter: nil},
            %V2.Departures.Section{query: "query B", filter: nil}
          ]
        },
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

  describe "candidate_instances/4" do
    test "returns expected header and departures", %{config: config} do
      now = ~U[2020-04-06T10:00:00Z]
      fetch_stop_fn = fn "place-gover" -> "Government Center" end

      fetch_section_departures_fn = fn
        %V2.Departures.Section{query: "query A"} -> {:ok, []}
        %V2.Departures.Section{query: "query B"} -> {:ok, []}
      end

      expected_header =
        List.duplicate(
          %NormalHeader{
            screen: config,
            icon: :logo,
            text: "Government Center",
            time: ~U[2020-04-06T10:00:00Z]
          },
          3
        )

      expected_departures = [
        %Departures{
          screen: config,
          section_data: [
            %{type: :normal_section, rows: []},
            %{type: :normal_section, rows: []}
          ],
          slot_names: [:main_content_zero]
        },
        %Departures{
          screen: config,
          section_data: [
            %{type: :normal_section, rows: []},
            %{type: :normal_section, rows: []}
          ],
          slot_names: [:main_content_one]
        },
        %Departures{
          screen: config,
          section_data: [
            %{type: :normal_section, rows: []},
            %{type: :normal_section, rows: []}
          ],
          slot_names: [:main_content_two]
        }
      ]

      actual_instances =
        Dup.candidate_instances(
          config,
          now,
          fetch_stop_fn,
          fetch_section_departures_fn
        )

      assert Enum.all?(expected_header, &Enum.member?(actual_instances, &1))
      assert Enum.all?(expected_departures, &Enum.member?(actual_instances, &1))
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
