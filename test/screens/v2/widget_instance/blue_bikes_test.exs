defmodule Screens.V2.WidgetInstance.BlueBikesTest do
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.BlueBikes

  use ExUnit.Case, async: true

  setup do
    config =
      struct(ScreensConfig.Screen, %{
        app_params:
          struct(ScreensConfig.V2.PreFare, %{
            blue_bikes: %ScreensConfig.V2.BlueBikes{
              enabled: true,
              destination: "Back Bay",
              minutes_range_to_destination: "15-20",
              priority: [123],
              stations: [
                %ScreensConfig.V2.BlueBikes.Station{
                  id: "279",
                  arrow: :e,
                  walk_distance_minutes: 10,
                  walk_distance_feet: 2820
                },
                %ScreensConfig.V2.BlueBikes.Station{
                  id: "273",
                  arrow: :n,
                  walk_distance_minutes: 1,
                  walk_distance_feet: 282
                },
                %ScreensConfig.V2.BlueBikes.Station{
                  id: "11",
                  arrow: :ne,
                  walk_distance_minutes: 30,
                  walk_distance_feet: 8460
                }
              ]
            }
          })
      })

    statuses = %{
      "273" => %Screens.BlueBikes.StationStatus{
        name: "station 273",
        status: {:normal, %{num_bikes_available: 3, num_docks_available: 5}}
      },
      "279" => %Screens.BlueBikes.StationStatus{name: "station 279", status: :valet},
      "11" => %Screens.BlueBikes.StationStatus{name: "station 11", status: :out_of_service}
    }

    widget = %BlueBikes{screen: config, station_statuses: statuses}

    %{widget: widget}
  end

  describe "priority/1" do
    test "uses priority value from config", %{widget: widget} do
      assert [123] == WidgetInstance.priority(widget)
    end
  end

  describe "serialize/1" do
    test "serializes data", %{widget: widget} do
      # We expect stations list to be sorted by walk_distance_minutes ascending,
      # and limited to only 2 stations.
      expected = %{
        destination: "Back Bay",
        minutes_range_to_destination: "15-20",
        stations: [
          %{
            arrow: :n,
            id: "273",
            name: "station 273",
            num_bikes_available: 3,
            num_docks_available: 5,
            status: :normal,
            walk_distance_minutes: 1,
            walk_distance_feet: 282
          },
          %{
            arrow: :e,
            id: "279",
            name: "station 279",
            status: :valet,
            walk_distance_minutes: 10,
            walk_distance_feet: 2820
          }
        ]
      }

      assert expected == WidgetInstance.serialize(widget)
    end
  end

  describe "slot_names/1" do
    test "returns [:lower_right]", %{widget: widget} do
      assert [:orange_line_surge_upper] == WidgetInstance.slot_names(widget)
    end
  end

  describe "widget_type/1" do
    test "returns :blue_bikes", %{widget: widget} do
      assert :blue_bikes == WidgetInstance.widget_type(widget)
    end
  end

  describe "valid_candidate?/1" do
    test "returns true", %{widget: widget} do
      assert WidgetInstance.valid_candidate?(widget)
    end
  end

  describe "audio_serialize/1" do
    test "returns same data as serialize/1", %{widget: widget} do
      expected = WidgetInstance.serialize(widget)

      assert expected == WidgetInstance.audio_serialize(widget)
    end
  end

  describe "audio_sort_key/1" do
    test "returns [2]", %{widget: widget} do
      assert [2] == WidgetInstance.audio_sort_key(widget)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns true", %{widget: widget} do
      assert WidgetInstance.audio_valid_candidate?(widget)
    end
  end

  describe "audio_view/1" do
    test "returns view module", %{widget: widget} do
      assert ScreensWeb.V2.Audio.BlueBikesView == WidgetInstance.audio_view(widget)
    end
  end
end
