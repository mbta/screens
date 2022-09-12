defmodule Screens.V2.WidgetInstance.OvernightCRDepartures do
  @moduledoc false

  alias Screens.Schedules.Schedule
  alias Screens.V2.WidgetInstance

  @enforce_keys ~w[destination last_tomorrow_schedule direction_to_destination priority now]a
  defstruct destination: nil,
            last_tomorrow_schedule: nil,
            direction_to_destination: nil,
            priority: nil,
            now: nil

  @type t :: %__MODULE__{
          destination: String.t(),
          last_tomorrow_schedule: Schedule.t(),
          direction_to_destination: 0 | 1,
          priority: WidgetInstance.priority(),
          now: DateTime.t()
        }

  def priority(%__MODULE__{} = config), do: config.priority

  def serialize(%__MODULE__{
        destination: destination,
        direction_to_destination: direction_to_destination,
        last_tomorrow_schedule: %Schedule{departure_time: departure_time, stop_headsign: headsign}
      }) do
    {:ok, local_departure_time} = DateTime.shift_zone(departure_time, "America/New_York")
    {headsign_stop, headsign_via} = format_headsign(headsign)

    %{
      direction: direction_to_destination,
      last_schedule_departure_time: local_departure_time,
      last_schedule_headsign_stop: headsign_stop,
      last_schedule_headsign_via: serialize_via_string(destination, headsign_via)
    }
  end

  defp serialize_via_string(destination, via_string) do
    via_station = String.replace(via_string, "via ", "")

    case {destination, via_station} do
      {"Back Bay", _} ->
        "Ruggles and Back Bay"

      {"Forest Hills", "Ruggles"} ->
        "Ruggles"

      {"Forest Hills", "Forest Hills"} ->
        "Ruggles and Forest Hills"

      _ ->
        ""
    end
  end

  def slot_names(_instance), do: [:main_content_left]

  def widget_type(_instance), do: :overnight_cr_departures

  def valid_candidate?(_instance), do: true

  def audio_serialize(instance), do: serialize(instance)

  def audio_sort_key(_instance), do: [1]

  def audio_valid_candidate?(_instance), do: true

  defp format_headsign(headsign) do
    via_pattern = ~r/(.+) (via .+)/

    [headsign, via_string] =
      if String.match?(headsign, via_pattern) do
        Regex.run(via_pattern, headsign, capture: :all_but_first)
      else
        [headsign, nil]
      end

    {headsign, via_string}
  end

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.OvernightCRDepartures

    def priority(instance), do: OvernightCRDepartures.priority(instance)
    def serialize(instance), do: OvernightCRDepartures.serialize(instance)
    def slot_names(instance), do: OvernightCRDepartures.slot_names(instance)
    def widget_type(instance), do: OvernightCRDepartures.widget_type(instance)
    def valid_candidate?(instance), do: OvernightCRDepartures.valid_candidate?(instance)
    def audio_serialize(instance), do: OvernightCRDepartures.audio_serialize(instance)
    def audio_sort_key(instance), do: OvernightCRDepartures.audio_sort_key(instance)

    def audio_valid_candidate?(instance),
      do: OvernightCRDepartures.audio_valid_candidate?(instance)

    def audio_view(_instance), do: ScreensWeb.V2.Audio.OvernightCRDeparturesView
  end
end
