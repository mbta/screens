defmodule Screens.V2.WidgetInstance.ElevatorClosures do
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Elevator
  alias Screens.Alerts.Alert

  defstruct screen: nil,
            alerts: nil

  @type t :: %__MODULE__{
          screen: Screen.t(),
          alerts: list(Alert.t())
        }

  def serialize(%__MODULE__{screen: %Screen{app_params: %Elevator{elevator_id: id}}}) do
    %{id: id, alerts: []}
  end

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
