defmodule Screens.V2.WidgetInstance.CurrentElevatorClosed do
  @moduledoc false

  alias Screens.Util.Assets
  alias ScreensConfig.V2.Elevator

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
    alias Screens.V2.WidgetInstance.CurrentElevatorClosed

    def priority(_instance), do: [1]
    def serialize(instance), do: CurrentElevatorClosed.serialize(instance)
    def slot_names(_instance), do: [:main_content]
    def widget_type(_instance), do: :current_elevator_closed
    def valid_candidate?(_instance), do: true
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: [0]
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.CurrentElevatorClosedView
  end
end
