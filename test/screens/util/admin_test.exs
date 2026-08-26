defmodule Screens.Util.AdminTest do
  use ExUnit.Case, async: true

  alias Screens.Config.ScreenConfig
  alias Screens.Util.Admin
  alias ScreensConfig.{AlertSchedule, EvergreenContentItem, RecurrentSchedule, Schedule, Screen}
  alias ScreensConfig.Screen.BusShelter

  defp build_item(schedule), do: struct(EvergreenContentItem, schedule: schedule)

  defp build_screen(evergreen_content) do
    struct(Screen, app_params: struct(BusShelter, evergreen_content: evergreen_content))
  end

  setup_all do
    before_date = ~D[2025-01-01]

    config_all_ended =
      build_item([
        %Schedule{start_dt: ~U[2024-10-01T00:00:00Z], end_dt: ~U[2024-10-03T00:00:00Z]},
        %Schedule{start_dt: ~U[2024-11-01T00:00:00Z], end_dt: ~U[2024-11-03T00:00:00Z]}
      ])

    config_some_ended =
      build_item([
        %Schedule{start_dt: ~U[2024-10-01T00:00:00Z], end_dt: ~U[2024-10-03T00:00:00Z]},
        %Schedule{start_dt: ~U[2025-02-01T00:00:00Z], end_dt: ~U[2025-02-03T00:00:00Z]}
      ])

    config_indefinite =
      build_item([
        %Schedule{start_dt: ~U[2024-10-01T00:00:00Z], end_dt: ~U[2024-10-03T00:00:00Z]},
        %Schedule{start_dt: ~U[2024-11-01T00:00:00Z], end_dt: nil}
      ])

    config_recurring_ended =
      build_item(%RecurrentSchedule{
        dates: [
          %{start_date: ~D[2024-10-01], end_date: ~D[2024-10-03]},
          %{start_date: ~D[2024-11-01], end_date: ~D[2024-11-03]}
        ]
      })

    config_recurring_some_ended =
      build_item(%RecurrentSchedule{
        dates: [
          %{start_date: ~D[2024-10-01], end_date: ~D[2024-10-03]},
          %{start_date: ~D[2024-11-01], end_date: nil}
        ]
      })

    config_alert_linked = build_item(%AlertSchedule{alert_ids: ["1"]})

    screen_before_cleanup =
      build_screen([
        config_all_ended,
        config_some_ended,
        config_indefinite,
        config_recurring_ended,
        config_recurring_some_ended,
        config_alert_linked
      ])

    screen_after_cleanup =
      build_screen([
        config_some_ended,
        config_indefinite,
        config_recurring_some_ended,
        config_alert_linked
      ])

    varied_configs = [
      %ScreenConfig{id: "composite", config: screen_before_cleanup},
      %ScreenConfig{id: "recurring-ended", config: build_screen([config_recurring_ended])},
      %ScreenConfig{id: "indefinite-only", config: build_screen([config_indefinite])},
      %ScreenConfig{id: "alert-only", config: build_screen([config_alert_linked])}
    ]

    varied_expected_updates = [
      %{id: "composite", config: screen_after_cleanup},
      %{id: "recurring-ended", config: build_screen([])}
    ]

    {:ok,
     before_date: before_date,
     screen_after_cleanup: screen_after_cleanup,
     screen_before_cleanup: screen_before_cleanup,
     varied_configs: varied_configs,
     varied_expected_updates: varied_expected_updates}
  end

  describe "cleanup_evergreen_content/2" do
    test "removes evergreen content items where all schedules end before the given date", %{
      before_date: before_date,
      screen_after_cleanup: screen_after_cleanup,
      screen_before_cleanup: screen_before_cleanup
    } do
      cleaned_screen = Admin.cleanup_evergreen_content(screen_before_cleanup, before_date)

      assert cleaned_screen == screen_after_cleanup
    end
  end

  describe "expired_evergreen_content_count/2" do
    test "counts only configs changed by evergreen cleanup", %{
      varied_configs: varied_configs,
      before_date: before_date
    } do
      assert Admin.expired_evergreen_content_count(varied_configs, before_date) == 2
    end
  end

  describe "evergreen_content_cleanup_updates/2" do
    test "returns updates only for configs changed by cleanup across varied schedule types", %{
      varied_configs: varied_configs,
      varied_expected_updates: varied_expected_updates,
      before_date: before_date
    } do
      result =
        Admin.evergreen_content_cleanup_updates(varied_configs, before_date)
        |> Enum.sort_by(& &1.id)

      expected = Enum.sort_by(varied_expected_updates, & &1.id)

      assert result == expected
    end
  end
end
