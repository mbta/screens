defmodule Screens.V2.WidgetInstance.CRDepartures do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Dup.Override.FreeTextLine
  alias Screens.Config.Screen
  alias Screens.Config.V2.CRDepartures
  alias Screens.Util
  alias Screens.V2.Departure
  alias Screens.V2.WidgetInstance.CRDepartures, as: CRDeparturesWidget
  alias Screens.V2.WidgetInstance.Serializer.RoutePill

  defstruct config: nil,
            departures_data: []

  @type t :: %__MODULE__{
          config: CRDepartures.t(),
          departures_data: list(Departure.t())
        }

  defimpl Screens.V2.WidgetInstance do
    def priority(%CRDeparturesWidget{config: config}), do: config.priority

    def serialize(%CRDeparturesWidget{departures_data: departures_data}) do
      %{departures: Enum.map(departures_data, &CRDeparturesWidget.serialize_departure/1)}
    end

    # TODO: review below

    def slot_names(_instance), do: [:main_content_left]

    def widget_type(_instance), do: :cr_departures

    def valid_candidate?(_instance), do: true

    def audio_serialize(%CRDeparturesWidget{departures_data: departures_data, config: config}) do
      %{departures: Enum.map(departures_data, &CRDeparturesWidget.serialize_departure/1)}
    end

    def audio_sort_key(_instance), do: [1]

    def audio_valid_candidate?(_instance), do: true

    def audio_view(_instance), do: ScreensWeb.V2.Audio.CRDeparturesView
  end

  def serialize_departure(%Departure{} = departure, now \\ DateTime.utc_now()) do
    %{
      headsign: serialize_headsign(departure),
      time: serialize_time_with_schedule(departure, now),
      track_number: Departure.track_number(departure)
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
    route_type = Departure.route_type(departure)

    second_diff = DateTime.diff(departure_time, now)
    minute_diff = round(second_diff / 60)

    time =
      cond do
        vehicle_status == :stopped_at and second_diff < 90 ->
          %{type: :text, text: "BRD"}

        second_diff < 30 and stop_type == :first_stop ->
          %{type: :text, text: "BRD"}

        second_diff < 30 ->
          %{type: :text, text: "ARR"}

        minute_diff < 60 and route_type not in [:rail, :ferry] ->
          %{type: :minutes, minutes: minute_diff}

        true ->
          serialize_timestamp(departure_time)
      end

    %{time: time}
  end

  defp serialize_time_with_schedule(departure, now) do
    %{time: serialized_time} = serialize_time(departure, now)

    scheduled_time = Departure.scheduled_time(departure)

    if is_nil(scheduled_time) do
      %{time: serialized_time}
    else
      serialized_scheduled_time = serialize_timestamp(scheduled_time)

      case serialized_time do
        %{type: :text} ->
          %{time: serialized_time}

        ^serialized_scheduled_time ->
          %{time: serialized_time}

        _ ->
          %{time: serialized_time, scheduled_time: serialized_scheduled_time}
      end
    end
  end

  defp serialize_timestamp(departure_time) do
    {:ok, local_time} = DateTime.shift_zone(departure_time, "America/New_York")
    hour = 1 + Integer.mod(local_time.hour - 1, 12)
    minute = local_time.minute
    am_pm = if local_time.hour >= 12, do: :pm, else: :am
    %{type: :timestamp, hour: hour, minute: minute, am_pm: am_pm}
  end
end
