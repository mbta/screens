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

  defp should_cleanup_evergreen_item?(%EvergreenContentItem{schedule: schedules}, before_date)
       when is_list(schedules) do
    Enum.all?(schedules, fn
      %Schedule{end_dt: nil} -> false
      %Schedule{end_dt: datetime} -> Date.compare(datetime, before_date) == :lt
    end)
  end

  defp should_cleanup_evergreen_item?(
         %EvergreenContentItem{schedule: %RecurrentSchedule{dates: date_ranges}},
         before_date
       ) do
    Enum.all?(date_ranges, fn
      %{end_date: nil} -> false
      %{end_date: end_date} -> Date.compare(end_date, before_date) == :lt
    end)
  end

  # Cleaning up alert-linked content is not supported
  defp should_cleanup_evergreen_item?(%EvergreenContentItem{schedule: _other}, _before_date),
    do: false
end
