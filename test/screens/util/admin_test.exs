defmodule Screens.Util.AdminTest do
  use ExUnit.Case, async: true

  alias Screens.Util.Admin
  alias ScreensConfig.{AlertSchedule, EvergreenContentItem, RecurrentSchedule, Schedule, Screen}
  alias ScreensConfig.Screen.BusShelter

  describe "cleanup_evergreen_content/2" do
    defp build_item(schedule), do: struct(EvergreenContentItem, schedule: schedule)

    defp build_screen(evergreen_content) do
      struct(Screen, app_params: struct(BusShelter, evergreen_content: evergreen_content))
    end

    test "removes evergreen content items where all schedules end before the given date" do
      all_ended =
        build_item([
          %Schedule{start_dt: ~U[2024-10-01T00:00:00Z], end_dt: ~U[2024-10-03T00:00:00Z]},
          %Schedule{start_dt: ~U[2024-11-01T00:00:00Z], end_dt: ~U[2024-11-03T00:00:00Z]}
        ])

      some_ended =
        build_item([
          %Schedule{start_dt: ~U[2024-10-01T00:00:00Z], end_dt: ~U[2024-10-03T00:00:00Z]},
          %Schedule{start_dt: ~U[2025-02-01T00:00:00Z], end_dt: ~U[2025-02-03T00:00:00Z]}
        ])

      indefinite =
        build_item([
          %Schedule{start_dt: ~U[2024-10-01T00:00:00Z], end_dt: ~U[2024-10-03T00:00:00Z]},
          %Schedule{start_dt: ~U[2024-11-01T00:00:00Z], end_dt: nil}
        ])

      recurring_all_ended =
        build_item(%RecurrentSchedule{
          dates: [
            %{start_date: ~D[2024-10-01], end_date: ~D[2024-10-03]},
            %{start_date: ~D[2024-11-01], end_date: ~D[2024-11-03]}
          ]
        })

      recurring_some_ended =
        build_item(%RecurrentSchedule{
          dates: [
            %{start_date: ~D[2024-10-01], end_date: ~D[2024-10-03]},
            %{start_date: ~D[2024-11-01], end_date: nil}
          ]
        })

      alert_linked = build_item(%AlertSchedule{alert_ids: ["1"]})

      screen =
        build_screen([
          all_ended,
          some_ended,
          indefinite,
          recurring_all_ended,
          recurring_some_ended,
          alert_linked
        ])

      cleaned_screen = Admin.cleanup_evergreen_content(screen, ~D[2025-01-01])

      assert cleaned_screen.app_params.evergreen_content ==
               [some_ended, indefinite, recurring_some_ended, alert_linked]
    end
  end
end
