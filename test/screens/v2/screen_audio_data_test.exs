defmodule Screens.V2.ScreenAudioDataTest do
  use ExUnit.Case, async: true

  alias Screens.Config.{Screen, V2}
  alias Screens.V2.ScreenAudioData
  alias Screens.V2.WidgetInstance.MockWidget

  setup do
    %{
      config_no_audio: %Screen{
        app_params: %V2.BusShelter{
          departures: %V2.Departures{sections: []},
          footer: %V2.Footer{},
          header: %V2.Header.CurrentStopId{stop_id: "1"},
          alerts: %V2.Alerts{stop_id: "1"}
        },
        vendor: :lg_mri,
        device_id: "TEST",
        name: "TEST",
        app_id: :bus_shelter_v2
      },
      config_audio_inactive: %Screen{
        app_params: %V2.BusShelter{
          audio: %V2.Audio{
            start_time: ~T[00:00:00],
            stop_time: ~T[01:00:00],
            daytime_start_time: ~T[00:00:00],
            daytime_stop_time: ~T[01:00:00],
            days_active: [1, 2, 3, 4, 5, 6, 7],
            daytime_volume: 0.1,
            nighttime_volume: 0.1
          },
          departures: %V2.Departures{sections: []},
          footer: %V2.Footer{},
          header: %V2.Header.CurrentStopId{stop_id: "1"},
          alerts: %V2.Alerts{stop_id: "1"}
        },
        vendor: :lg_mri,
        device_id: "TEST",
        name: "TEST",
        app_id: :bus_shelter_v2
      },
      config_valid_audio: %Screen{
        app_params: %V2.BusShelter{
          audio: %V2.Audio{
            start_time: ~T[00:00:00],
            stop_time: ~T[02:00:00],
            daytime_start_time: ~T[00:00:00],
            daytime_stop_time: ~T[01:00:00],
            days_active: [1, 2, 3, 4, 5, 6, 7],
            daytime_volume: 0.1,
            nighttime_volume: 0.1
          },
          departures: %V2.Departures{sections: []},
          footer: %V2.Footer{},
          header: %V2.Header.CurrentStopId{stop_id: "1"},
          alerts: %V2.Alerts{stop_id: "1"}
        },
        vendor: :lg_mri,
        device_id: "TEST",
        name: "TEST",
        app_id: :bus_shelter_v2
      },
      config_eink: %Screen{
        app_params: %V2.BusEink{
          departures: %V2.Departures{sections: []},
          footer: %V2.Footer{},
          header: %V2.Header.CurrentStopId{stop_id: "1"},
          alerts: %V2.Alerts{stop_id: "1"}
        },
        vendor: :gds,
        device_id: "TEST",
        name: "TEST",
        app_id: :bus_eink_v2
      }
    }
  end

  describe "by_screen_id/3" do
    test "returns a list of {audio_view, view_assigns_map} tuples", %{
      config_valid_audio: config_valid_audio
    } do
      screen_id = "123"
      now = ~U[2021-10-18T05:00:00Z]

      selected_instances = %{
        {0, :medium_left} => %MockWidget{
          slot_names: [:medium_left, :medium_right],
          audio_valid_candidate?: false,
          audio_sort_key: [2],
          content: "Alert"
        },
        :main_content => %MockWidget{
          slot_names: [:main_content],
          audio_valid_candidate?: true,
          audio_sort_key: [1],
          content: "Departures"
        },
        :header => %MockWidget{
          slot_names: [:header],
          audio_valid_candidate?: true,
          audio_sort_key: [0],
          content: "Header"
        }
      }

      get_config_fn = fn _screen_id -> config_valid_audio end

      fetch_data_fn = fn _config_valid_audio -> {:layout, selected_instances} end

      get_audio_only_instances_fn = fn _widgets, _config -> [] end

      audio_view = ScreensWeb.V2.Audio.MockWidgetView

      expected_data = [{audio_view, %{content: "Header"}}, {audio_view, %{content: "Departures"}}]

      assert expected_data ==
               ScreenAudioData.by_screen_id(
                 screen_id,
                 get_config_fn,
                 fetch_data_fn,
                 get_audio_only_instances_fn,
                 now
               )
    end

    test "returns an empty list if audio not in valid date range", %{
      config_audio_inactive: config_audio_inactive
    } do
      screen_id = "123"
      now = ~U[2021-10-18T15:00:00Z]

      selected_instances = %{
        {0, :medium_left} => %MockWidget{
          slot_names: [:medium_left, :medium_right],
          audio_valid_candidate?: false,
          audio_sort_key: [2],
          content: "Alert"
        },
        :main_content => %MockWidget{
          slot_names: [:main_content],
          audio_valid_candidate?: true,
          audio_sort_key: [1],
          content: "Departures"
        },
        :header => %MockWidget{
          slot_names: [:header],
          audio_valid_candidate?: true,
          audio_sort_key: [0],
          content: "Header"
        }
      }

      get_config_fn = fn _screen_id -> config_audio_inactive end

      fetch_data_fn = fn _config_audio_inactive -> {:layout, selected_instances} end

      get_audio_only_instances_fn = fn _widgets, _config -> [] end

      expected_data = []

      assert expected_data ==
               ScreenAudioData.by_screen_id(
                 screen_id,
                 get_config_fn,
                 fetch_data_fn,
                 get_audio_only_instances_fn,
                 now
               )
    end

    test "returns an empty list if audio config is missing", %{
      config_no_audio: config_no_audio
    } do
      screen_id = "123"
      now = ~U[2021-10-18T15:00:00Z]

      selected_instances = %{
        {0, :medium_left} => %MockWidget{
          slot_names: [:medium_left, :medium_right],
          audio_valid_candidate?: false,
          audio_sort_key: [2],
          content: "Alert"
        },
        :main_content => %MockWidget{
          slot_names: [:main_content],
          audio_valid_candidate?: true,
          audio_sort_key: [1],
          content: "Departures"
        },
        :header => %MockWidget{
          slot_names: [:header],
          audio_valid_candidate?: true,
          audio_sort_key: [0],
          content: "Header"
        }
      }

      get_config_fn = fn _screen_id -> config_no_audio end

      fetch_data_fn = fn _config_no_audio -> {:layout, selected_instances} end

      get_audio_only_instances_fn = fn _widgets, _config -> [] end

      expected_data = []

      assert expected_data ==
               ScreenAudioData.by_screen_id(
                 screen_id,
                 get_config_fn,
                 fetch_data_fn,
                 get_audio_only_instances_fn,
                 now
               )
    end

    test "returns an error if not a screen with defined audio equivalence", %{
      config_eink: config_eink
    } do
      screen_id = "123"
      now = ~U[2021-10-18T15:00:00Z]

      selected_instances = %{
        {0, :medium_left} => %MockWidget{
          slot_names: [:medium_left, :medium_right],
          audio_valid_candidate?: false,
          audio_sort_key: [2],
          content: "Alert"
        },
        :main_content => %MockWidget{
          slot_names: [:main_content],
          audio_valid_candidate?: true,
          audio_sort_key: [1],
          content: "Departures"
        },
        :header => %MockWidget{
          slot_names: [:header],
          audio_valid_candidate?: true,
          audio_sort_key: [0],
          content: "Header"
        }
      }

      get_config_fn = fn _screen_id -> config_eink end

      fetch_data_fn = fn _config_eink -> {:layout, selected_instances} end

      get_audio_only_instances_fn = fn _widgets, _config -> [] end

      expected_data = :error

      assert expected_data ==
               ScreenAudioData.by_screen_id(
                 screen_id,
                 get_config_fn,
                 fetch_data_fn,
                 get_audio_only_instances_fn,
                 now
               )
    end

    test "adds audio-only widgets to the readout data as defined by the audio_only_instances candidate generator function",
         %{config_valid_audio: config_valid_audio} do
      screen_id = "123"
      now = ~U[2021-10-18T05:00:00Z]

      selected_instances = %{
        {0, :medium_left} => %MockWidget{
          slot_names: [:medium_left, :medium_right],
          audio_valid_candidate?: true,
          audio_sort_key: [2],
          content: "Alert"
        },
        :main_content => %MockWidget{
          slot_names: [:main_content],
          audio_valid_candidate?: true,
          audio_sort_key: [1],
          content: "Departures"
        },
        :header => %MockWidget{
          slot_names: [:header],
          audio_valid_candidate?: true,
          audio_sort_key: [0],
          content: "Header"
        }
      }

      get_config_fn = fn _screen_id -> config_valid_audio end

      fetch_data_fn = fn _config_valid_audio -> {:layout, selected_instances} end

      get_audio_only_instances_fn = fn _widgets, _config ->
        [
          %MockWidget{
            slot_names: [:nothing],
            audio_valid_candidate?: true,
            audio_sort_key: [0, 1],
            content: "Content Summary"
          },
          %MockWidget{
            slot_names: [:nothing],
            audio_valid_candidate?: true,
            audio_sort_key: [1, 1],
            content: "Alerts Summary"
          },
          %MockWidget{
            slot_names: [:nothing],
            audio_valid_candidate?: false,
            audio_sort_key: [0],
            content: "SoundOfNailsOnChalkboard Widget"
          }
        ]
      end

      audio_view = ScreensWeb.V2.Audio.MockWidgetView

      expected_data = [
        {audio_view, %{content: "Header"}},
        {audio_view, %{content: "Content Summary"}},
        {audio_view, %{content: "Departures"}},
        {audio_view, %{content: "Alerts Summary"}},
        {audio_view, %{content: "Alert"}}
      ]

      assert expected_data ==
               ScreenAudioData.by_screen_id(
                 screen_id,
                 get_config_fn,
                 fetch_data_fn,
                 get_audio_only_instances_fn,
                 now
               )
    end
  end

  describe "time_in_range?/1" do
    test "returns false for a time before a normal range" do
      t = ~T[01:00:00]
      start_time = ~T[05:00:00]
      stop_time = ~T[07:00:00]

      refute ScreenAudioData.time_in_range?(t, start_time, stop_time)
    end

    test "returns false for a time after a normal range" do
      t = ~T[09:00:00]
      start_time = ~T[05:00:00]
      stop_time = ~T[07:00:00]

      refute ScreenAudioData.time_in_range?(t, start_time, stop_time)
    end

    test "returns true for a time at start of a normal range" do
      t = ~T[05:00:00]
      start_time = ~T[05:00:00]
      stop_time = ~T[07:00:00]

      assert ScreenAudioData.time_in_range?(t, start_time, stop_time)
    end

    test "returns false for a time at end of a normal range" do
      t = ~T[07:00:00]
      start_time = ~T[05:00:00]
      stop_time = ~T[07:00:00]

      refute ScreenAudioData.time_in_range?(t, start_time, stop_time)
    end

    test "returns true for a time within a normal range" do
      t = ~T[06:00:00]
      start_time = ~T[05:00:00]
      stop_time = ~T[07:00:00]

      assert ScreenAudioData.time_in_range?(t, start_time, stop_time)
    end

    #############################

    test "returns false for a time outside an inverted range" do
      t = ~T[06:00:00]
      start_time = ~T[07:00:00]
      stop_time = ~T[05:00:00]

      refute ScreenAudioData.time_in_range?(t, start_time, stop_time)
    end

    test "returns true for a time at start of an inverted range" do
      t = ~T[07:00:00]
      start_time = ~T[07:00:00]
      stop_time = ~T[05:00:00]

      assert ScreenAudioData.time_in_range?(t, start_time, stop_time)
    end

    test "returns false for a time at end of an inverted range" do
      t = ~T[05:00:00]
      start_time = ~T[07:00:00]
      stop_time = ~T[05:00:00]

      refute ScreenAudioData.time_in_range?(t, start_time, stop_time)
    end

    test "returns true for a time within an inverted range (after start/before midnight)" do
      t = ~T[08:00:00]
      start_time = ~T[07:00:00]
      stop_time = ~T[05:00:00]

      assert ScreenAudioData.time_in_range?(t, start_time, stop_time)
    end

    test "returns true for a time within an inverted range (before end/after midnight)" do
      t = ~T[04:00:00]
      start_time = ~T[07:00:00]
      stop_time = ~T[05:00:00]

      assert ScreenAudioData.time_in_range?(t, start_time, stop_time)
    end
  end
end
