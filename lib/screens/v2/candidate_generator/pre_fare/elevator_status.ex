defmodule Screens.V2.CandidateGenerator.PreFare.ElevatorStatus do
  @moduledoc "Generates the Pre-Fare Elevator Status widget."

  alias Screens.Alerts.Alert
  alias Screens.Elevator.Closure
  alias Screens.V2.WidgetInstance.ElevatorStatusNew, as: ElevatorWidget
  alias ScreensConfig.Screen

  import Screens.Inject
  @alert injected(Alert)

  @spec instances(Screen.t(), DateTime.t()) :: [ElevatorWidget.t()]
  def instances(
        %Screen{
          app_params: %Screen.PreFare{
            elevator_status: %ScreensConfig.ElevatorStatus{parent_station_id: station_id}
          }
        },
        _now
      ) do
    {:ok, alerts} = @alert.fetch(activities: [:using_wheelchair], include_all?: true)

    active_closures =
      alerts
      |> Enum.filter(&Alert.happening_now?/1)
      |> Enum.flat_map(fn alert ->
        case Closure.from_alert(alert) do
          {:ok, closure} -> [closure]
          :error -> []
        end
      end)

    [%ElevatorWidget{closures: active_closures, station_id: station_id}]
  end
end
