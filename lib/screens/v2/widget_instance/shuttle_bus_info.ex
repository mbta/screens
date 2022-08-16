defmodule Screens.V2.WidgetInstance.ShuttleBusInfo do
  @moduledoc false

  alias Screens.Config.Screen
  alias Screens.Config.V2.ShuttleBusInfo

  @enforce_keys ~w[screen]a
  defstruct screen: nil

  @type t :: %__MODULE__{
          screen: Screen.t()
        }

  def priority(%__MODULE__{screen: %Screen{app_params: %ShuttleBusInfo{priority: priority}}}),
    do: priority

  def serialize(%__MODULE__{
        screen: %Screen{
          app_params: %ShuttleBusInfo{
            minutes_range_to_destination: minutes_range_to_destination,
            destination: destination,
            arrow: arrow
          }
        }
      }),
      do: %{
        minutes_range_to_destination: minutes_range_to_destination,
        destination: destination,
        arrow: arrow
      }

  def widget_type(_instance), do: :shuttle_bus_info

  def valid_candidate?(%__MODULE__{screen: %Screen{app_id: :pre_fare_v2}}), do: true
  def valid_candidate?(_), do: false

  def slot_names(_instance), do: [:tbd]

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.ShuttleBusInfo

    def priority(instance), do: ShuttleBusInfo.priority(instance)
    def serialize(instance), do: ShuttleBusInfo.serialize(instance)
    def slot_names(instance), do: ShuttleBusInfo.slot_names(instance)
    def widget_type(instance), do: ShuttleBusInfo.widget_type(instance)
    def valid_candidate?(instance), do: ShuttleBusInfo.valid_candidate?(instance)
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: [0]
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.ShuttleBusInfoView
  end
end
