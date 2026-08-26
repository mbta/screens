defmodule Screens.V2.ScreenDataTest do
  use ExUnit.Case, async: true

  alias Screens.TestSupport.CandidateGeneratorStub, as: Stub
  alias Screens.TestSupport.ScreenDataCache
  alias Screens.V2.ScreenData
  alias Screens.V2.WidgetInstance.{MockWidget, Placeholder}
  alias ScreensConfig.Screen

  import Screens.Inject
  import Mox
  setup :verify_on_exit!
  setup {ScreenDataCache, :passthrough}

  @parameters injected(Screens.V2.ScreenData.Parameters)

  require Stub

  Stub.candidate_generator(GrayGenerator, fn _ -> [placeholder(:gray)] end)

  Stub.candidate_generator(CrashGenerator, fn %Screen{app_params: %{test_pid: pid}} ->
    send(pid, {:crash_running, self()})
    raise "oopsie"
  end)

  defp build_screen(attrs \\ []) do
    struct!(
      %Screen{app_id: :test_app, app_params: %{}, device_id: "", name: "", vendor: ""},
      attrs
    )
  end

  describe "get/2" do
    setup do
      stub(@parameters, :refresh_rate, fn _app_id -> 0 end)
      :ok
    end

    test "gets widget data for a screen" do
      screen = build_screen(%{app_id: :test_app})

      stub(@parameters, :candidate_generator, fn %Screen{app_id: :test_app} -> GrayGenerator end)

      assert ScreenData.get("test", screen) ==
               %{type: :normal, main: %{type: :placeholder, color: :gray, text: ""}}
    end
  end

  describe "audio/2" do
    @layout %{
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
      },
      :footer => %MockWidget{
        slot_names: [:footer],
        audio_valid_candidate?: false,
        audio_sort_key: [],
        content: "Footer"
      }
    }

    @view ScreensWeb.V2.Audio.MockWidgetView

    test "returns a list of {audio_view, view_assigns_map} tuples" do
      audio_only_instances_fn = fn widgets, _screen ->
        # All selected instances should be passed to `audio_only_instances` in the snapshot, even
        # those without audio equivalence
        assert Enum.sort(widgets) == @layout |> Map.values() |> Enum.sort()
        []
      end

      expected_data = [
        {@view, %{content: "Header"}},
        {@view, %{content: "Departures"}},
        {@view, %{content: "Alert"}}
      ]

      assert expected_data ==
               ScreenData.audio("test", build_screen(),
                 generate_fn: fn _id, _screen -> {:layout, @layout} end,
                 audio_only_instances_fn: audio_only_instances_fn
               )
    end

    test "adds audio-only widgets as defined by the audio_only_instances candidate generator function" do
      audio_only_instances_fn = fn _widgets, _screen ->
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

      expected_data = [
        {@view, %{content: "Header"}},
        {@view, %{content: "Content Summary"}},
        {@view, %{content: "Departures"}},
        {@view, %{content: "Alerts Summary"}},
        {@view, %{content: "Alert"}}
      ]

      assert expected_data ==
               ScreenData.audio("test", build_screen(),
                 generate_fn: fn _id, _screen -> {:layout, @layout} end,
                 audio_only_instances_fn: audio_only_instances_fn
               )
    end
  end

  describe "serialize/1" do
    test "serializes a hierarchical layout" do
      layout =
        {:screen,
         {:normal,
          [
            :main_content,
            {:flex_zone, {:two_medium, [:medium_left, :medium_right]}},
            :footer
          ]}}

      selected_widgets = %{
        main_content: %MockWidget{
          slot_names: [:main_content],
          widget_type: :departures,
          content: []
        },
        medium_left: %MockWidget{
          slot_names: [:medium_left, :medium_right],
          widget_type: :static_image,
          content: "face_covering.png"
        },
        medium_right: %MockWidget{
          slot_names: [:medium_left, :medium_right],
          widget_type: :static_image,
          content: "autopay.png"
        },
        footer: %MockWidget{
          slot_names: [:footer],
          widget_type: :normal_footer,
          content: "fare info"
        }
      }

      paging_metadata = %{flex_zone: {1, 3}, footer: {0, 2}}

      expected = %{
        type: :normal,
        main_content: %{type: :departures, content: []},
        flex_zone: %{
          type: :two_medium,
          page_index: 1,
          num_pages: 3,
          medium_left: %{type: :static_image, content: "face_covering.png"},
          medium_right: %{type: :static_image, content: "autopay.png"}
        },
        footer: %{type: :normal_footer, page_index: 0, num_pages: 2, content: "fare info"}
      }

      assert expected == ScreenData.serialize({layout, selected_widgets, paging_metadata})
    end
  end
end
