defmodule Screens.V2.ScreenAudioDataTest do
  use ExUnit.Case, async: true

  alias Screens.V2.ScreenAudioData
  alias Screens.V2.WidgetInstance.MockWidget

  describe "by_screen_id/3" do
    test "returns a list of {audio_view, view_assigns_map} tuples" do
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

      get_config_fn = fn "123" -> :config end

      fetch_data_fn = fn "123", :config -> {:layout, selected_instances} end

      audio_view = ScreensWeb.V2.Audio.MockWidgetView

      expected_data = [{audio_view, %{content: "Header"}}, {audio_view, %{content: "Departures"}}]

      assert expected_data ==
               ScreenAudioData.by_screen_id(screen_id, get_config_fn, fetch_data_fn)
    end
  end
end
