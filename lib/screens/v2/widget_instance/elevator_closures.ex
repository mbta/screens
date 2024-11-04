defmodule Screens.V2.WidgetInstance.ElevatorClosures do
  @moduledoc false

  defstruct ~w[id in_station_alerts outside_alerts]a

  @type t :: %__MODULE__{
          id: String.t(),
          in_station_alerts: list(__MODULE__.Alert.t()),
          outside_alerts: list(__MODULE__.Alert.t())
        }

  defmodule Alert do
    @moduledoc false

    defstruct ~w[station_name routes alert_id elevator_name elevator_id description header_text]a

    @type t :: %__MODULE__{
            station_name: String.t(),
            routes: list(String.t()),
            alert_id: String.t(),
            elevator_name: String.t(),
            elevator_id: String.t(),
            description: String.t(),
            header_text: String.t()
          }
  end

  def serialize(t), do: t

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.ElevatorClosures

    def priority(_instance), do: [1]
    def serialize(instance), do: ElevatorClosures.serialize(instance)
    def slot_names(_instance), do: [:main_content]
    def widget_type(_instance), do: :elevator_closures
    def valid_candidate?(_instance), do: true
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: [0]
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.ElevatorClosuresView
  end
end
