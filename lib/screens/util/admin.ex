defmodule Screens.Util.Admin do
  @moduledoc "Common functions used for administrative tasks."

  alias ScreensConfig.{EvergreenContentItem, RecurrentSchedule, Schedule, Screen}

  def cleanup_evergreen_content(
        %Screen{app_params: %_app{evergreen_content: _}} = screen,
        before_date
      ) do
    update_in(screen.app_params.evergreen_content, fn items ->
      Enum.reject(items, &should_cleanup_evergreen_item?(&1, before_date))
    end)
  end

  def cleanup_evergreen_content(screen, _before_date), do: screen

  defp should_cleanup_evergreen_item?(
         %EvergreenContentItem{schedule: schedule_items},
         before_date
       ) do
    Enum.all?(schedule_items, fn
      %Schedule{end_dt: nil} ->
        false

      %Schedule{end_dt: datetime} ->
        Date.compare(datetime, before_date) == :lt

      %RecurrentSchedule{dates: date_ranges} ->
        Enum.all?(date_ranges, fn
          %{end_date: nil} -> false
          %{end_date: end_date} -> Date.compare(end_date, before_date) == :lt
        end)
    end)
  end
end
