defmodule Screens.Util.Admin do
  @moduledoc "Common functions used for administrative tasks."

  import Screens.Inject

  alias Screens.Alerts.Alert
  alias Screens.Config.ScreenConfig
  alias ScreensConfig.{AlertSchedule, EvergreenContentItem, RecurrentSchedule, Schedule, Screen}
  alias ScreensConfig.Departures
  alias ScreensConfig.Departures.Header
  alias ScreensConfig.Departures.Header.WayfindingInformation
  alias ScreensConfig.Departures.Section

  @alert injected(Screens.Alerts.Alert)

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

  @doc """
  Counts screen configs that contain expired wayfinding content, i.e. those where
  all non-empty schedule `end_dt` values are before `before_date`.
  """
  @spec expired_wayfinding_content_count([ScreenConfig.t()], Date.t()) :: non_neg_integer()
  def expired_wayfinding_content_count(screen_configs, before_date) do
    screen_configs
    |> wayfinding_content_cleanup_updates(before_date)
    |> Enum.count()
  end

  @doc "Returns a list of updates for Postgres that will clean up expired wayfinding content."
  @spec wayfinding_content_cleanup_updates([ScreenConfig.t()], Date.t()) :: [map()]
  def wayfinding_content_cleanup_updates(screen_configs, before_date) do
    Enum.reduce(screen_configs, [], fn %{id: id, config: screen}, acc ->
      cleaned = cleanup_wayfinding_content(screen, before_date)

      if cleaned == screen do
        acc
      else
        [%{id: id, config: cleaned} | acc]
      end
    end)
  end

  @spec cleanup_wayfinding_content(Screen.t(), Date.t()) :: Screen.t()
  def cleanup_wayfinding_content(
        %Screen{app_params: %_app{departures: %Departures{sections: _sections}}} = screen,
        before_date
      ) do
    update_in(screen.app_params.departures.sections, fn sections ->
      Enum.map(sections, fn
        %Section{header: %Header{wayfinding_information: wayfinding_information}} = section ->
          if should_cleanup_wayfinding_item?(wayfinding_information, before_date) do
            %{section | header: %Header{wayfinding_information: nil}}
          else
            section
          end
      end)
    end)
  end

  def cleanup_wayfinding_content(screen, _before_date), do: screen

  @spec should_cleanup_wayfinding_item?(WayfindingInformation.t() | nil, Date.t()) :: boolean()
  defp should_cleanup_wayfinding_item?(nil, _before_date), do: false

  defp should_cleanup_wayfinding_item?(wayfinding_information, before_date) do
    Enum.all?(wayfinding_information.schedule, fn
      %Schedule{end_dt: nil} -> false
      %Schedule{end_dt: datetime} -> Date.compare(datetime, before_date) == :lt
    end)
  end

  @doc """
  Returns a list of updates for Postgres that will remove alert-linked evergreen content where
  none of the linked alerts are present in the alerts feed (i.e. they have expired).
  """
  @spec expired_alert_content_cleanup_updates([ScreenConfig.t()]) :: {:ok, [map()]} | :error
  def expired_alert_content_cleanup_updates(screen_configs) do
    alert_ids = screen_configs |> Enum.flat_map(&linked_alert_ids/1) |> Enum.uniq()

    with {:ok, present_ids} <- fetch_present_alert_ids(alert_ids) do
      {:ok,
       Enum.flat_map(screen_configs, fn %ScreenConfig{id: id, config: screen} ->
         cleaned = cleanup_expired_alert_content(screen, present_ids)
         if cleaned == screen, do: [], else: [%{id: id, config: cleaned}]
       end)}
    end
  end

  @spec linked_alert_ids(ScreenConfig.t()) :: [Alert.id()]
  defp linked_alert_ids(%ScreenConfig{
         config: %Screen{app_params: %_app{evergreen_content: items}}
       }) do
    Enum.flat_map(items, fn
      %EvergreenContentItem{schedule: %AlertSchedule{alert_ids: ids}} -> ids
      _ -> []
    end)
  end

  defp linked_alert_ids(_screen_config), do: []

  @spec fetch_present_alert_ids([Alert.id()]) :: {:ok, [Alert.id()]} | :error
  defp fetch_present_alert_ids([]), do: {:ok, []}

  defp fetch_present_alert_ids(alert_ids) do
    with {:ok, alerts} <- @alert.fetch(ids: alert_ids, activities: :all) do
      {:ok, Enum.map(alerts, & &1.id)}
    end
  end

  @spec cleanup_expired_alert_content(Screen.t(), [Alert.id()]) :: Screen.t()
  defp cleanup_expired_alert_content(
         %Screen{app_params: %_app{evergreen_content: _}} = screen,
         present_ids
       ) do
    update_in(screen.app_params.evergreen_content, fn items ->
      Enum.reject(items, &alert_content_expired?(&1, present_ids))
    end)
  end

  defp cleanup_expired_alert_content(screen, _present_ids), do: screen

  @spec alert_content_expired?(EvergreenContentItem.t(), [Alert.id()]) :: boolean()
  defp alert_content_expired?(
         %EvergreenContentItem{schedule: %AlertSchedule{alert_ids: [_ | _] = alert_ids}},
         present_ids
       ),
       do: not Enum.any?(alert_ids, &Enum.member?(present_ids, &1))

  defp alert_content_expired?(_item, _present_ids), do: false
end
