defmodule Screens.V2.WidgetInstance.LineMap do
  @moduledoc false

  alias Screens.Config.{Screen, V2}
  alias Screens.Predictions.Prediction
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.LineMap
  alias Screens.Vehicles.Vehicle

  defstruct screen: nil,
            stops: [],
            departures: []

  @type t :: %__MODULE__{
          screen: Screen.t(),
          stops: list(Screens.Stops.Stop.t()),
          departures: list(Departure.t())
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]

    def serialize(
          %LineMap{screen: config, stops: stops, departures: departures},
          now \\ DateTime.utc_now()
        ) do
      %Screen{
        app_params: %V2.GlEink{
          line_map: %V2.LineMap{stop_id: current_stop, direction_id: direction_id}
        }
      } = config

      %{
        stops: LineMap.serialize_stops(current_stop, stops),
        vehicles: LineMap.serialize_vehicles(departures, stops, direction_id, current_stop, now),
        scheduled_departure: LineMap.serialize_scheduled_departure(departures, stops)
      }
    end

    def slot_names(_instance), do: [:left_sidebar]

    def widget_type(_instance), do: :line_map

    def valid_candidate?(_instance), do: true

    def audio_serialize(_instance), do: %{}

    def audio_sort_key(_instance), do: 0

    def audio_valid_candidate?(_instance), do: false

    def audio_view(_instance), do: ScreensWeb.Views.V2.Audio.LineMapView
  end

  def serialize_stops(current_stop, stops) do
    current_stop_index = Enum.find_index(stops, fn %{id: stop} -> stop == current_stop end)

    stops
    |> Enum.slice(0, current_stop_index + 3)
    |> Enum.with_index()
    |> Enum.map(fn {%Screens.Stops.Stop{name: label}, i} ->
      %{
        label: label,
        downstream: i > current_stop_index,
        current: i == current_stop_index,
        terminal: i == 0 or i == length(stops) - 1
      }
    end)
    |> Enum.reverse()
  end

  def serialize_vehicles(departures, stops, direction_id, current_stop, now) do
    departures
    |> Enum.reject(fn d -> is_nil(d.prediction) end)
    |> Enum.reject(fn %{prediction: %{vehicle: v}} -> is_nil(v) end)
    |> Enum.filter(fn %{prediction: %{vehicle: %{direction_id: d}}} -> d == direction_id end)
    |> Enum.flat_map(&serialize_vehicle_departure(&1, stops, current_stop, now))
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
    future_stops = min(length(stops) - current_stop_index - 1, 2)

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
      [%{id: vehicle_id, index: index, label: label}]
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

  def serialize_scheduled_departure(departures, stops) do
    prediction_count =
      departures
      |> Enum.reject(fn d -> is_nil(d.prediction) end)
      |> length()

    if prediction_count < 2 do
      %{name: origin_stop_name} = Enum.at(stops, 0)

      {:ok, local_time} =
        departures
        |> Enum.filter(fn d -> is_nil(d.prediction) end)
        |> Enum.at(0)
        |> Departure.time()
        |> DateTime.shift_zone("America/New_York")

      {:ok, timestamp} = Timex.format(local_time, "{h12}:{m}")

      %{timestamp: timestamp, station_name: origin_stop_name}
    else
      nil
    end
  end
end
