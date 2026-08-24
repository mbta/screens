defmodule Screens.Util.Admin do
  @moduledoc "Common functions used for administrative tasks."

  alias Screens.Config.ScreenConfig
  alias ScreensConfig.{EvergreenContentItem, RecurrentSchedule, Schedule, Screen}

  @doc """
  Counts screen configs that contain expired evergreen content, i.e. those where
  all non-empty schedule `end_dt` values are before `before_date`.
  """
  @spec expired_evergreen_content_count([ScreenConfig.t()], Date.t()) :: non_neg_integer()
  def expired_evergreen_content_count(screen_configs, before_date) do
    screen_configs
    |> evergreen_content_cleanup_updates(before_date)
    |> Enum.count()
  end

  @doc "Returns a list of updates for Postgres that will clean up expired evergreen content."
  @spec evergreen_content_cleanup_updates([ScreenConfig.t()], Date.t()) :: [map()]
  def evergreen_content_cleanup_updates(screen_configs, before_date) do
    Enum.reduce(screen_configs, [], fn %{id: id, config: screen}, acc ->
      cleaned = cleanup_evergreen_content(screen, before_date)

      if cleaned == screen do
        acc
      else
        [%{id: id, config: cleaned} | acc]
      end
    end)
  end

  @spec cleanup_evergreen_content(Screen.t(), Date.t()) :: Screen.t()

  def cleanup_evergreen_content(
        %Screen{app_params: %_app{evergreen_content: _}} = screen,
        before_date
      ) do
    update_in(screen.app_params.evergreen_content, fn items ->
      Enum.reject(items, &should_cleanup_evergreen_item?(&1, before_date))
    end)
  end

  def cleanup_evergreen_content(screen, _before_date), do: screen

  @spec should_cleanup_evergreen_item?(EvergreenContentItem.t(), Date.t()) :: boolean()
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
