defmodule Screens.V2.CandidateGenerator.Widgets.EmergencyTakeoverTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.Widgets.EmergencyTakeover, as: Generator
  alias Screens.V2.WidgetInstance.EvergreenContent
  alias ScreensConfig.EmergencyTakeover
  alias ScreensConfig.Screen

  @now ~U[2025-01-01 12:00:00Z]
  @default_emergency_takeover %EmergencyTakeover{
    visual_asset_path: "visual_asset_path",
    audio_asset_path: "audio_asset_path",
    text_for_audio: "audio_text"
  }

  defp build_screen(screen, emergency_takeover \\ @default_emergency_takeover),
    do: struct(Screen, app_params: struct(screen, %{emergency_takeover: emergency_takeover}))

  describe "emergency_takeover_instance/2" do
    test "returns empty array when emergency_takeover is nil" do
      screen = build_screen(Screen.PreFare, nil)

      assert Generator.emergency_takeover_instances(screen, @now) == []
    end

    test "returns emergency takeover with PreFare Duo full screen slots" do
      screen = build_screen(Screen.PreFare)

      assert Generator.emergency_takeover_instances(screen, @now) == [
               %EvergreenContent{
                 screen: screen,
                 slot_names: [:full_left_screen],
                 asset_url: "visual_asset_path",
                 text_for_audio: "audio_text",
                 priority: [0],
                 audio_priority: [0],
                 now: @now
               },
               %EvergreenContent{
                 screen: screen,
                 slot_names: [:full_right_screen],
                 asset_url: "visual_asset_path",
                 text_for_audio: "audio_text",
                 priority: [0],
                 audio_priority: [0],
                 now: @now
               }
             ]
    end

    test "returns emergency takeover with PreFare Solo full screen slots" do
      screen =
        struct(Screen,
          app_params:
            struct(Screen.PreFare, %{
              template: :solo,
              emergency_takeover: @default_emergency_takeover
            })
        )

      assert Generator.emergency_takeover_instances(screen, @now) == [
               %EvergreenContent{
                 screen: screen,
                 slot_names: [:full_right_screen],
                 asset_url: "visual_asset_path",
                 text_for_audio: "audio_text",
                 priority: [0],
                 audio_priority: [0],
                 now: @now
               }
             ]
    end

    test "returns emergency takeover with Dup full screen slots" do
      screen = build_screen(Screen.Dup)

      assert Generator.emergency_takeover_instances(screen, @now) == [
               %EvergreenContent{
                 screen: screen,
                 slot_names: [:full_rotation_zero],
                 asset_url: "visual_asset_path",
                 text_for_audio: "audio_text",
                 priority: [0],
                 audio_priority: [0],
                 now: @now
               },
               %EvergreenContent{
                 screen: screen,
                 slot_names: [:full_rotation_one],
                 asset_url: "visual_asset_path",
                 text_for_audio: "audio_text",
                 priority: [0],
                 audio_priority: [0],
                 now: @now
               },
               %EvergreenContent{
                 screen: screen,
                 slot_names: [:full_rotation_two],
                 asset_url: "visual_asset_path",
                 text_for_audio: "audio_text",
                 priority: [0],
                 audio_priority: [0],
                 now: @now
               }
             ]
    end

    test "returns emergency takeover with Busway full screen slots" do
      screen = build_screen(Screen.Busway)

      assert Generator.emergency_takeover_instances(screen, @now) == [
               %EvergreenContent{
                 screen: screen,
                 slot_names: [:full_screen],
                 asset_url: "visual_asset_path",
                 text_for_audio: "audio_text",
                 priority: [0],
                 audio_priority: [0],
                 now: @now
               }
             ]
    end
  end
end
