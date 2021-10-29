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
          audio_sort_key: 2,
          content: "Alert"
        },
        :main_content => %MockWidget{
          slot_names: [:main_content],
          audio_valid_candidate?: true,
          audio_sort_key: 1,
          content: "Departures"
        },
        :header => %MockWidget{
          slot_names: [:header],
          audio_valid_candidate?: true,
          audio_sort_key: 0,
          content: "Header"
        }
      }

      get_config_fn = fn _screen_id -> config_valid_audio end

      fetch_data_fn = fn _config_valid_audio -> {:layout, selected_instances} end

      audio_view = ScreensWeb.V2.Audio.MockWidgetView

      expected_data = [{audio_view, %{content: "Header"}}, {audio_view, %{content: "Departures"}}]

      assert expected_data ==
               ScreenAudioData.by_screen_id(screen_id, get_config_fn, fetch_data_fn, now)
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
          audio_sort_key: 2,
          content: "Alert"
        },
        :main_content => %MockWidget{
          slot_names: [:main_content],
          audio_valid_candidate?: true,
          audio_sort_key: 1,
          content: "Departures"
        },
        :header => %MockWidget{
          slot_names: [:header],
          audio_valid_candidate?: true,
          audio_sort_key: 0,
          content: "Header"
        }
      }

      get_config_fn = fn _screen_id -> config_audio_inactive end

      fetch_data_fn = fn _config_audio_inactive -> {:layout, selected_instances} end

      expected_data = []

      assert expected_data ==
               ScreenAudioData.by_screen_id(screen_id, get_config_fn, fetch_data_fn, now)
    end

    test "returns an empty list if audio config is missing", %{
      config_no_audio: config_no_audio
    } do
      screen_id = "123"

      selected_instances = %{
        {0, :medium_left} => %MockWidget{
          slot_names: [:medium_left, :medium_right],
          audio_valid_candidate?: false,
          audio_sort_key: 2,
          content: "Alert"
        },
        :main_content => %MockWidget{
          slot_names: [:main_content],
          audio_valid_candidate?: true,
          audio_sort_key: 1,
          content: "Departures"
        },
        :header => %MockWidget{
          slot_names: [:header],
          audio_valid_candidate?: true,
          audio_sort_key: 0,
          content: "Header"
        }
      }

      get_config_fn = fn _screen_id -> config_no_audio end

      fetch_data_fn = fn _config_no_audio -> {:layout, selected_instances} end

      expected_data = []

      assert expected_data ==
               ScreenAudioData.by_screen_id(screen_id, get_config_fn, fetch_data_fn)
    end

    test "returns an error if not a BusShelter screen", %{
      config_eink: config_eink
    } do
      screen_id = "123"

      selected_instances = %{
        {0, :medium_left} => %MockWidget{
          slot_names: [:medium_left, :medium_right],
          audio_valid_candidate?: false,
          audio_sort_key: 2,
          content: "Alert"
        },
        :main_content => %MockWidget{
          slot_names: [:main_content],
          audio_valid_candidate?: true,
          audio_sort_key: 1,
          content: "Departures"
        },
        :header => %MockWidget{
          slot_names: [:header],
          audio_valid_candidate?: true,
          audio_sort_key: 0,
          content: "Header"
        }
      }

      get_config_fn = fn _screen_id -> config_eink end

      fetch_data_fn = fn _config_eink -> {:layout, selected_instances} end

      expected_data = :error

      assert expected_data ==
               ScreenAudioData.by_screen_id(screen_id, get_config_fn, fetch_data_fn)
    end
  end
end
