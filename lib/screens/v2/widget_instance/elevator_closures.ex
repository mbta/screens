defmodule Screens.V2.WidgetInstance.ElevatorClosures do
  @moduledoc false

  alias Screens.Stops.Stop
  alias Screens.Util.Assets
  alias ScreensConfig.V2.Elevator

  defstruct ~w[app_params in_station_closures other_stations_with_closures]a

  @type t :: %__MODULE__{
          app_params: Elevator.t(),
          in_station_closures: list(__MODULE__.Closure.t()),
          other_stations_with_closures: list(__MODULE__.Station.t())
        }

  defmodule Station do
    @moduledoc false

    alias Screens.Routes.Route
    alias Screens.V2.WidgetInstance.ElevatorClosures.Closure

    @derive Jason.Encoder

    defstruct ~w[id name route_icons closures]a

    @type t :: %__MODULE__{
            id: Stop.id(),
            name: String.t(),
            route_icons: list(Route.icon()),
            closures: list(Closure.t())
          }
  end

  defmodule Closure do
    @moduledoc false

    @derive Jason.Encoder

    defstruct ~w[id elevator_name elevator_id description header_text]a

    @type t :: %__MODULE__{
            id: String.t(),
            elevator_name: String.t(),
            elevator_id: String.t(),
            description: String.t(),
            header_text: String.t()
          }
  end

  def serialize(%__MODULE__{
        app_params: %Elevator{
          elevator_id: id,
          alternate_direction_text: alternate_direction_text,
          accessible_path_direction_arrow: accessible_path_direction_arrow,
          accessible_path_image_url: accessible_path_image_url,
          accessible_path_image_here_coordinates: accessible_path_image_here_coordinates
        },
        in_station_closures: in_station_closures,
        other_stations_with_closures: other_stations_with_closures
      }),
      do: %{
        id: id,
        in_station_closures: in_station_closures,
        other_stations_with_closures: other_stations_with_closures,
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
