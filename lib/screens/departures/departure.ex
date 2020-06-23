defmodule Screens.Departures.Departure do
  @moduledoc false

  alias Screens.Predictions.Prediction
  alias Screens.Schedules.Schedule
  alias Screens.Trips.Trip
  alias Screens.Vehicles.Vehicle

  defstruct id: nil,
            stop_name: nil,
            route: nil,
            route_id: nil,
            destination: nil,
            direction_id: nil,
            vehicle_status: nil,
            alerts: [],
            stop_type: nil,
            time: nil,
            crowding_level: nil,
            inline_badges: nil

  @type crowding_level :: 1 | 2 | 3 | nil

  @type t :: %__MODULE__{
          id: String.t(),
          stop_name: String.t(),
          route: String.t(),
          route_id: String.t(),
          destination: String.t(),
          direction_id: 0 | 1 | nil,
          vehicle_status: String.t(),
          alerts: list(:delay | :snow_route | :last_trip),
          stop_type: :first_stop | :last_stop | :mid_route_stop,
          time: DateTime.t(),
          crowding_level: crowding_level,
          inline_badges: list(map())
        }

  def fetch(query_params, opts \\ %{}) do
    case Map.get(opts, :include_schedules, false) do
      true -> fetch_predictions_and_schedules(query_params)
      false -> fetch_predictions_only(query_params)
    end
  end

  def fetch_schedules_by_datetime(query_params, dt) do
    # Find the current service date by shifting the given datetime to Pacific Time.
    # This splits the service day at 3am, as midnight at Pacific Time is always 3am here.
    {:ok, pacific_time} = DateTime.shift_zone(dt, "America/Los_Angeles")
    service_date = DateTime.to_date(pacific_time)

    schedules =
      query_params
      |> Map.put(:date, Date.to_string(service_date))
      |> Schedule.fetch()

    case schedules do
      {:ok, data} ->
        departures =
          data
          |> Enum.reject(fn %{departure_time: departure_time} -> is_nil(departure_time) end)
          |> Enum.filter(fn %{departure_time: departure_time} ->
            DateTime.compare(departure_time, dt) != :lt
          end)
          |> deduplicate_combined_routes()
          |> Enum.map(&from_prediction_or_schedule/1)

        {:ok, departures}

      :error ->
        :error
    end
  end

  defp fetch_predictions_only(query_params) do
    query_params
    |> Prediction.fetch()
    |> from_predictions()
  end

  # Copies stop headsigns from schedules to predictions with the same trip_id
  defp copy_stop_headsigns(predictions, schedules) do
    stop_headsigns_by_trip =
      schedules
      |> Enum.reject(&is_nil(&1.trip))
      |> Enum.map(fn %{trip: %{id: trip_id}, stop_headsign: stop_headsign} ->
        {trip_id, stop_headsign}
      end)
      |> Enum.into(%{})

    Enum.map(predictions, &copy_stop_headsign(&1, stop_headsigns_by_trip))
  end

  defp copy_stop_headsign(%{trip: %{id: trip_id}} = prediction, stop_headsigns_by_trip) do
    stop_headsign = Map.get(stop_headsigns_by_trip, trip_id)
    %{prediction | stop_headsign: stop_headsign}
  end

  defp copy_stop_headsign(prediction, _stop_headsigns_by_trip) do
    prediction
  end

  defp merge_predictions_and_schedules({:ok, predictions}, {:ok, schedules}) do
    predictions = copy_stop_headsigns(predictions, schedules)

    predicted_trip_ids =
      predictions
      |> Enum.reject(&is_nil(&1.trip))
      |> Enum.reject(&is_nil(&1.departure_time))
      |> Enum.map(& &1.trip.id)
      |> Enum.into(MapSet.new())

    unpredicted_schedules =
      Enum.reject(schedules, fn %{trip: %{id: trip_id}} -> trip_id in predicted_trip_ids end)

    {:ok, predicted_departures} = from_predictions({:ok, predictions})
    {:ok, scheduled_departures} = from_schedules({:ok, unpredicted_schedules})

    merged =
      (predicted_departures ++ scheduled_departures)
      |> Enum.sort_by(& &1.time)

    {:ok, merged}
  end

  defp merge_predictions_and_schedules(_, _), do: :error

  def from_schedules({:ok, schedules}) do
    departures =
      schedules
      |> Enum.reject(fn %{departure_time: departure_time} -> is_nil(departure_time) end)
      |> Enum.reject(&departure_in_past/1)
      |> deduplicate_combined_routes()
      |> Enum.map(&from_prediction_or_schedule/1)

    {:ok, departures}
  end

  def from_schedules(:error), do: :error

  def from_predictions({:ok, predictions}) do
    departures =
      predictions
      |> Enum.reject(fn %{departure_time: departure_time} -> is_nil(departure_time) end)
      |> Enum.reject(&departure_in_past/1)
      |> deduplicate_combined_routes()
      |> Enum.map(&from_prediction_or_schedule/1)

    {:ok, departures}
  end

  def from_predictions(:error), do: :error

  defp from_prediction_or_schedule(
         %{
           id: id,
           stop: %{name: stop_name},
           route: %{id: route_id, short_name: route_short_name},
           arrival_time: arrival_time,
           departure_time: departure_time,
           stop_headsign: stop_headsign
         } = data
       ) do
    time = select_prediction_time(arrival_time, departure_time)

    base_data = %{
      id: id,
      stop_name: stop_name,
      route: route_short_name,
      route_id: route_id,
      time: DateTime.to_iso8601(time),
      stop_type: stop_type(arrival_time, departure_time),
      inline_badges: []
    }

    trip_data =
      case Map.get(data, :trip) do
        %{headsign: destination, direction_id: direction_id} ->
          # Override trip headsign with stop_headsign if not nil
          case stop_headsign do
            nil -> %{destination: destination, direction_id: direction_id}
            _ -> %{destination: stop_headsign, direction_id: direction_id}
          end

        nil ->
          %{}
      end

    vehicle_data =
      case Map.get(data, :vehicle) do
        %{current_status: current_status} = vehicle ->
          trip = Map.get(data, :trip)
          %{vehicle_status: current_status, crowding_level: crowding_level(vehicle, trip)}

        nil ->
          %{}
      end

    alert_data =
      case Map.get(data, :alerts) do
        nil -> %{}
        alerts -> %{alerts: get_alerts_list(alerts)}
      end

    departure = Enum.reduce([base_data, trip_data, vehicle_data, alert_data], &Map.merge/2)

    struct(__MODULE__, departure)
  end

  def select_prediction_time(arrival_time, departure_time) do
    case {arrival_time, departure_time} do
      {nil, t} -> t
      {_, nil} -> nil
      {t, _} -> t
    end
  end

  def stop_type(arrival_time, departure_time) do
    case {arrival_time, departure_time} do
      {nil, _} -> :first_stop
      {_, nil} -> :last_stop
      {_, _} -> :mid_route_stop
    end
  end

  @spec crowding_level(Vehicle.t(), Trip.t() | nil) :: crowding_level
  defp crowding_level(_vehicle, nil), do: nil

  defp crowding_level(vehicle, trip) do
    %{occupancy_status: occupancy_status, trip_id: vehicle_trip_id} = vehicle
    %{id: trip_trip_id} = trip

    if trip_trip_id == vehicle_trip_id do
      crowding_level_from_occupancy_status(occupancy_status)
    else
      nil
    end
  end

  @spec crowding_level_from_occupancy_status(Vehicle.occupancy_status()) :: crowding_level
  defp crowding_level_from_occupancy_status(:many_seats_available), do: 1
  defp crowding_level_from_occupancy_status(:few_seats_available), do: 2
  defp crowding_level_from_occupancy_status(:full), do: 3
  defp crowding_level_from_occupancy_status(nil), do: nil

  defp fetch_predictions_and_schedules(query_params) do
    predictions = Prediction.fetch(query_params)
    schedules = Schedule.fetch(query_params)
    merge_predictions_and_schedules(predictions, schedules)
  end

  def do_query_and_parse(query_params, api_endpoint, parser) do
    default_params = %{"sort" => "departure_time", "include" => "route,stop,trip"}

    api_query_params =
      query_params |> Enum.map(&format_query_param/1) |> Enum.into(default_params)

    case Screens.V3Api.get_json(api_endpoint, api_query_params) do
      {:ok, result} -> {:ok, parser.parse_result(result)}
      _ -> :error
    end
  end

  defp format_query_param({:stop_id, stop_id}) do
    {"filter[stop]", stop_id}
  end

  defp format_query_param({:stop_ids, stop_ids}) do
    {"filter[stop]", Enum.join(stop_ids, ",")}
  end

  defp format_query_param({:route_id, route_id}) do
    {"filter[route]", route_id}
  end

  defp format_query_param({:route_ids, route_ids}) do
    {"filter[route]", Enum.join(route_ids, ",")}
  end

  defp format_query_param({:direction_id, direction_id}) do
    {"filter[direction_id]", direction_id}
  end

  defp format_query_param({:include, relationships}) do
    {"include", Enum.join(relationships, ",")}
  end

  defp format_query_param({:date, date}) do
    {"date", date}
  end

  # Chooses the "preferred prediction" from multiple predictions in cases of combined routes.
  #
  # For any set of predictions with the same ID, they will also share the same trip, but will have differing routes.
  # This function filters out predictions whose route ID does not equal its trip's route ID.
  #
  # For buses, that means removing predictions for routes 24 and 27 when combined route 24/27 exists.
  defp deduplicate_combined_routes(predictions) do
    Enum.filter(predictions, &(&1.route.id == &1.trip.route_id))
  end

  def departure_in_past(%{departure_time: departure_time}) do
    DateTime.compare(departure_time, DateTime.utc_now()) == :lt
  end

  def associate_alerts_with_departures(departures, alerts) do
    delay_map = Screens.Alerts.Alert.build_delay_map(alerts)
    Enum.map(departures, &update_departure_with_delay_alert(delay_map, &1))
  end

  defp update_departure_with_delay_alert(delay_map, %{route_id: route_id} = departure) do
    case delay_map do
      %{^route_id => severity} ->
        %{departure | inline_badges: [%{type: :delay, severity: severity}]}

      _ ->
        departure
    end
  end

  defp get_alerts_list(alerts) do
    [
      delay: Enum.any?(alerts, &(&1.effect == :delay)),
      snow_route: false,
      last_trip: false
    ]
    |> Enum.filter(fn {_alert_type, active?} -> active? end)
    |> Enum.map(fn {alert_type, _active?} -> alert_type end)
  end
end
