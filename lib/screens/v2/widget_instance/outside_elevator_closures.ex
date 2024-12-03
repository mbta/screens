defmodule Screens.V2.WidgetInstance.OutsideElevatorClosures do
  @moduledoc false

  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.CurrentElevatorClosed.Closure
  alias ScreensConfig.V2.Elevator

  defstruct ~w[app_params in_station_closures other_stations_with_closures]a

  @type t :: %__MODULE__{
          app_params: Elevator.t(),
          in_station_closures: list(Closure.t()),
          other_stations_with_closures: list(__MODULE__.Station.t())
        }

  defmodule Station do
    @moduledoc false

    alias Screens.Routes.Route
    alias Screens.V2.WidgetInstance.CurrentElevatorClosed.Closure

    @derive Jason.Encoder

    defstruct ~w[id name route_icons closures]a

    @type t :: %__MODULE__{
            id: Stop.id(),
            name: String.t(),
            route_icons: list(Route.icon()),
            closures: list(Closure.t())
          }
  end

  def serialize(%__MODULE__{
        app_params: %Elevator{elevator_id: id},
        in_station_closures: in_station_closures,
        other_stations_with_closures: other_stations_with_closures
      }),
      do: %{
        id: id,
        in_station_closures: in_station_closures,
        other_stations_with_closures: other_stations_with_closures
      }

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.OutsideElevatorClosures

    def priority(_instance), do: [1]
    def serialize(instance), do: OutsideElevatorClosures.serialize(instance)
    def slot_names(_instance), do: [:main_content]
    def widget_type(_instance), do: :outside_elevator_closures
    def valid_candidate?(_instance), do: true
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: [0]
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.OutsideElevatorClosuresView
  end
end
