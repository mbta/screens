defmodule Screens.V2.WidgetInstance.CRDepartures do
  @moduledoc false

  alias Screens.Config.V2.CRDepartures
  alias Screens.V2.Departure

  defstruct config: nil,
            departures_data: [],
            destination: nil,
            now: nil

  @type t :: %__MODULE__{
          config: CRDepartures.t(),
          departures_data: list(Departure.t()),
          destination: String.t(),
          now: DateTime.t()
        }

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.CRDepartures, as: CRDeparturesWidget

    def priority(%CRDeparturesWidget{config: config}), do: config.priority

    def serialize(%CRDeparturesWidget{
          config: %CRDepartures{station: station} = config,
          departures_data: departures_data,
          destination: destination,
          now: now
        }) do
      %{
        departures:
          departures_data
          |> Enum.map(
            &CRDeparturesWidget.serialize_departure(
              &1,
              destination,
              config.wayfinding_arrows,
              station,
              now
            )
          )
          |> Enum.slice(0..2),
        show_via_headsigns_message: config.show_via_headsigns_message,
        destination: destination,
        time_to_destination: config.travel_time_to_destination
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

  defp serialize_time(departure, now) do
    departure_time = Departure.time(departure)
    vehicle_status = Departure.vehicle_status(departure)
    stop_type = Departure.stop_type(departure)

    second_diff = DateTime.diff(departure_time, now)
    minute_diff = round(second_diff / 60)

    cond do
      vehicle_status == :stopped_at and second_diff < 90 ->
        %{type: :text, text: "BRD"}

      second_diff < 30 and stop_type == :first_stop ->
        %{type: :text, text: "BRD"}

      second_diff < 30 ->
        %{type: :text, text: "ARR"}

      minute_diff < 60 ->
        %{type: :minutes, minutes: minute_diff}

      true ->
        serialize_timestamp(departure_time)
    end
  end

  defp serialize_timestamp(departure_time) do
    {:ok, local_time} = DateTime.shift_zone(departure_time, "America/New_York")
    hour = 1 + Integer.mod(local_time.hour - 1, 12)
    string_minute = Integer.to_string(local_time.minute)
    updated_minute = if local_time.minute < 10, do: "0" <> string_minute, else: string_minute
    am_pm = if local_time.hour >= 12, do: :pm, else: :am

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
