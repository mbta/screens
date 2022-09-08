defmodule Screens.V2.WidgetInstance.OvernightCRDepartures do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.{OvernightCRDepartures, PreFare}
  alias Screens.Schedules.Schedule
  alias Screens.V2.WidgetInstance

  @enforce_keys ~w[screen last_tomorrow_schedule direction_to_destination priority now]a
  defstruct screen: nil,
            last_tomorrow_schedule: nil,
            direction_to_destination: nil,
            priority: nil,
            now: nil

  @type t :: %__MODULE__{
          screen: Screen.t(),
          last_tomorrow_schedule: Schedule.t(),
          direction_to_destination: 0 | 1,
          priority: WidgetInstance.priority(),
          now: DateTime.t()
        }

  def priority(%__MODULE__{} = config), do: config.priority

  def serialize(%__MODULE__{
        screen: %Screen{app_params: %PreFare{overnight_cr_departures: config}},
        direction_to_destination: direction_to_destination,
        last_tomorrow_schedule: %Schedule{departure_time: departure_time, stop_headsign: headsign},
        now: now
      }) do
    {:ok, local_departure_time} = DateTime.shift_zone(departure_time, "America/New_York")
    {overnight_text_english, overnight_text_spanish} = get_overnight_text(config, now)
    {headsign_stop, headsign_via} = format_headsign(headsign)

    %{
      direction: serialize_direction(direction_to_destination),
      last_schedule_departure_time: local_departure_time,
      last_schedule_headsign_stop: headsign_stop,
      last_schedule_headsign_via: headsign_via,
      overnight_text_english: overnight_text_english,
      overnight_text_spanish: overnight_text_spanish
    }
  end

  def slot_names(_instance), do: [:main_content_left]

  def widget_type(_instance), do: :overnight_cr_departures

  def valid_candidate?(_instance), do: true

  def audio_serialize(_instance), do: %{}

  def audio_sort_key(_instance), do: [0]

  def audio_valid_candidate?(_instance), do: false

  defp serialize_direction(direction_id) do
    if direction_id == 0 do
      "outbound"
    else
      "inbound"
    end
  end

  defp get_overnight_text(
         %OvernightCRDepartures{} = config,
         now
       ) do
    day_of_week =
      now |> DateTime.shift_zone!("America/New_York") |> DateTime.to_date() |> Date.day_of_week()

    show_weekend_text? = day_of_week in 5..6

    if show_weekend_text? do
      {config.overnight_weekend_text_english, config.overnight_weekend_text_spanish}
    else
      {config.overnight_weekday_text_english, config.overnight_weekday_text_spanish}
    end
  end

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
