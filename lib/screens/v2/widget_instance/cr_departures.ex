defmodule Screens.V2.WidgetInstance.CRDepartures do
  @moduledoc false

  alias Screens.Config.V2.CRDepartures
  alias Screens.Predictions.Prediction
  alias Screens.Stops.Stop
  alias Screens.V2.Departure

  defstruct config: nil,
            departures_data: [],
            destination: nil,
            direction_to_destination: nil,
            now: nil

  @type t :: %__MODULE__{
          config: CRDepartures.t(),
          departures_data: list(Departure.t()),
          destination: String.t(),
          direction_to_destination: String.t(),
          now: DateTime.t()
        }

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.CRDepartures, as: CRDeparturesWidget

    def priority(%CRDeparturesWidget{config: config}), do: config.priority

    def serialize(%CRDeparturesWidget{
          config: %CRDepartures{station: station} = config,
          departures_data: departures_data,
          destination: destination,
          direction_to_destination: direction_to_destination,
          now: now
        }) do
      %{
        departures:
          departures_data
          |> Enum.slice(0..2)
          |> Enum.map(
            &CRDeparturesWidget.serialize_departure(
              &1,
              destination,
              config.wayfinding_arrows,
              station,
              now
            )
          ),
        show_via_headsigns_message: config.show_via_headsigns_message,
        destination: destination,
        time_to_destination: config.travel_time_to_destination,
        direction: direction_to_destination
      }
    end

    def slot_names(_instance), do: [:main_content_left]

    def widget_type(_instance), do: :cr_departures

    def valid_candidate?(_instance), do: true

    def audio_serialize(instance), do: serialize(instance)

    def audio_sort_key(_instance), do: [1]

    def audio_valid_candidate?(_instance), do: true

    def audio_view(_instance), do: ScreensWeb.V2.Audio.CRDeparturesView
  end

  def serialize_departure(%Departure{} = departure, destination, wayfinding_arrows, station, now) do
    track_number = get_track_number(departure, station)
    prediction_or_schedule_id = Departure.id(departure)

    arrow =
      cond do
        is_map(wayfinding_arrows) and track_number ->
          wayfinding_arrows
          |> Enum.find(fn {_k, v} -> Enum.member?(v, track_number) end)
          |> Kernel.then(fn {k, _v} -> k end)

        is_map(wayfinding_arrows) ->
          nil

        true ->
          wayfinding_arrows
      end

    %{
      headsign: serialize_headsign(departure, destination),
      time: serialize_time(departure, now),
      track_number: track_number,
      prediction_or_schedule_id: prediction_or_schedule_id,
      arrow: arrow
    }
  end

  def serialize_headsign(departure, destination) do
    headsign = Departure.headsign(departure)

    via_pattern = ~r/(.+) (via .+)/
    paren_pattern = ~r/(.+) (\(.+)/

    [headsign, via_string] =
      cond do
        String.match?(headsign, via_pattern) ->
          Regex.run(via_pattern, headsign, capture: :all_but_first)

        String.match?(headsign, paren_pattern) ->
          Regex.run(paren_pattern, headsign, capture: :all_but_first)

        true ->
          [headsign, nil]
      end

    %{
      headsign: headsign,
      station_service_list: serialize_station_service_list(via_string, destination)
    }
  end

  defp serialize_time(
         %Departure{
           prediction: prediction,
           schedule: schedule
         } = departure,
         now
       ) do
    {:ok, scheduled_departure_time} =
      %Departure{schedule: schedule}
      |> Departure.time()
      |> DateTime.shift_zone("America/New_York")

    if is_nil(prediction) or is_nil(prediction.vehicle) do
      serialize_schedule_departure_time(scheduled_departure_time)
    else
      serialize_prediction_departure_time(
        departure,
        scheduled_departure_time,
        prediction.vehicle,
        now
      )
    end
  end

  defp serialize_schedule_departure_time(scheduled_departure_time) do
    %{departure_time: scheduled_departure_time, departure_type: :schedule}
  end

  defp serialize_prediction_departure_time(
         %Departure{prediction: prediction} = departure,
         scheduled_departure_time,
         vehicle,
         now
       ) do
    %Prediction{stop: %Stop{id: stop_id}} = prediction

    {:ok, predicted_departure_time} =
      departure
      |> Departure.time()
      |> DateTime.shift_zone("America/New_York")

    stop_type = Departure.stop_type(departure)
    second_diff = DateTime.diff(predicted_departure_time, now)
    minute_diff = round(second_diff / 60)
    is_delayed = DateTime.compare(scheduled_departure_time, predicted_departure_time) == :lt

    departure_time =
      cond do
        is_boarding?(
          vehicle,
          stop_type,
          stop_id,
          second_diff
        ) ->
          %{type: :text, text: "BRD"}

        vehicle.current_status === :in_transit_to and vehicle.stop_id === stop_id and
            minute_diff <= 1 ->
          %{type: :text, text: "NOW"}

        is_delayed ->
          scheduled_departure_time

        minute_diff < 60 ->
          %{type: :minutes, minutes: minute_diff}

        true ->
          serialize_timestamp(predicted_departure_time)
      end

    %{departure_time: departure_time, departure_type: :prediction, is_delayed: is_delayed}
  end

  defp is_boarding?(
         vehicle,
         stop_type,
         home_station_id,
         second_diff
       ),
       do:
         (vehicle.current_status == :stopped_at and vehicle.parent_stop_id === home_station_id and
            second_diff < 90) or
           (stop_type == :first_stop and second_diff < 30)

  defp serialize_timestamp(departure_time) do
    hour = 1 + Integer.mod(departure_time.hour - 1, 12)
    string_minute = Integer.to_string(departure_time.minute)
    updated_minute = if departure_time.minute < 10, do: "0" <> string_minute, else: string_minute
    am_pm = if departure_time.hour >= 12, do: :pm, else: :am

    %{
      type: :timestamp,
      timestamp: Integer.to_string(hour) <> ":" <> updated_minute,
      ampm: am_pm
    }
  end

  defp serialize_station_service_list(nil, _), do: []

  defp serialize_station_service_list(via_string, destination) do
    via_station = String.replace(via_string, "via ", "")

    case {destination, via_station} do
      {"Back Bay", _} ->
        [%{name: "Ruggles", service: true}, %{name: "Back Bay", service: true}]

      {"Forest Hills", "Ruggles"} ->
        [%{name: "Ruggles", service: true}, %{name: "Forest Hills", service: false}]

      {"Forest Hills", "Forest Hills"} ->
        [%{name: "Ruggles", service: true}, %{name: "Forest Hills", service: true}]

      _ ->
        []
    end
  end

  # Forrest Hills should not show a track number, only wayfinding arrow.
  defp get_track_number(_, "place-forhl"), do: nil
  defp get_track_number(departure, _station), do: Departure.track_number(departure)
end
