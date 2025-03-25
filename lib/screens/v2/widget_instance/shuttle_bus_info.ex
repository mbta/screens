defmodule Screens.V2.WidgetInstance.ShuttleBusInfo do
  @moduledoc false

  alias Screens.Util
  alias ScreensConfig.{Screen, ShuttleBusInfo, ShuttleBusSchedule}
  alias ScreensConfig.Screen.PreFare

  defstruct screen: nil, now: nil

  @type t :: %__MODULE__{
          screen: Screen.t(),
          now: DateTime.t()
        }

  def priority(%__MODULE__{
        screen: %Screen{
          app_params: %PreFare{shuttle_bus_info: %ShuttleBusInfo{priority: priority}}
        }
      }),
      do: priority

  def serialize(%__MODULE__{
        screen: %Screen{
          app_params: %PreFare{
            shuttle_bus_info: %ShuttleBusInfo{
              minutes_range_to_destination_schedule: minutes_range_to_destination_schedule,
              destination: destination,
              arrow: arrow,
              english_boarding_instructions: english_boarding_instructions,
              spanish_boarding_instructions: spanish_boarding_instructions
            }
          }
        },
        now: now
      }) do
    %{
      minutes_range_to_destination: get_minute_range(minutes_range_to_destination_schedule, now),
      destination: destination,
      arrow: arrow,
      english_boarding_instructions: english_boarding_instructions,
      spanish_boarding_instructions: spanish_boarding_instructions
    }
  end

  def widget_type(_instance), do: :shuttle_bus_info

  def valid_candidate?(%__MODULE__{screen: %Screen{app_id: :pre_fare_v2}}), do: true
  def valid_candidate?(_), do: false

  def slot_names(_instance), do: [:orange_line_surge_lower]

  def audio_serialize(%__MODULE__{
        screen: %Screen{
          app_params: %PreFare{
            shuttle_bus_info: %ShuttleBusInfo{
              minutes_range_to_destination_schedule: minutes_range_to_destination_schedule,
              destination: destination,
              audio_boarding_instructions: boarding_instructions
            }
          }
        },
        now: now
      }) do
    %{
      minutes_range_to_destination: get_minute_range(minutes_range_to_destination_schedule, now),
      destination: destination,
      boarding_instructions: boarding_instructions
    }
  end

  def audio_sort_key(_instance), do: [2]

  def audio_valid_candidate?(_instance), do: true

  def audio_view(_instance), do: ScreensWeb.V2.Audio.ShuttleBusInfoView

  defp get_minute_range(schedule, now) do
    local_now = Util.to_eastern(now)
    service_day_of_week = local_now |> Util.service_date() |> Date.day_of_week()

    %ShuttleBusSchedule{minute_range: minutes_range_to_destination} =
      Enum.find(schedule, fn %ShuttleBusSchedule{
                               days: days,
                               start_time: start_time,
                               end_time: end_time
                             } ->
        day_range =
          case days do
            :weekday -> 1..5
            :saturday -> [6]
            :sunday -> [7]
          end

        service_day_of_week in day_range and
          Util.time_in_range?(DateTime.to_time(local_now), start_time, end_time)
      end)

    minutes_range_to_destination
  end

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.ShuttleBusInfo

    def priority(instance), do: ShuttleBusInfo.priority(instance)
    def serialize(instance), do: ShuttleBusInfo.serialize(instance)
    def slot_names(instance), do: ShuttleBusInfo.slot_names(instance)
    def widget_type(instance), do: ShuttleBusInfo.widget_type(instance)
    def valid_candidate?(instance), do: ShuttleBusInfo.valid_candidate?(instance)
    def audio_serialize(instance), do: ShuttleBusInfo.audio_serialize(instance)
    def audio_sort_key(instance), do: ShuttleBusInfo.audio_sort_key(instance)
    def audio_valid_candidate?(instance), do: ShuttleBusInfo.audio_valid_candidate?(instance)
    def audio_view(instance), do: ShuttleBusInfo.audio_view(instance)
  end
end
