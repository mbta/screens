defmodule Screens.Departures.Departure do
  @moduledoc false

  require Logger

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
            scheduled_time: nil,
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

  @type query_params :: %{
          optional(:stop_ids) => list(String.t()),
          optional(:route_ids) => list(String.t()),
          optional(:direction_id) => 0 | 1 | :both,
          optional(:sort) => String.t(),
          optional(:include) => list(String.t()),
          optional(:date) => String.t(),
          optional(:route_type) => Screens.RouteType.t() | nil
        }

  @spec fetch(query_params(), boolean()) :: {:ok, list()} | :error
  def fetch(%{} = query_params, include_schedules \\ false) do
    if include_schedules do
      fetch_predictions_and_schedules(query_params)
    else
      fetch_predictions_only(query_params)
    end
  end

  @spec fetch_schedules_by_datetime(query_params(), DateTime.t()) :: {:ok, t()} | :error
  def fetch_schedules_by_datetime(%{} = query_params, dt) do
    # Find the current service date by shifting the given datetime to Pacific Time.
    # This splits the service day at 3am, as midnight at Pacific Time is always 3am here.
    {:ok, pacific_time} = DateTime.shift_zone(dt, "America/Los_Angeles")
    service_date = DateTime.to_date(pacific_time)

    schedules = Schedule.fetch(query_params, Date.to_string(service_date))

    case schedules do
      {:ok, data} ->
        departures =
          data
          |> Enum.filter(fn %{departure_time: departure_time} ->
            DateTime.compare(departure_time, dt) != :lt
          end)
          |> deduplicate_slashed_routes()
          |> Enum.map(&from_prediction_or_schedule/1)

        {:ok, departures}

      :error ->
        :error
    end
  end

  defp fetch_predictions_only(%{} = query_params) do
    case Prediction.fetch(query_params) do
      {:ok, predictions} ->
        predictions
        |> Enum.reject(&departure_in_past/1)
        |> deduplicate_slashed_routes()
        |> deduplicate_repeated_trips()
        |> from_predictions_or_schedules()

      :error ->
        :error
    end
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

  # Attaches scheduled times to predicted departures.
  # For each departure, look up the corresponding prediction's trip,
  # then find the schedule for that trip.
  defp with_scheduled_times(predicted_departures, predictions, schedules) do
    predictions_by_id = Enum.into(predictions, %{}, fn %{id: id} = p -> {id, p} end)

    schedules_by_trip_id =
      schedules
      |> Enum.reject(fn
        %{trip: nil} -> true
        %{trip: %{id: nil}} -> true
        _ -> false
      end)
      |> Enum.into(%{}, fn %{trip: %{id: trip_id}} = s -> {trip_id, s} end)

    Enum.map(
      predicted_departures,
      &with_scheduled_time(&1, predictions_by_id, schedules_by_trip_id)
    )
  end

  defp with_scheduled_time(departure, predictions_by_id, schedules_by_trip_id) do
    %{id: id} = departure

    case Map.get(predictions_by_id, id) do
      %{trip: nil} ->
        departure

      %{trip: %{id: nil}} ->
        departure

      %{trip: %{id: trip_id}} ->
        case Map.get(schedules_by_trip_id, trip_id) do
          nil ->
            departure

          %{arrival_time: arrival_time, departure_time: departure_time} ->
            time = select_prediction_time(arrival_time, departure_time)
            %{departure | scheduled_time: DateTime.to_iso8601(time)}
        end
    end
  end

  defp merge_predictions_and_schedules({:ok, all_predictions}, {:ok, all_schedules}) do
    filtered_predictions = filter_predictions_or_schedules(all_predictions)
    filtered_schedules = filter_predictions_or_schedules(all_schedules)

    filtered_predictions = copy_stop_headsigns(filtered_predictions, filtered_schedules)

    predicted_trip_ids =
      filtered_predictions
      |> Enum.reject(&is_nil(&1.trip))
      |> Enum.map(& &1.trip.id)
      |> Enum.into(MapSet.new())

    unpredicted_schedules =
      Enum.reject(filtered_schedules, fn %{trip: %{id: trip_id}} ->
        trip_id in predicted_trip_ids
      end)

    {:ok, predicted_departures} = from_predictions_or_schedules({:ok, filtered_predictions})
    {:ok, scheduled_departures} = from_predictions_or_schedules({:ok, unpredicted_schedules})

    predicted_departures =
      with_scheduled_times(predicted_departures, filtered_predictions, all_schedules)

    merged =
      (predicted_departures ++ scheduled_departures)
      |> Enum.sort_by(& &1.time)

    {:ok, merged}
  end

  defp merge_predictions_and_schedules(_, _), do: :error

  def from_predictions_or_schedules({:ok, schedules}) do
    {:ok, Enum.map(schedules, &from_prediction_or_schedule/1)}
  end

  def from_predictions_or_schedules(:error), do: :error

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
          %{
            # Override trip headsign with stop_headsign if not nil
            destination: if(is_nil(stop_headsign), do: destination, else: stop_headsign),
            direction_id: direction_id
          }

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
    %{
      current_status: current_status,
      occupancy_status: occupancy_status,
      trip_id: vehicle_trip_id,
      stop_id: next_stop
    } = vehicle

    %{id: trip_trip_id, stops: stops} = trip

    first_stop =
      case stops do
        [s | _] -> s
        _ -> nil
      end

    # We only want to show crowding data if the data is relevant to riders looking at this screen.
    # Crowding data for a vehicle is only relevant if the vehicle has actually started the trip
    # associated with the predicted departure: The trip ids of the vehicle and prediction must
    # match, and the vehicle can't be IN_TRANSIT_TO the first stop, or else the trip has not begun.
    vehicle_on_prediction_trip? =
      not is_nil(trip_trip_id) and not is_nil(vehicle_trip_id) and trip_trip_id == vehicle_trip_id

    vehicle_started_trip? =
      not is_nil(first_stop) and
        not (current_status == :in_transit_to and next_stop == first_stop)

    crowding_data_relevant? = vehicle_on_prediction_trip? and vehicle_started_trip?

    if crowding_data_relevant? do
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

  defp fetch_predictions_and_schedules(%{} = query_params) do
    predictions = Prediction.fetch(query_params)
    schedules = Schedule.fetch(query_params)
    merge_predictions_and_schedules(predictions, schedules)
  end

  defp filter_predictions_or_schedules(predictions_or_schedules) do
    predictions_or_schedules
    |> Enum.reject(&departure_in_past/1)
    |> deduplicate_slashed_routes()
  end

  def do_query_and_parse(%{} = query_params, api_endpoint, parser, extra_params \\ %{}) do
    default_params = %{sort: "departure_time", include: ~w[route stop trip]}

    all_params = [default_params, query_params, extra_params]

    api_query_params =
      all_params
      |> Enum.reduce(fn params, acc -> Map.merge(acc, params) end)
      |> Enum.map(&format_query_param/1)
      |> Enum.reject(&is_nil/1)
      |> Enum.into(%{})

    case Screens.V3Api.get_json(api_endpoint, api_query_params) do
      {:ok, result} -> {:ok, parser.parse_result(result)}
      _ -> :error
    end
  end

  defp format_query_param({:stop_ids, []}) do
    nil
  end

  defp format_query_param({:stop_ids, stop_ids}) do
    {"filter[stop]", Enum.join(stop_ids, ",")}
  end

  defp format_query_param({:route_ids, []}) do
    nil
  end

  defp format_query_param({:route_ids, route_ids}) do
    {"filter[route]", Enum.join(route_ids, ",")}
  end

  defp format_query_param({:direction_id, :both}) do
    nil
  end

  defp format_query_param({:direction_id, direction_id}) do
    {"filter[direction_id]", direction_id}
  end

  defp format_query_param({:sort, sort}) do
    {"sort", sort}
  end

  defp format_query_param({:include, relationships}) do
    {"include", Enum.join(relationships, ",")}
  end

  defp format_query_param({:date, date}) do
    {"date", date}
  end

  defp format_query_param({:route_type, nil}) do
    nil
  end

  defp format_query_param({:route_type, route_type}) do
    {"filter[route_type]", Screens.RouteType.to_id(route_type)}
  end

  defp log_unexpected_groups(groups) do
    Enum.each(groups, fn {trip_id, predictions} ->
      route_ids = Enum.map(predictions, & &1.route.id)
      route_id = Enum.at(route_ids, 0)

      expected_route_ids = ["64", "120"]

      if length(route_ids) > 1 and !Enum.member?(expected_route_ids, route_id) do
        Logger.warn(
          "log_unexpected_groups found #{length(route_ids)} predictions on trip #{trip_id} for route #{
            Enum.at(route_ids, 0)
          }"
        )
      end
    end)

    groups
  end

  # If there are multiple predictions along the same trip, choose only the earliest one to display.
  # This addresses a specific issue at Central where late-night outbound 64 trips which start in
  # Central Square serve multiple stops we're displaying on the Solari screen there. This shouldn't
  # happen anywhere else.
  defp deduplicate_repeated_trips(predictions) do
    {predictions_without_trip, predictions_with_trip} =
      Enum.split_with(predictions, fn
        %{trip: nil} -> true
        %{trip: %{id: nil}} -> true
        _ -> false
      end)

    deduplicated_predictions_with_trip =
      predictions_with_trip
      |> Enum.group_by(fn %{trip: %Trip{id: trip_id}} -> trip_id end)
      |> log_unexpected_groups()
      |> Enum.map(fn {_trip_id, predictions} -> Enum.min_by(predictions, & &1.departure_time) end)

    deduplicated_predictions =
      (predictions_without_trip ++ deduplicated_predictions_with_trip)
      |> Enum.sort_by(& &1.departure_time)

    {:ok, deduplicated_predictions}
  end

  # This function filters out predictions whose route ID does not equal its trip's route ID.
  #
  # For buses, that means removing predictions for routes 24 and 27 when combined route 24/27 exists.
  defp deduplicate_slashed_routes(predictions) do
    Enum.filter(predictions, fn
      %{route: %{id: id1}, trip: %{route_id: id2}} -> id1 == id2
      _ -> true
    end)
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
