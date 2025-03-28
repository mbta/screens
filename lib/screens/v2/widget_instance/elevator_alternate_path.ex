defmodule Screens.V2.WidgetInstance.ElevatorAlternatePath do
  @moduledoc "The main content of an elevator screen when its associated elevator is closed."

  alias Screens.Util.Assets
  alias ScreensConfig.Screen.Elevator

  defstruct ~w[app_params]a

  @type t :: %__MODULE__{app_params: Elevator.t()}

  def serialize(%__MODULE__{
        app_params: %Elevator{
          alternate_direction_text: alternate_direction_text,
          accessible_path_direction_arrow: accessible_path_direction_arrow,
          accessible_path_image_url: accessible_path_image_url,
          accessible_path_image_here_coordinates: accessible_path_image_here_coordinates
        }
      }),
      do: %{
        alternate_direction_text: alternate_direction_text,
        accessible_path_direction_arrow: accessible_path_direction_arrow,
        accessible_path_image_url:
          if(is_nil(accessible_path_image_url),
            do: nil,
            else: Assets.s3_asset_url(accessible_path_image_url)
          ),
        accessible_path_image_here_coordinates: accessible_path_image_here_coordinates
      }

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.ElevatorAlternatePath

    def priority(_instance), do: [1]
    def serialize(instance), do: ElevatorAlternatePath.serialize(instance)
    def slot_names(_instance), do: [:main_content]
    def widget_type(_instance), do: :elevator_alternate_path
    def valid_candidate?(_instance), do: true
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: [0]
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.ElevatorAlternatePathView
  end
end
