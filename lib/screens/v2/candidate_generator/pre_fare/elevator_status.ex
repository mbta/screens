defmodule Screens.V2.CandidateGenerator.PreFare.ElevatorStatus do
  @moduledoc "Generates the Pre-Fare Elevator Status widget."

  alias Screens.Alerts.Alert
  alias Screens.Elevator.Closure
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.V2.WidgetInstance.ElevatorStatus, as: ElevatorWidget
  alias ScreensConfig.Screen

  import Screens.Inject
  @alert injected(Alert)
  @route_pattern injected(RoutePattern)

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

    relevant_station_ids =
      case @route_pattern.fetch(%{canonical?: true, stop_ids: [station_id]}) do
        {:ok, patterns} ->
          patterns |> Enum.filter(&subway_route?/1) |> Enum.flat_map(&station_ids/1)

        :error ->
          []
      end

    [
      %ElevatorWidget{
        closures: active_closures,
        home_station_id: station_id,
        relevant_station_ids: MapSet.new(relevant_station_ids)
      }
    ]
  end

  defp station_ids(%RoutePattern{stops: stops}) do
    stops |> Enum.map(& &1.parent_station) |> Enum.reject(&is_nil/1) |> Enum.map(& &1.id)
  end

  defp subway_route?(%RoutePattern{route: %Route{type: type}}),
    do: type in ~w[light_rail subway]a
end
