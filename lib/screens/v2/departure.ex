defmodule Screens.V2.Departure do
  @moduledoc false

  alias Screens.Predictions.Prediction
  alias Screens.Routes.Route
  alias Screens.Schedules.Schedule
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.Util
  alias Screens.V2.Departure.Builder
  alias Screens.Vehicles.Vehicle

  @type t :: %__MODULE__{
          prediction: Screens.Predictions.Prediction.t() | nil,
          schedule: Screens.Schedules.Schedule.t() | nil
        }

  defstruct prediction: nil, schedule: nil

  @type params :: %{
          optional(:direction_id) => Trip.direction() | :both,
          optional(:route_ids) => [Route.id()],
          optional(:route_type) => nil | :bus | :ferry | :light_rail | :rail | :subway,
          optional(:sort) => String.t(),
          optional(:stop_ids) => [Stop.id()]
        }

  @type opts :: [
          include_schedules: boolean(),
          now: DateTime.t()
        ]

  @type result :: {:ok, [t()]} | :error

  @type fetch :: (params(), opts() -> result())

  @default_params %{sort: "departure_time"}

  @callback fetch(params(), opts()) :: result()
  def fetch(params, opts \\ []) do
    # This is equivalent to an argument with a default value, so it's fine
    # credo:disable-for-next-line Screens.Checks.UntestableDateTime
    now = Keyword.get(opts, :now, DateTime.utc_now())

    if opts[:include_schedules] do
      fetch_predictions_and_schedules(params, now)
    else
      fetch_predictions_only(params, now)
    end
  end

  def fetch_predictions_and_schedules(
        params,
        now,
        fetch_predictions_fn \\ &Prediction.fetch/1,
        fetch_schedules_fn \\ &Schedule.fetch/1
      ) do
    with {:ok, predictions} <- fetch_predictions_fn.(params),
         {:ok, schedules} <- fetch_schedules_fn.(params) do
      relevant_predictions = Builder.get_relevant_departures(predictions, now)
      relevant_schedules = Builder.get_relevant_departures(schedules, now)

      departures =
        Builder.merge_predictions_and_schedules(
          relevant_predictions,
          relevant_schedules,
          schedules
        )

      {:ok, departures}
    else
      _ -> :error
    end
  end

  def fetch_predictions_only(params, now) do
    case Prediction.fetch(params) do
      {:ok, predictions} ->
        relevant_predictions = Builder.get_relevant_departures(predictions, now)
        departures = Enum.map(relevant_predictions, fn p -> %__MODULE__{prediction: p} end)
        {:ok, departures}

      :error ->
        :error
    end
  end

  def do_fetch(endpoint, params, parser) do
    encoded_params =
      @default_params
      |> Map.merge(params)
      |> Enum.map(&encode_param/1)
      |> Enum.reject(&is_nil/1)
      |> Map.new()

    case Screens.V3Api.get_json(endpoint, encoded_params) do
      {:ok, result} -> {:ok, parser.parse(result)}
      _ -> :error
    end
  end

  defp encode_param({:date, %DateTime{} = date}), do: {"filter[date]", Util.service_date(date)}
  defp encode_param({:date, %Date{} = date}), do: {"filter[date]", Date.to_iso8601(date)}
  defp encode_param({:date, date}), do: {"filter[date]", date}
  defp encode_param({:direction_id, :both}), do: nil
  defp encode_param({:direction_id, direction_id}), do: {"filter[direction_id]", direction_id}
  defp encode_param({:include, relationships}), do: {"include", Enum.join(relationships, ",")}
  defp encode_param({:route_ids, []}), do: nil
  defp encode_param({:route_ids, route_ids}), do: {"filter[route]", Enum.join(route_ids, ",")}
  defp encode_param({:route_type, nil}), do: nil

  defp encode_param({:route_type, route_type}),
    do: {"filter[route_type]", Screens.RouteType.to_id(route_type)}

  defp encode_param({:sort, sort}), do: {"sort", sort}
  defp encode_param({:stop_ids, []}), do: nil
  defp encode_param({:stop_ids, stop_ids}), do: {"filter[stop]", Enum.join(stop_ids, ",")}

  ### Accessor functions

  def crowding_level(%__MODULE__{prediction: p}) when not is_nil(p) do
    case p do
      %Prediction{trip: %Trip{} = trip, vehicle: %Vehicle{occupancy_status: status} = vehicle} ->
        if crowding_data_relevant?(trip, vehicle) do
          crowding_level_from_occupancy_status(status)
        else
          nil
        end

      _ ->
        nil
    end
  end

  def crowding_level(%__MODULE__{prediction: nil, schedule: _}), do: nil

  def direction_id(%__MODULE__{prediction: %Prediction{trip: %Trip{direction_id: direction_id}}}) do
    direction_id
  end

  def direction_id(%__MODULE__{prediction: nil, schedule: s}) do
    case s do
      %Schedule{trip: %Trip{direction_id: direction_id}} -> direction_id
      _ -> nil
    end
  end

  def headsign(%__MODULE__{prediction: p, schedule: s}) when not is_nil(p) do
    %Prediction{trip: %Trip{headsign: headsign}} = p

    case s do
      %Schedule{stop_headsign: stop_headsign} when not is_nil(stop_headsign) ->
        stop_headsign

      _ ->
        headsign
    end
  end

  def headsign(%__MODULE__{prediction: nil, schedule: s}) do
    case s do
      %Schedule{stop_headsign: stop_headsign} when not is_nil(stop_headsign) ->
        stop_headsign

      %Schedule{trip: %Trip{headsign: headsign}} ->
        headsign
    end
  end

  def id(%__MODULE__{prediction: %Prediction{id: prediction_id}}), do: prediction_id
  def id(%__MODULE__{schedule: %Schedule{id: schedule_id}}), do: schedule_id

  @spec representative_headsign(t()) :: String.t() | nil
  def representative_headsign(%__MODULE__{prediction: %Prediction{trip: trip}}),
    do: Trip.representative_headsign(trip)

  def representative_headsign(%__MODULE__{schedule: %Schedule{trip: trip}}),
    do: Trip.representative_headsign(trip)

  @spec route(t()) :: Route.t()
  def route(%__MODULE__{prediction: %Prediction{route: route}}), do: route
  def route(%__MODULE__{prediction: nil, schedule: %Schedule{route: route}}), do: route

  def scheduled_time(%__MODULE__{schedule: s}) when not is_nil(s) do
    select_arrival_time(s)
  end

  def scheduled_time(_), do: nil

  @spec stop(t()) :: Stop.t()
  def stop(%__MODULE__{prediction: %Prediction{stop: stop}}), do: stop
  def stop(%__MODULE__{prediction: nil, schedule: %Schedule{stop: stop}}), do: stop

  def stop_type(%__MODULE__{
        prediction: %Prediction{arrival_time: arrival_time, departure_time: departure_time}
      }) do
    identify_stop_type_from_times(arrival_time, departure_time)
  end

  def stop_type(%__MODULE__{
        prediction: nil,
        schedule: %Schedule{arrival_time: arrival_time, departure_time: departure_time}
      }) do
    identify_stop_type_from_times(arrival_time, departure_time)
  end

  def time(%__MODULE__{prediction: p}) when not is_nil(p) do
    select_arrival_time(p)
  end

  def time(%__MODULE__{prediction: nil, schedule: s}) do
    select_arrival_time(s)
  end

  def track_number(%__MODULE__{prediction: %Prediction{track_number: track_number}})
      when not is_nil(track_number) do
    track_number
  end

  def track_number(%__MODULE__{schedule: %Schedule{track_number: track_number}})
      when not is_nil(track_number) do
    track_number
  end

  def track_number(_), do: nil

  def vehicle_status(%__MODULE__{
        prediction: %Prediction{vehicle: %Vehicle{current_status: current_status}}
      }) do
    current_status
  end

  def vehicle_status(_), do: nil

  defp crowding_data_relevant?(%Trip{id: trip_trip_id, stops: [first_stop | _]}, %Vehicle{
         trip_id: vehicle_trip_id,
         stop_id: next_stop
       })
       when not is_nil(trip_trip_id) and not is_nil(vehicle_trip_id) do
    vehicle_on_prediction_trip? = trip_trip_id == vehicle_trip_id
    vehicle_started_trip? = not (next_stop == first_stop)
    vehicle_on_prediction_trip? and vehicle_started_trip?
  end

  defp crowding_data_relevant?(_trip, _vehicle), do: false

  defp crowding_level_from_occupancy_status(:many_seats_available), do: 1
  defp crowding_level_from_occupancy_status(:few_seats_available), do: 2
  defp crowding_level_from_occupancy_status(:full), do: 3
  defp crowding_level_from_occupancy_status(nil), do: nil

  defp select_arrival_time(%{arrival_time: nil, departure_time: t}), do: t
  defp select_arrival_time(%{arrival_time: t, departure_time: _}), do: t

  defp identify_stop_type_from_times(arrival_time, departure_time)
  defp identify_stop_type_from_times(nil, _), do: :first_stop
  defp identify_stop_type_from_times(_, nil), do: :last_stop
  defp identify_stop_type_from_times(_, _), do: :mid_route_stop
end
