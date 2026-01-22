defmodule Screens.V2.CandidateGenerator.Widgets.EvergreenTest do
  use ExUnit.Case, async: true

  alias Screens.V2.CandidateGenerator.Widgets.Evergreen, as: Generator
  alias Screens.V2.WidgetInstance.EvergreenContent
  alias ScreensConfig.{AlertSchedule, EvergreenContentItem, Screen}

  import Mox
  setup :verify_on_exit!

  import Screens.Inject
  @alert injected(Screens.Alerts.Alert)

  @now ~U[2025-01-01 12:00:00Z]

  defp build_screen(content),
    do: struct(Screen, app_params: struct(Screen.PreFare, %{evergreen_content: content}))

  describe "evergreen_content_instances/2" do
    test "translates configured items into widgets and fetches relevant alerts" do
      screen =
        build_screen([
          %EvergreenContentItem{
            slot_names: ~w[screen],
            asset_path: "asset.png",
            priority: [0],
            schedule: %AlertSchedule{alert_ids: ~w[1 2]},
            text_for_audio: "audio description",
            audio_priority: [0]
          }
        ])

      expect(@alert, :fetch, fn [ids: ~w[1 2]] -> {:ok, ["fake alert 1", "fake alert 2"]} end)

      assert Generator.evergreen_content_instances(screen, @now) ==
               [
                 %EvergreenContent{
                   screen: screen,
                   slot_names: ~w[screen]a,
                   alerts: ["fake alert 1", "fake alert 2"],
                   asset_url: "https://mbta-screens.s3.amazonaws.com/screens-dev/asset.png",
                   priority: [0],
                   schedule: %AlertSchedule{alert_ids: ~w[1 2]},
                   now: @now,
                   text_for_audio: "audio description",
                   audio_priority: [0]
                 }
               ]
    end

    test "tolerates API failure when fetching alerts" do
      screen =
        build_screen([
          %EvergreenContentItem{
            slot_names: ~w[screen],
            asset_path: "asset.png",
            priority: [0],
            schedule: %AlertSchedule{alert_ids: ~w[1]},
            text_for_audio: "audio description",
            audio_priority: [0]
          }
        ])

      expect(@alert, :fetch, fn [ids: ~w[1]] -> :error end)

      assert [%EvergreenContent{alerts: []}] = Generator.evergreen_content_instances(screen, @now)
    end
  end
end
