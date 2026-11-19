defmodule Screens.V2.WidgetInstance.LineMap do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Predictions.Prediction
  alias Screens.Trips.Trip
  alias Screens.Util
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.LineMap
  alias Screens.Vehicles.Vehicle
  alias ScreensConfig.Screen

  defstruct screen: nil,
            stops: [],
            reverse_stops: [],
            departures: [],
            alerts: []

  @type t :: %__MODULE__{
          screen: Screen.t(),
          stops: list(Screens.Stops.Stop.t()),
          reverse_stops: list(Screens.Stops.Stop.t()),
          departures: list(Departure.t()),
          alerts: list(Alert.t())
        }

  @type serialized_stop :: %{
          label: String.t(),
          closed: boolean(),
          downstream: boolean(),
          current: boolean(),
          terminal: boolean()
        }

  @type serialized_vehicle :: %{
          id: String.t(),
          index: float(),
          label: %{type: :text, text: String.t()} | %{type: :minutes, minutes: integer()} | nil,
          time_in_epoch: integer()
        }

  @type serialized_scheduled_departure :: %{
          timestamp: String.t(),
          station_name: String.t()
        }

  @type serialized_line_map :: %{
          stops: [serialized_stop()],
          vehicles: [serialized_vehicle()],
          scheduled_departure: serialized_scheduled_departure() | nil
        }

  @num_future_stops 2

  defimpl Screens.V2.WidgetInstance do
    def serialize(
          %LineMap{
            screen: config,
            stops: stops,
            reverse_stops: reverse_stops,
            departures: departures,
            alerts: alerts
          },
          now \\ DateTime.utc_now()
        ) do
      %Screen{
        app_params: %Screen.GlEink{
          line_map: %ScreensConfig.LineMap{
            stop_id: current_stop,
            direction_id: direction_id,
            route_id: route_id
          }
        }
      } = config

      current_stop_index = Enum.find_index(stops, fn %{id: stop} -> stop == current_stop end)
      current_stop_terminal? = current_stop_index == 0

      %{
        stops:
          LineMap.serialize_stops(
            current_stop,
            stops,
            reverse_stops,
            current_stop_terminal?,
            route_id,
            alerts
          ),
        vehicles:
          LineMap.serialize_vehicles(
            departures,
            stops,
            reverse_stops,
            direction_id,
            current_stop,
            now,
            current_stop_terminal?
          ),
        scheduled_departure:
          LineMap.serialize_scheduled_departure(
            departures,
            direction_id,
            stops,
            current_stop_terminal?
          )
      }
    end

    def priority(_instance), do: [2]
    def slot_names(_instance), do: [:left_sidebar]
    def page_groups(_instance), do: []
    def widget_type(_instance), do: :line_map
    def valid_candidate?(_instance), do: true
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: [0]
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.NullView
  end

  @spec serialize_stops(
          String.t(),
          [Screens.Stops.Stop.t()],
          [Screens.Stops.Stop.t()],
          boolean(),
          String.t(),
          [Alert.t()]
        ) :: [serialized_stop()]
  def serialize_stops(current_stop, stops, reverse_stops, terminal?, route_id, alerts \\ []) do
    current_stop_index = Enum.find_index(stops, fn %{id: stop} -> stop == current_stop end)

    closed_stop_ids = get_closed_stop_ids(alerts, route_id)

    forward_stops =
      stops
      |> Enum.slice(0, current_stop_index + @num_future_stops + 1)
      |> Enum.with_index()
      |> Enum.map(fn {%Screens.Stops.Stop{id: stop_id, name: label}, i} ->
        %{
          label: label,
          closed: MapSet.member?(closed_stop_ids, stop_id),
          downstream: i > current_stop_index,
          current: i == current_stop_index,
          terminal: i == 0 or i == length(stops) - 1
        }
      end)
      |> Enum.reverse()

    if terminal? do
      backward_stops =
        reverse_stops
        |> Enum.reverse()
        |> Enum.drop(1)
        |> Enum.with_index()
        |> Enum.map(fn {%Screens.Stops.Stop{id: stop_id, name: label}, i} ->
          %{
            label: label,
            closed: MapSet.member?(closed_stop_ids, stop_id),
            downstream: false,
            current: false,
            terminal: i == length(reverse_stops) - 2
          }
        end)

      forward_stops ++ backward_stops
    else
      forward_stops
    end
  end

  @spec serialize_vehicles(
          [Departure.t()],
          [Screens.Stops.Stop.t()],
          [Screens.Stops.Stop.t()],
          integer(),
          String.t(),
          DateTime.t(),
          boolean()
        ) :: [serialized_vehicle()]
  def serialize_vehicles(
        departures,
        stops,
        reverse_stops,
        direction_id,
        current_stop,
        now,
        terminal?
      ) do
    departures_with_vehicle_and_trip =
      departures
      |> Stream.reject(fn d -> is_nil(d.prediction) end)
      |> Stream.reject(fn %{prediction: p} -> is_nil(p.vehicle) or is_nil(p.trip) end)

    forward_vehicles =
      departures_with_vehicle_and_trip
      |> Stream.filter(&forward_directions_match?(&1, direction_id))
      |> Enum.flat_map(&serialize_vehicle_departure(&1, stops, current_stop, now))

    all_vehicles =
      if terminal? do
        backward_vehicles =
          departures_with_vehicle_and_trip
          |> Stream.filter(&reverse_directions_match?(&1, direction_id))
          |> Stream.flat_map(&serialize_vehicle_departure(&1, reverse_stops, current_stop, now))
          |> Enum.map(fn %{index: index} = v -> %{v | index: index + @num_future_stops} end)

        forward_vehicles ++ backward_vehicles
      else
        forward_vehicles
      end

    adjust_vehicles_for_overlaps(all_vehicles)
  end

  # We don't want to show overlapping train icons and predictions, so if two indices
  # are too close together, we'll push the later train down. If the predictions times
  # are the same, they can overlap slightly; if they're different, we space them further apart.
  defp adjust_vehicles_for_overlaps(vehicles) do
    vehicles
    |> Enum.sort_by(& &1.index)
    |> Enum.reduce([], &adjust_vehicle_for_overlaps/2)
    |> Enum.reverse()
  end

  defp adjust_vehicle_for_overlaps(v, []), do: [v]

  defp adjust_vehicle_for_overlaps(
         %{index: current_index, label: current_label} = v,
         [%{index: prev_index, label: prev_label} | _] = acc
       ) do
    minimum_index_difference = 0.4

    if current_index - prev_index <= minimum_index_difference do
      adjustment = if current_label == prev_label, do: 0.4, else: 0.7
      [%{v | index: prev_index + adjustment} | acc]
    else
      [v | acc]
    end
  end

  defp forward_directions_match?(
         %{
           prediction: %{
             vehicle: %{direction_id: vehicle_direction_id},
             trip: %{direction_id: trip_direction_id}
           }
         },
         direction_id
       ) do
    vehicle_direction_id == direction_id and trip_direction_id == direction_id
  end

  defp reverse_directions_match?(
         %{
           prediction: %{
             vehicle: %{direction_id: vehicle_direction_id},
             trip: %{direction_id: trip_direction_id}
           }
         },
         direction_id
       ) do
    vehicle_direction_id == 1 - direction_id and trip_direction_id == direction_id
  end

  defp serialize_vehicle_departure(
         %Departure{
           prediction: %Prediction{
             vehicle: %Vehicle{
               id: vehicle_id,
               current_status: vehicle_status,
               stop_id: vehicle_stop
             }
           }
         } = d,
         stops,
         current_stop,
         now
       ) do
    vehicle_stop_index = Enum.find_index(stops, fn %{id: stop} -> stop == vehicle_stop end)
    current_stop_index = Enum.find_index(stops, fn %{id: stop} -> stop == current_stop end)

    if is_nil(vehicle_stop_index) || is_nil(current_stop_index) do
      []
    else
      future_stops = min(length(stops) - current_stop_index - 1, @num_future_stops)

      index =
        future_stops + current_stop_index - vehicle_stop_index +
          status_adjustment(vehicle_stop_index, vehicle_status)

      label =
        if index < future_stops do
          nil
        else
          serialize_vehicle_label(d, now)
        end

      if index < 0 do
        []
      else
        # See `docs/mercury_api.md`
        departure_time_epoch = d |> Departure.time() |> DateTime.to_unix()
        [%{id: vehicle_id, index: index, label: label, time_in_epoch: departure_time_epoch}]
      end
    end
  end

  defp status_adjustment(0, _), do: 0.0
  defp status_adjustment(_, :stopped_at), do: 0.0
  defp status_adjustment(_, :in_transit_to), do: 0.7
  defp status_adjustment(_, :incoming_at), do: 0.3

  defp serialize_vehicle_label(d, now) do
    departure_time = Departure.time(d)
    second_diff = DateTime.diff(departure_time, now)
    minute_diff = round(second_diff / 60)

    if second_diff < 60 do
      %{type: :text, text: "Now"}
    else
      %{type: :minutes, minutes: minute_diff}
    end
  end

  @spec serialize_scheduled_departure(
          [Departure.t()],
          integer(),
          [Screens.Stops.Stop.t()],
          boolean()
        ) :: serialized_scheduled_departure() | nil
  def serialize_scheduled_departure(_departures, _direction_id, _stops, true = _terminal?),
    do: nil

  def serialize_scheduled_departure(departures, direction_id, stops, _terminal?) do
    # Number of departures with predictions (not just schedules) in this direction
    prediction_count =
      Enum.count(
        departures,
        &match?(%Departure{prediction: %Prediction{trip: %Trip{direction_id: ^direction_id}}}, &1)
      )

    departure = Enum.find(departures, &is_nil(&1.prediction))

    if prediction_count < 2 and not is_nil(departure) do
      %{name: origin_stop_name} = Enum.at(stops, 0)

      timestamp =
        departure
        |> Departure.time()
        |> Util.to_eastern()
        |> Calendar.strftime("%-I:%M")

      %{timestamp: timestamp, station_name: origin_stop_name}
    end
  end

  @spec get_closed_stop_ids([Alert.t()], String.t()) :: MapSet.t()
  defp get_closed_stop_ids(alerts, route_id) do
    alerts
    |> Enum.filter(&closure_alert?/1)
    |> Enum.flat_map(&closure_affected_stop_ids(&1, route_id))
    |> MapSet.new()
  end

  @spec closure_alert?(Alert.t()) :: boolean()
  defp closure_alert?(%Alert{effect: effect}) do
    effect in [:station_closure, :stop_closure, :suspension, :shuttle, :stop_moved]
  end

  @spec closure_affected_stop_ids(Alert.t(), String.t()) :: [String.t()]
  defp closure_affected_stop_ids(%Alert{informed_entities: informed_entities}, route_id) do
    informed_entities
    |> Enum.filter(fn entity ->
      not is_nil(entity.stop) and entity.route.id == route_id and
        Enum.find(entity.activities, &(&1 == :exit))
    end)
    |> Enum.map(fn entity -> entity.stop.id end)
    |> Enum.uniq()
  end
end
