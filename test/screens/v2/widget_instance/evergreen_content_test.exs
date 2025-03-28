defmodule Screens.V2.WidgetInstance.EvergreenContentTest do
  use ExUnit.Case, async: true

  alias Screens.V2.WidgetInstance
  alias Screens.V2.WidgetInstance.EvergreenContent
  alias ScreensConfig.{Schedule, Screen}

  setup do
    %{
      widget: %EvergreenContent{
        screen: %Screen{app_params: nil, vendor: nil, device_id: nil, name: nil, app_id: nil},
        slot_names: [:medium_left, :medium_right],
        asset_url: "https://mbta-screens.s3.amazonaws.com/screens-dev/videos/some-video.mp4",
        priority: [2, 3, 1],
        schedule: [%Schedule{}],
        now: ~U[2021-02-01T00:00:00Z],
        text_for_audio: "This is text.",
        audio_priority: [1, 3, 2]
      },
      widget_old_schedule: %EvergreenContent{
        screen: %Screen{app_params: nil, vendor: nil, device_id: nil, name: nil, app_id: nil},
        slot_names: [:medium_left, :medium_right],
        asset_url: "https://mbta-screens.s3.amazonaws.com/screens-dev/videos/some-video.mp4",
        priority: [2, 3, 1],
        schedule: [
          %Schedule{start_dt: ~U[2021-01-01T00:00:00Z], end_dt: ~U[2021-01-02T00:00:00Z]}
        ],
        now: ~U[2021-02-01T00:00:00Z]
      },
      widget_no_audio: %EvergreenContent{
        screen: %Screen{app_params: nil, vendor: nil, device_id: nil, name: nil, app_id: nil},
        slot_names: [:medium_left, :medium_right],
        asset_url: "https://mbta-screens.s3.amazonaws.com/screens-dev/videos/some-video.mp4",
        priority: [2, 3, 1],
        schedule: [%Schedule{}],
        now: ~U[2021-02-01T00:00:00Z]
      }
    }
  end

  describe "priority/1" do
    test "returns priority defined on the struct", %{widget: widget} do
      assert [2, 3, 1] == WidgetInstance.priority(widget)
    end
  end

  describe "serialize/1" do
    test "returns asset url in a map", %{widget: widget} do
      assert %{
               asset_url:
                 "https://mbta-screens.s3.amazonaws.com/screens-dev/videos/some-video.mp4"
             } == WidgetInstance.serialize(widget)
    end
  end

  describe "slot_names/1" do
    test "returns slot names defined on the struct", %{widget: widget} do
      assert [:medium_left, :medium_right] == WidgetInstance.slot_names(widget)
    end
  end

  describe "widget_type/1" do
    test "returns :evergreen_content", %{widget: widget} do
      assert :evergreen_content == WidgetInstance.widget_type(widget)
    end
  end

  describe "valid_candidate?/1 with \"classic\" schedule" do
    test "returns true with blank schedule", %{widget: widget} do
      assert WidgetInstance.valid_candidate?(widget)
    end

    test "returns false with old schedule", %{widget_old_schedule: widget_old_schedule} do
      refute WidgetInstance.valid_candidate?(widget_old_schedule)
    end
  end

  describe "valid_candidate?/1 with recurrent schedule" do
    setup do
      %{
        widget_non_overnight_schedule:
          struct(EvergreenContent, %{
            schedule: %{
              dates: [%{start_date: ~D[2023-01-05], end_date: ~D[2023-01-10]}],
              times: [%{start_time_utc: ~T[06:30:00], end_time_utc: ~T[17:00:00]}]
            }
          }),
        widget_overnight_schedule:
          struct(EvergreenContent, %{
            schedule: %{
              dates: [%{start_date: ~D[2023-01-05], end_date: ~D[2023-01-10]}],
              times: [%{start_time_utc: ~T[22:00:00], end_time_utc: ~T[03:00:00]}]
            }
          }),
        widget_multi_schedule:
          struct(EvergreenContent, %{
            schedule: %{
              dates: [
                %{start_date: ~D[2023-01-05], end_date: ~D[2023-01-10]},
                %{start_date: ~D[2023-02-05], end_date: ~D[2023-02-10]}
              ],
              times: [
                %{start_time_utc: ~T[06:30:00], end_time_utc: ~T[17:00:00]},
                %{start_time_utc: ~T[22:00:00], end_time_utc: ~T[03:00:00]}
              ]
            }
          })
      }
    end

    # Recurrent schedule: basic cases

    test "recurrent schedule: returns false for empty schedule" do
      widget =
        struct(EvergreenContent, %{
          now: ~U[2023-01-05T12:00:00Z],
          schedule: %{
            dates: [],
            times: []
          }
        })

      refute WidgetInstance.valid_candidate?(widget)
    end

    test "recurrent schedule: returns false for schedule with no dates" do
      widget =
        struct(EvergreenContent, %{
          now: ~U[2023-01-05T12:00:00Z],
          schedule: %{
            dates: [],
            times: [%{start_time_utc: ~T[06:30:00], end_time_utc: ~T[17:00:00]}]
          }
        })

      refute WidgetInstance.valid_candidate?(widget)
    end

    test "recurrent schedule: returns false for schedule with no times" do
      widget =
        struct(EvergreenContent, %{
          now: ~U[2023-01-05T12:00:00Z],
          schedule: %{
            dates: [%{start_date: ~D[2023-01-01], end_date: ~D[2023-01-10]}],
            times: []
          }
        })

      refute WidgetInstance.valid_candidate?(widget)
    end

    # Recurrent schedule: non-overnight time period

    test "recurrent schedule: returns true for schedule with non-overnight time period, now is within date and time",
         %{widget_non_overnight_schedule: widget} do
      widget = %{widget | now: ~U[2023-01-05T12:00:00Z]}

      assert WidgetInstance.valid_candidate?(widget)

      widget = %{widget | now: ~U[2023-01-06T12:00:00Z]}

      assert WidgetInstance.valid_candidate?(widget)

      widget = %{widget | now: ~U[2023-01-10T12:00:00Z]}

      assert WidgetInstance.valid_candidate?(widget)
    end

    test "recurrent schedule: returns false for schedule with non-overnight time period, now is outside date",
         %{widget_non_overnight_schedule: widget} do
      widget = %{widget | now: ~U[2023-01-04T12:00:00Z]}

      refute WidgetInstance.valid_candidate?(widget)

      widget = %{widget | now: ~U[2023-01-11T12:00:00Z]}

      refute WidgetInstance.valid_candidate?(widget)
    end

    test "recurrent schedule: returns false for schedule with non-overnight time period, now is outside time",
         %{widget_non_overnight_schedule: widget} do
      widget = %{widget | now: ~U[2023-01-05T06:29:59Z]}

      refute WidgetInstance.valid_candidate?(widget)

      widget = %{widget | now: ~U[2023-01-05T17:00:00Z]}

      refute WidgetInstance.valid_candidate?(widget)
    end

    test "recurrent schedule: returns false for schedule with non-overnight time period, now is outside date and time",
         %{widget_non_overnight_schedule: widget} do
      widget = %{widget | now: ~U[2023-02-18T21:00:00Z]}

      refute WidgetInstance.valid_candidate?(widget)
    end

    # Recurrent schedule: overnight time period
    # date: 1/5 - 1/10
    # time: 22:00 - 03:00

    test "recurrent_schedule: returns false for schedule with overnight time period, now is before UTC midnight + within time range + on start date - 1",
         %{widget_overnight_schedule: widget} do
      widget = %{widget | now: ~U[2023-01-04T23:00:00Z]}

      refute WidgetInstance.valid_candidate?(widget)
    end

    test "recurrent_schedule: returns false for schedule with overnight time period, now is after UTC midnight + within time range + on start date",
         %{widget_overnight_schedule: widget} do
      widget = %{widget | now: ~U[2023-01-05T01:00:00Z]}

      refute WidgetInstance.valid_candidate?(widget)
    end

    test "recurrent_schedule: returns true for schedule with overnight time period, now is before UTC midnight + within time range + on start date",
         %{widget_overnight_schedule: widget} do
      widget = %{widget | now: ~U[2023-01-05T22:00:00Z]}

      assert WidgetInstance.valid_candidate?(widget)
    end

    test "recurrent_schedule: returns false for schedule with overnight time period, now is outside of time range + within date range",
         %{widget_overnight_schedule: widget} do
      widget = %{widget | now: ~U[2023-01-05T12:00:00Z]}

      refute WidgetInstance.valid_candidate?(widget)
    end

    test "recurrent_schedule: returns true for schedule with overnight time period, now is before UTC midnight + within time range + on end date",
         %{widget_overnight_schedule: widget} do
      widget = %{widget | now: ~U[2023-01-10T23:00:00Z]}

      assert WidgetInstance.valid_candidate?(widget)
    end

    test "recurrent_schedule: returns true for schedule with overnight time period, now is after UTC midnight + within time range + on end date + 1",
         %{widget_overnight_schedule: widget} do
      widget = %{widget | now: ~U[2023-01-11T01:00:00Z]}

      assert WidgetInstance.valid_candidate?(widget)
    end

    test "recurrent_schedule: returns false for schedule with overnight time period, now is outside of time range + on end date + 1",
         %{widget_overnight_schedule: widget} do
      widget = %{widget | now: ~U[2023-01-11T12:00:00Z]}

      refute WidgetInstance.valid_candidate?(widget)
    end

    test "recurrent_schedule: returns false for schedule with overnight time period, now is before UTC midnight + within time range + on end date + 1",
         %{widget_overnight_schedule: widget} do
      widget = %{widget | now: ~U[2023-01-11T23:00:00Z]}

      refute WidgetInstance.valid_candidate?(widget)
    end

    test "recurrent_schedule: returns false for schedule with overnight time period, now is after UTC midnight + within time range + on end date + 2",
         %{widget_overnight_schedule: widget} do
      widget = %{widget | now: ~U[2023-01-12T01:00:00Z]}

      refute WidgetInstance.valid_candidate?(widget)
    end

    test "recurrent_schedule: returns false for schedule with overnight time period, now is outside of time range + on end date + 2",
         %{widget_overnight_schedule: widget} do
      widget = %{widget | now: ~U[2023-01-12T12:00:00Z]}

      refute WidgetInstance.valid_candidate?(widget)
    end

    test "recurrent_schedule: returns false for schedule with overnight time period, now is before UTC midnight + within of time range + on end date + 2",
         %{widget_overnight_schedule: widget} do
      widget = %{widget | now: ~U[2023-01-12T23:00:00Z]}

      refute WidgetInstance.valid_candidate?(widget)
    end

    # Multiple dates/times

    test "recurrent_schedule: returns true if any date and any time matches when there are multiple",
         %{widget_multi_schedule: widget} do
      widget = %{widget | now: ~U[2023-02-06T12:00:00Z]}

      assert WidgetInstance.valid_candidate?(widget)
    end

    test "recurrent_schedule: returns false if either no date or no time matches when there are multiple",
         %{widget_multi_schedule: widget} do
      widget = %{widget | now: ~U[2023-03-06T12:00:00Z]}

      refute WidgetInstance.valid_candidate?(widget)

      widget = %{widget | now: ~U[2023-02-06T18:00:00Z]}

      refute WidgetInstance.valid_candidate?(widget)

      widget = %{widget | now: ~U[2023-03-06T18:00:00Z]}

      refute WidgetInstance.valid_candidate?(widget)
    end
  end

  describe "audio_serialize/1" do
    test "returns map with text to read out", %{widget: widget} do
      assert %{text_for_audio: "This is text."} == WidgetInstance.audio_serialize(widget)
    end
  end

  describe "audio_sort_key/1" do
    test "returns audio_priority defined on the struct", %{widget: widget} do
      assert [1, 3, 2] == WidgetInstance.audio_sort_key(widget)
    end
  end

  describe "audio_valid_candidate?/1" do
    test "returns true for widgets with configured text", %{widget: widget} do
      assert WidgetInstance.audio_valid_candidate?(widget)
    end

    test "returns false for widgets without configured audio", %{widget_no_audio: widget_no_audio} do
      refute WidgetInstance.audio_valid_candidate?(widget_no_audio)
    end
  end

  describe "audio_view/1" do
    test "returns EvergreenContentView", %{widget: widget} do
      assert ScreensWeb.V2.Audio.EvergreenContentView == WidgetInstance.audio_view(widget)
    end
  end
end
