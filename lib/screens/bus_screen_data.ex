defmodule Screens.BusScreenData do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Cache
  alias Screens.Departures.Departure
  alias Screens.LogScreenData
  alias Screens.NearbyConnections
  alias Screens.Schedules.Schedule
  alias Screens.Util
  alias ScreensConfig.Bus

  def by_screen_id(screen_id, is_screen, now \\ DateTime.utc_now()) do
    if Cache.mode_disabled?(:bus) do
      %{
        force_reload: false,
        success: false
      }
    else
      by_enabled_screen_id(screen_id, is_screen, now)
    end
  end

  defp by_enabled_screen_id(screen_id, is_screen, now) do
    %Bus{stop_id: stop_id} = Cache.app_params(screen_id)

    # If we are unable to fetch alerts:
    # - inline_alerts will be an empty list
    # - global_alert will be nil
    #
    # We do this because we still want to return an API response with departures,
    # even if the other API requests fail.
    {inline_alerts, global_alert} = Alert.by_stop_id(stop_id)

    # If we are unable to fetch departures, we want to show an error message on the screen.
    departures =
      case Departure.fetch(%{stop_ids: [stop_id]}) do
        {:ok, result} ->
          result =
            Enum.sort_by(
              result,
              &Util.parse_time_string(&1.time),
              DateTime
            )

          {:ok, Departure.associate_alerts_with_departures(result, inline_alerts)}

        :error ->
          :error
      end

    nearby_connections_data = NearbyConnections.by_screen_id(screen_id)

    nearby_connections =
      case nearby_connections_data do
        {:ok, {_, nearby_connections}} -> nearby_connections
        _ -> []
      end

    stop_name = extract_stop_name(nearby_connections_data, departures)

    service_level = Cache.service_level(screen_id)

    _ = LogScreenData.log_departures(screen_id, is_screen, departures)

    {psa_type, psa_url} = Screens.Psa.current_psa_for(screen_id)

    in_service_day? = in_service_day_at_stop?(stop_id, now)

    case departures do
      {:ok, departures} ->
        %{
          force_reload: false,
          success: true,
          current_time: Screens.Util.format_time(now),
          stop_name: stop_name,
          stop_id: stop_id,
          departures: format_departure_rows(departures),
          global_alert: format_global_alert(global_alert),
          nearby_connections: nearby_connections,
          service_level: service_level,
          psa_type: psa_type,
          psa_url: psa_url,
          in_service_day: in_service_day?
        }

      :error ->
        %{
          force_reload: false,
          success: false
        }
    end
  end

  defp in_service_day_at_stop?(stop_id, current_time) do
    with {:ok, schedules} <- Schedule.fetch(%{stop_ids: [stop_id]}),
         {first_arrival_time, last_arrival_time} <- get_service_day_from_schedules(schedules) do
      DateTime.compare(first_arrival_time, current_time) in [:lt, :eq] and
        DateTime.compare(last_arrival_time, current_time) == :gt
    else
      _ -> true
    end
  end

  defp get_service_day_from_schedules(schedules) do
    schedules
    |> Enum.map(& &1.departure_time)
    |> case do
      [] ->
        nil

      departure_times ->
        {Enum.min(departure_times, DateTime), Enum.max(departure_times, DateTime)}
    end
  end

  defp extract_stop_name({:ok, {%{stop_name: stop_name}, _}}, _) do
    stop_name
  end

  defp extract_stop_name(_, {:ok, [departure | _]}) do
    departure.stop_name
  end

  defp extract_stop_name(_, _) do
    nil
  end

  defp format_departure_rows(departures) do
    Enum.map(departures, &Map.from_struct/1)
  end

  def format_global_alert(alert) do
    Alert.to_map(alert)
  end
end
