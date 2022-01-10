defmodule Screens.V2.WidgetInstance.ElevatorStatus do
  @moduledoc false

  alias Screens.Alerts.Alert

  defstruct screen: nil,
            now: nil,
            alerts: nil

  @type t :: %__MODULE__{
          screen: Screens.Config.Screen.t(),
          now: DateTime.t(),
          alerts: list(Alert.t())
        }

  # @max_height_list_container 0
  # @max_height_station_heading 0
  # @max_height_elevator_description 0
  # @max_height_row_separator 0

  # defp get_active_at_home_station(_alerts) do
  # end

  # defp get_active_elsewhere(_alerts) do
  # end

  # defp get_upcoming_at_home_station(_alerts) do
  # end

  # defp get_upcoming_on_connecting_lines(_alerts) do
  # end

  defimpl Screens.V2.WidgetInstance do
    def priority(_instance), do: [2]

    def serialize(_instance), do: %{}

    def slot_names(_instance), do: [:main_content_right]

    def widget_type(_instance), do: :elevator_status

    def valid_candidate?(_instance), do: true

    def audio_serialize(_instance), do: %{}

    def audio_sort_key(_instance), do: 0

    def audio_valid_candidate?(_instance), do: false

    def audio_view(_instance), do: ScreensWeb.V2.Audio.ElevatorStatusView
  end
end
