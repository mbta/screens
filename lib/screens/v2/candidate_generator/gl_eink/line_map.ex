defmodule Screens.V2.CandidateGenerator.GlEink.LineMap do
  @moduledoc "Generates the LineMap widget for GL E-ink screens."

  alias Screens.RoutePatterns.RoutePattern
  alias Screens.V2.WidgetInstance.LineMap
  alias ScreensConfig.Screen

  import Screens.Inject
  @departure injected(Screens.V2.Departure)
  @route_pattern injected(RoutePattern)

  @scheduled_terminal_departure_lookback_seconds 180

  def instances(
        %Screen{
          app_params: %Screen.GlEink{
            line_map: %ScreensConfig.LineMap{
              station_id: station_id,
              direction_id: direction_id,
              route_id: route_id
            }
          }
        } = screen,
        now
      ) do
    with {:ok, stops, reverse_stops} <- fetch_stops(route_id, direction_id),
         {:ok, departures} <- fetch_departures(station_id, now) do
      [
        %LineMap{
          screen: screen,
          stops: stops,
          reverse_stops: reverse_stops,
          departures: departures
        }
      ]
    else
      _ -> []
    end
  end

  defp fetch_departures(station_id, now) do
    @departure.fetch(
      %{stop_ids: [station_id]},
      include_schedules: true,
      now: DateTime.add(now, -@scheduled_terminal_departure_lookback_seconds)
    )
  end

  defp fetch_stops(route_id, direction_id) do
    case @route_pattern.fetch(%{canonical?: true, route_ids: [route_id]}) do
      {:ok, patterns} ->
        reverse_direction_id = 1 - direction_id

        # Assume exactly two canonical patterns per route, one for each direction (expected for
        # Green Line routes, but not universal)
        %{
          ^direction_id => [%RoutePattern{stops: stops}],
          ^reverse_direction_id => [%RoutePattern{stops: reverse_stops}]
        } = Enum.group_by(patterns, & &1.direction_id)

        {:ok, stops, reverse_stops}

      :error ->
        :error
    end
  end
end
