defmodule Screens.V2.WidgetInstance.ElevatorClosuresList do
  @moduledoc false

  alias Screens.Stops.Stop
  alias Screens.V2.WidgetInstance.Elevator.Closure
  alias ScreensConfig.V2.Elevator

  defstruct ~w[app_params in_station_closures other_stations_with_closures station_id]a

  @type t :: %__MODULE__{
          app_params: Elevator.t(),
          in_station_closures: list(Closure.t()),
          other_stations_with_closures: list(__MODULE__.Station.t()),
          station_id: String.t()
        }

  defmodule Station do
    @moduledoc false

    alias Screens.Routes.Route
    alias Screens.V2.WidgetInstance.Elevator.Closure

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
        other_stations_with_closures: other_stations_with_closures,
        station_id: station_id
      }),
      do: %{
        id: id,
        in_station_closures: in_station_closures,
        other_stations_with_closures: other_stations_with_closures,
        station_id: station_id
      }

  defimpl Screens.V2.WidgetInstance do
    alias Screens.V2.WidgetInstance.ElevatorClosuresList

    def priority(_instance), do: [1]
    def serialize(instance), do: ElevatorClosuresList.serialize(instance)
    def slot_names(_instance), do: [:main_content]
    def widget_type(_instance), do: :elevator_closures_list
    def valid_candidate?(_instance), do: true
    def audio_serialize(_instance), do: %{}
    def audio_sort_key(_instance), do: [0]
    def audio_valid_candidate?(_instance), do: false
    def audio_view(_instance), do: ScreensWeb.V2.Audio.ElevatorClosuresListView
  end
end
