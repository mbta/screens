defmodule Screens.V2.WidgetInstance.ShuttleBusInfoTest do
  use ExUnit.Case, async: true

  alias Screens.Config.Screen
  alias Screens.Config.V2.{PreFare, ShuttleBusInfo, ShuttleBusSchedule}
  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.ShuttleBusInfo, as: ShuttleBusInfoWidget

  setup do
    %{
      widget: %ShuttleBusInfoWidget{
        screen:
          struct(Screen, %{
            app_id: :pre_fare_v2,
            app_params:
              struct(PreFare, %{
                shuttle_bus_info: %ShuttleBusInfo{
                  minutes_range_to_destination_schedule: [
                    %ShuttleBusSchedule{
                      start_time: ~T[00:00:00],
                      end_time: ~T[10:00:00],
                      days: :weekday,
                      minute_range: "35-45"
                    },
                    %ShuttleBusSchedule{
                      start_time: ~T[11:00:00],
                      end_time: ~T[23:00:00],
                      days: :weekday,
                      minute_range: "15-25"
                    },
                    %ShuttleBusSchedule{
                      start_time: ~T[00:00:00],
                      end_time: ~T[10:59:59],
                      days: :sunday,
                      minute_range: "18-28"
                    },
                    %ShuttleBusSchedule{
                      start_time: ~T[11:00:00],
                      end_time: ~T[23:59:59],
                      days: :sunday,
                      minute_range: "17-27"
                    }
                  ],
                  destination: "Test Station",
                  arrow: :n,
                  english_boarding_instructions: "Hello",
                  spanish_boarding_instructions: "Hola",
                  audio_boarding_instructions: "Hi",
                  priority: [2, 3, 1]
                }
              })
          }),
        now: ~U[2022-08-18T08:00:00Z]
      },
      widget_not_pre_fare: %ShuttleBusInfoWidget{
        screen:
          struct(Screen, %{
            app_id: :bus_shelter_v2,
            app_params:
              struct(PreFare, %{
                shuttle_bus_info: %ShuttleBusInfo{
                  minutes_range_to_destination_schedule: [
                    %ShuttleBusSchedule{
                      start_time: "00:00:00",
                      end_time: "10:00:00",
                      days: :weekday,
                      minute_range: "35-45"
                    },
                    %ShuttleBusSchedule{
                      start_time: "11:00:00",
                      end_time: "23:00:00",
                      days: :weekday,
                      minute_range: "15-25"
                    }
                  ],
                  destination: "Test Station",
                  english_boarding_instructions: "Hello",
                  spanish_boarding_instructions: "Hola",
                  audio_boarding_instructions: "Hi",
                  arrow: :n,
                  priority: [2, 3, 1]
                }
              })
          })
      }
    }
  end

  defp put_now(widget, now) do
    %{widget | now: now}
  end

  describe "priority/1" do
    test "returns priority defined on the struct", %{widget: widget} do
      assert [2, 3, 1] == WidgetInstance.priority(widget)
    end
  end

  describe "serialize/1" do
    test "returns map with minutes_range_to_destination, destination, arrow, and boarding_instructions",
         %{
           widget: widget
         } do
      assert %{
               minutes_range_to_destination: "35-45",
               destination: "Test Station",
               arrow: :n,
               english_boarding_instructions: "Hello",
               spanish_boarding_instructions: "Hola"
             } == WidgetInstance.serialize(widget)

      widget = put_now(widget, ~U[2022-08-18T20:00:00Z])

      assert %{
               minutes_range_to_destination: "15-25",
               destination: "Test Station",
               arrow: :n,
               english_boarding_instructions: "Hello",
               spanish_boarding_instructions: "Hola"
             } == WidgetInstance.serialize(widget)

      widget = put_now(widget, ~U[2022-08-18T20:00:00Z])

      assert %{
               minutes_range_to_destination: "15-25",
               destination: "Test Station",
               arrow: :n,
               english_boarding_instructions: "Hello",
               spanish_boarding_instructions: "Hola"
             } == WidgetInstance.serialize(widget)
    end

    test "returns map with minutes_range_to_destination for correct service day",
         %{
           widget: widget
         } do
      widget = put_now(widget, ~U[2022-09-05T01:00:00Z])

      assert %{
               minutes_range_to_destination: "17-27",
               destination: "Test Station",
               arrow: :n,
               english_boarding_instructions: "Hello",
               spanish_boarding_instructions: "Hola"
             } == WidgetInstance.serialize(widget)
    end

    test "returns map with minutes_range_to_destination for correct day outside of DST",
         %{
           widget: widget
         } do
      widget = put_now(widget, ~U[2023-01-02T01:00:00Z])

      assert %{
               minutes_range_to_destination: "17-27",
               destination: "Test Station",
               arrow: :n,
               english_boarding_instructions: "Hello",
               spanish_boarding_instructions: "Hola"
             } == WidgetInstance.serialize(widget)
    end

    test "returns map with minutes_range_to_destination for correct day just before DST",
         %{
           widget: widget
         } do
      widget = put_now(widget, ~U[2022-03-13T08:00:00Z])

      assert %{
               minutes_range_to_destination: "18-28",
               destination: "Test Station",
               arrow: :n,
               english_boarding_instructions: "Hello",
               spanish_boarding_instructions: "Hola"
             } == WidgetInstance.serialize(widget)
    end
  end

  describe "slot_names/1" do
    test "returns slot names defined on the struct", %{widget: widget} do
      assert [:orange_line_surge_lower] == WidgetInstance.slot_names(widget)
    end
  end

  describe "widget_type/1" do
    test "returns :shuttle_bus_info", %{widget: widget} do
      assert :shuttle_bus_info == WidgetInstance.widget_type(widget)
    end
  end

  describe "valid_candidate?/1" do
    test "returns true for pre-fare", %{widget: widget} do
      assert WidgetInstance.valid_candidate?(widget)
    end

    test "returns false with old schedule", %{widget_not_pre_fare: widget_not_pre_fare} do
      refute WidgetInstance.valid_candidate?(widget_not_pre_fare)
    end
  end

  describe "audio_serialize/1" do
    test "returns map with minutes_range_to_destination, destination, and boarding_instructions",
         %{
           widget: widget
         } do
      assert %{
               minutes_range_to_destination: "35-45",
               destination: "Test Station",
               boarding_instructions: "Hi"
             } == WidgetInstance.audio_serialize(widget)

      widget = put_now(widget, ~U[2022-08-18T20:00:00Z])

      assert %{
               minutes_range_to_destination: "15-25",
               destination: "Test Station",
               boarding_instructions: "Hi"
             } == WidgetInstance.audio_serialize(widget)
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
    test "returns ShuttleBusInfoView", %{widget: widget} do
      assert ScreensWeb.V2.Audio.ShuttleBusInfoView == WidgetInstance.audio_view(widget)
    end
  end
end
