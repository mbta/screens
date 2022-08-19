defmodule Screens.V2.WidgetInstance.CRDepartures do
  @moduledoc false

  alias Screens.Config.V2.CRDepartures
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.CRDepartures, as: CRDeparturesWidget

  defstruct config: nil,
            departures_data: [],
            destination: nil

  @type t :: %__MODULE__{
          config: CRDepartures.t(),
          departures_data: list(Departure.t()),
          destination: String.t()
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(%CRDeparturesWidget{config: config}), do: config.priority

    def serialize(%CRDeparturesWidget{
          config: config,
          departures_data: departures_data,
          destination: destination
        }) do
      %{
        departures:
          departures_data
          |> Enum.map(&CRDeparturesWidget.serialize_departure(&1, config.wayfinding_arrows))
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

  def serialize_departure(%Departure{} = departure, wayfinding_arrows, now \\ DateTime.utc_now()) do
    track_number = Departure.track_number(departure)

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
      headsign: serialize_headsign(departure),
      time: serialize_time(departure, now),
      track_number: track_number,
      arrow: arrow
    }
  end

  def serialize_headsign(departure) do
    headsign = Departure.headsign(departure)

    via_pattern = ~r/(.+) (via .+)/
    paren_pattern = ~r/(.+) (\(.+)/

    [headsign, variation] =
      cond do
        String.match?(headsign, via_pattern) ->
          Regex.run(via_pattern, headsign, capture: :all_but_first)

        String.match?(headsign, paren_pattern) ->
          Regex.run(paren_pattern, headsign, capture: :all_but_first)

        true ->
          [headsign, nil]
      end

    %{headsign: headsign, variation: variation}
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
    minute = local_time.minute
    am_pm = if local_time.hour >= 12, do: :pm, else: :am

    %{
      type: :timestamp,
      timestamp: Integer.to_string(hour) <> ":" <> Integer.to_string(minute),
      ampm: am_pm
    }
  end
end
