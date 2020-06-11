defmodule Screens.LineMap do
  @moduledoc false

  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Vehicles.Vehicle

  def by_stop_id(stop_id, route_id, direction_id, predictions) do
    vehicles = Vehicle.by_route_and_direction(route_id, direction_id)
    route_stops = RoutePattern.stops_by_route_and_direction(route_id, direction_id)

    current_stop_index =
      Enum.find_index(route_stops, fn %{id: route_stop_id} -> route_stop_id == stop_id end)

    %{id: origin_stop_id} = Enum.at(route_stops, 0)
    schedule = next_scheduled_departure(origin_stop_id, route_id, predictions)

    {
      %{
        stops: format_stops(route_stops, current_stop_index),
        vehicles: format_vehicles(vehicles, route_stops, current_stop_index, predictions),
        schedule: format_schedule(schedule)
      },
      {:ok,
       filter_predictions_by_vehicles(predictions, vehicles, route_stops, current_stop_index)}
    }
  end

  def filter_predictions_by_vehicles(predictions, vehicles, route_stops, current_stop_index) do
    departed_vehicle_trip_ids =
      vehicles
      |> Enum.filter(fn v ->
        index = find_vehicle_index(v, route_stops)
        not is_nil(index) and index > current_stop_index
      end)
      |> Enum.map(fn %{trip_id: trip_id} -> trip_id end)
      |> Enum.reject(&is_nil/1)

    Enum.reject(predictions, fn p ->
      case p do
        %{trip: %{id: trip_id}} -> trip_id in departed_vehicle_trip_ids
        _ -> false
      end
    end)
  end

  defp find_vehicle_index(%{stop_id: vehicle_stop_id}, route_stops) do
    Enum.find_index(route_stops, fn %{id: route_stop_id} -> route_stop_id == vehicle_stop_id end)
  end

  defp next_scheduled_departure(origin_stop_id, route_id, predictions) do
    time = DateTime.add(DateTime.utc_now(), -180)

    case Screens.Schedules.Schedule.fetch(%{stop_id: origin_stop_id, route_id: route_id}) do
      {:ok, [_ | _] = schedules} ->
        schedules
        |> Enum.filter(&check_after(&1, time))
        |> next_unpredicted_departure(predictions)

      _ ->
        nil
    end
  end

  defp check_after(%{departure_time: nil}, _time) do
    false
  end

  defp check_after(%{departure_time: t}, time) do
    DateTime.compare(t, time) == :gt
  end

  defp next_unpredicted_departure([], _) do
    nil
  end

  defp next_unpredicted_departure([first_schedule | _], []) do
    first_schedule
  end

  defp next_unpredicted_departure(schedules, [%{trip: %{id: trip_id}}]) do
    schedules
    |> Enum.reject(fn %{trip_id: t_id} -> t_id == trip_id end)
    |> Enum.at(0)
  end

  defp next_unpredicted_departure(_schedules, _predictions) do
    # If there are two predictions, we don't want to show a schedule departure.
    nil
  end

  defp format_schedule(%{departure_time: t}), do: %{departure_time: t}
  defp format_schedule(nil), do: nil

  defp format_stops(route_stops, current_stop_index) do
    %{name: current_stop_name} = Enum.at(route_stops, current_stop_index)
    %{name: next_stop_name} = Enum.at(route_stops, current_stop_index + 1)
    %{name: following_stop_name} = Enum.at(route_stops, current_stop_index + 2)
    %{name: origin_stop_name} = Enum.at(route_stops, 0)

    %{
      current: current_stop_name,
      next: next_stop_name,
      following: following_stop_name,
      origin: origin_stop_name,
      count_before: current_stop_index
    }
  end

  defp format_vehicles(vehicles, route_stops, current_stop_index, predictions) do
    trip_id_to_time =
      predictions
      |> Enum.reject(&is_nil(&1.trip))
      |> Enum.map(&select_prediction_time/1)
      |> Enum.into(%{})

    vehicles
    |> Enum.map(&format_vehicle(&1, route_stops, current_stop_index, trip_id_to_time))
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(fn %{index: index} -> index < 0 end)
    |> maybe_strip_time()
  end

  def select_prediction_time(%{
        arrival_time: arrival_time,
        departure_time: departure_time,
        trip: %{id: trip_id}
      }) do
    time = Screens.Departures.Departure.select_prediction_time(arrival_time, departure_time)
    {trip_id, time}
  end

  defp maybe_strip_time(vehicles) do
    if Enum.any?(vehicles, fn v -> v.index > 2 and is_nil(v.time) end) do
      Enum.map(vehicles, &strip_time/1)
    else
      vehicles
    end
  end

  defp strip_time(vehicle) do
    %{vehicle | time: nil}
  end

  defp format_vehicle(
         %{id: id, stop_id: vehicle_stop_id, trip_id: vehicle_trip_id, current_status: status},
         route_stops,
         current_stop_index,
         trip_id_to_time
       ) do
    vehicle_stop_index =
      Enum.find_index(route_stops, fn %{id: route_stop_id} -> route_stop_id == vehicle_stop_id end)

    case vehicle_stop_index do
      nil ->
        nil

      _ ->
        index =
          2 + current_stop_index - vehicle_stop_index +
            status_adjustment(vehicle_stop_index, status)

        time = Map.get(trip_id_to_time, vehicle_trip_id)
        %{id: id, index: index, time: time}
    end
  end

  defp status_adjustment(0, _), do: 0.0
  defp status_adjustment(_, :stopped_at), do: 0.0
  defp status_adjustment(_, :in_transit_to), do: 0.7
  defp status_adjustment(_, :incoming_at), do: 0.3
end
