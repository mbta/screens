defmodule Screens.Util.AdminTest do
  use ExUnit.Case, async: true

  import Mox

  alias Screens.Alerts.Alert
  alias Screens.Config.ScreenConfig
  alias Screens.Util.Admin
  alias ScreensConfig.{AlertSchedule, EvergreenContentItem, RecurrentSchedule, Schedule, Screen}
  alias ScreensConfig.Screen.BusShelter

  defp build_evergreen_item(schedule), do: struct(EvergreenContentItem, schedule: schedule)

  defp build_screen_with_evergreen(evergreen_content) do
    struct(Screen, app_params: struct(BusShelter, evergreen_content: evergreen_content))
  end

  setup_all do
    before_date = ~D[2025-01-01]

    evergreen_config_all_ended =
      build_evergreen_item([
        %Schedule{start_dt: ~U[2024-10-01T00:00:00Z], end_dt: ~U[2024-10-03T00:00:00Z]},
        %Schedule{start_dt: ~U[2024-11-01T00:00:00Z], end_dt: ~U[2024-11-03T00:00:00Z]}
      ])

    evergreen_config_some_ended =
      build_evergreen_item([
        %Schedule{start_dt: ~U[2024-10-01T00:00:00Z], end_dt: ~U[2024-10-03T00:00:00Z]},
        %Schedule{start_dt: ~U[2025-02-01T00:00:00Z], end_dt: ~U[2025-02-03T00:00:00Z]}
      ])

    evergreen_config_indefinite =
      build_evergreen_item([
        %Schedule{start_dt: ~U[2024-10-01T00:00:00Z], end_dt: ~U[2024-10-03T00:00:00Z]},
        %Schedule{start_dt: ~U[2024-11-01T00:00:00Z], end_dt: nil}
      ])

    evergreen_config_recurring_ended =
      build_evergreen_item(%RecurrentSchedule{
        dates: [
          %{start_date: ~D[2024-10-01], end_date: ~D[2024-10-03]},
          %{start_date: ~D[2024-11-01], end_date: ~D[2024-11-03]}
        ]
      })

    evergreen_config_recurring_some_ended =
      build_evergreen_item(%RecurrentSchedule{
        dates: [
          %{start_date: ~D[2024-10-01], end_date: ~D[2024-10-03]},
          %{start_date: ~D[2024-11-01], end_date: nil}
        ]
      })

    evergreen_config_alert_linked = build_evergreen_item(%AlertSchedule{alert_ids: ["1"]})

    evergreen_screen_before_cleanup =
      build_screen_with_evergreen([
        evergreen_config_all_ended,
        evergreen_config_some_ended,
        evergreen_config_indefinite,
        evergreen_config_recurring_ended,
        evergreen_config_recurring_some_ended,
        evergreen_config_alert_linked
      ])

    evergreen_screen_after_cleanup =
      build_screen_with_evergreen([
        evergreen_config_some_ended,
        evergreen_config_indefinite,
        evergreen_config_recurring_some_ended,
        evergreen_config_alert_linked
      ])

    evergreen_varied_configs = [
      %ScreenConfig{id: "composite", config: evergreen_screen_before_cleanup},
      %ScreenConfig{
        id: "recurring-ended",
        config: build_screen_with_evergreen([evergreen_config_recurring_ended])
      },
      %ScreenConfig{
        id: "indefinite-only",
        config: build_screen_with_evergreen([evergreen_config_indefinite])
      },
      %ScreenConfig{
        id: "alert-only",
        config: build_screen_with_evergreen([evergreen_config_alert_linked])
      }
    ]

    evergreen_varied_expected_updates = [
      %{id: "composite", config: evergreen_screen_after_cleanup},
      %{id: "recurring-ended", config: build_screen_with_evergreen([])}
    ]

    {:ok,
     before_date: before_date,
     evergreen_screen_after_cleanup: evergreen_screen_after_cleanup,
     evergreen_screen_before_cleanup: evergreen_screen_before_cleanup,
     evergreen_varied_configs: evergreen_varied_configs,
     evergreen_varied_expected_updates: evergreen_varied_expected_updates}
  end

  describe "cleanup_evergreen_content/2" do
    test "removes evergreen content items where all schedules end before the given date", %{
      before_date: before_date,
      evergreen_screen_after_cleanup: evergreen_screen_after_cleanup,
      evergreen_screen_before_cleanup: evergreen_screen_before_cleanup
    } do
      cleaned_screen =
        Admin.cleanup_evergreen_content(evergreen_screen_before_cleanup, before_date)

      assert cleaned_screen == evergreen_screen_after_cleanup
    end
  end

  describe "expired_evergreen_content_count/2" do
    test "counts only configs changed by evergreen cleanup", %{
      evergreen_varied_configs: evergreen_varied_configs,
      before_date: before_date
    } do
      assert Admin.expired_evergreen_content_count(evergreen_varied_configs, before_date) == 2
    end
  end

  describe "evergreen_content_cleanup_updates/2" do
    test "returns updates only for configs changed by cleanup across varied schedule types", %{
      evergreen_varied_configs: evergreen_varied_configs,
      evergreen_varied_expected_updates: evergreen_varied_expected_updates,
      before_date: before_date
    } do
      result =
        Admin.evergreen_content_cleanup_updates(evergreen_varied_configs, before_date)
        |> Enum.sort_by(& &1.id)

      expected = Enum.sort_by(evergreen_varied_expected_updates, & &1.id)

      assert result == expected
    end
  end

  describe "expired_alert_content_cleanup_updates/1" do
    setup :verify_on_exit!

    test "removes alert-linked content only when none of its alerts are present" do
      expired = build_item(%AlertSchedule{alert_ids: ["expired"]})
      partially_expired = build_item(%AlertSchedule{alert_ids: ["expired", "active"]})
      no_alerts = build_item(%AlertSchedule{alert_ids: []})
      scheduled = build_item([%Schedule{end_dt: ~U[2026-10-13T00:00:00Z]}])

      configs = [
        %ScreenConfig{id: "mixed", config: build_screen([expired, partially_expired, scheduled])},
        %ScreenConfig{id: "active", config: build_screen([partially_expired, no_alerts])},
        %ScreenConfig{id: "none", config: build_screen([scheduled])}
      ]

      expect(Alert.Mock, :fetch, fn _opts -> {:ok, [%Alert{id: "active"}]} end)

      assert Admin.expired_alert_content_cleanup_updates(configs) ==
               {:ok, [%{id: "mixed", config: build_screen([partially_expired, scheduled])}]}
    end

    test "does not fetch alerts when no content is alert-linked" do
      configs = [%ScreenConfig{id: "none", config: build_screen([])}]

      assert Admin.expired_alert_content_cleanup_updates(configs) == {:ok, []}
    end

    test "returns an error when alerts cannot be fetched" do
      configs = [
        %ScreenConfig{
          id: "alert",
          config: build_screen([build_item(%AlertSchedule{alert_ids: ["1"]})])
        }
      ]

      expect(Alert.Mock, :fetch, fn _opts -> :error end)

      assert Admin.expired_alert_content_cleanup_updates(configs) == :error
    end
  end
end
