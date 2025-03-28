defmodule Screens.V2.ScreenAudioDataTest do
  use ExUnit.Case, async: true

  alias Screens.V2.ScreenAudioData
  alias Screens.V2.WidgetInstance.MockWidget
  alias ScreensConfig, as: Config
  alias ScreensConfig.Screen

  setup do
    %{
      config_bus_shelter: %Screen{
        app_params: %Screen.BusShelter{
          audio: %Config.Audio{interval_enabled: true},
          departures: %Config.Departures{sections: []},
          footer: %Config.Footer{},
          header: %Config.Header.CurrentStopId{stop_id: "1"},
          alerts: %Config.Alerts{stop_id: "1"}
        },
        vendor: :lg_mri,
        device_id: "TEST",
        name: "TEST",
        app_id: :bus_shelter_v2
      },
      config_dup: %Screen{
        app_params: %Screen.Dup{
          primary_departures: %Config.Departures{sections: []},
          secondary_departures: %Config.Departures{sections: []},
          header: %Config.Header.CurrentStopId{stop_id: "1"},
          alerts: %Config.Alerts{stop_id: "1"}
        },
        vendor: :outfront,
        device_id: "TEST",
        name: "TEST",
        app_id: :dup_v2
      }
    }
  end

  describe "by_screen_id/3" do
    test "returns a list of {audio_view, view_assigns_map} tuples", %{
      config_bus_shelter: config_bus_shelter
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

      get_config_fn = fn _screen_id -> config_bus_shelter end
      generate_layout_fn = fn _config_valid_audio -> {:layout, selected_instances} end
      get_audio_only_instances_fn = fn _widgets, _config -> [] end
      audio_view = ScreensWeb.V2.Audio.MockWidgetView
      expected_data = [{audio_view, %{content: "Header"}}, {audio_view, %{content: "Departures"}}]

      assert expected_data ==
               ScreenAudioData.by_screen_id(
                 screen_id,
                 get_config_fn,
                 generate_layout_fn,
                 get_audio_only_instances_fn,
                 now
               )
    end

    test "returns empty list if screen type does not have audio enabled", %{
      config_dup: config_dup
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

      get_config_fn = fn _screen_id -> config_dup end
      generate_layout_fn = fn _config_eink -> {:layout, selected_instances} end
      get_audio_only_instances_fn = fn _widgets, _config -> [] end

      assert [] ==
               ScreenAudioData.by_screen_id(
                 screen_id,
                 get_config_fn,
                 generate_layout_fn,
                 get_audio_only_instances_fn,
                 now
               )
    end

    test "adds audio-only widgets to the readout data as defined by the audio_only_instances candidate generator function",
         %{config_bus_shelter: config_bus_shelter} do
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

      get_config_fn = fn _screen_id -> config_bus_shelter end
      generate_layout_fn = fn _config_valid_audio -> {:layout, selected_instances} end

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
                 generate_layout_fn,
                 get_audio_only_instances_fn,
                 now
               )
    end
  end
end
