defmodule Screens.V2.CandidateGenerator.PreFare.ElevatorStatus do
  @moduledoc "Generates the Pre-Fare Elevator Status widget."

  alias Screens.V2.WidgetInstance.Placeholder
  alias ScreensConfig.Screen

  @spec instances(Screen.t(), DateTime.t()) :: [Placeholder.t()]
  def instances(
        %Screen{
          app_params: %Screen.PreFare{
            elevator_status: %ScreensConfig.ElevatorStatus{parent_station_id: parent_station_id}
          }
        },
        _now
      ) do
    [
      %Placeholder{
        color: :blue,
        text: "ElevatorStatus id=#{parent_station_id}",
        priority: [0],
        slot_names: [:lower_right]
      }
    ]
  end
end
