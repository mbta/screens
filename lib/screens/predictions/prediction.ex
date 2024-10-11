defmodule Screens.Predictions.Prediction do
  @moduledoc false

  alias Screens.Departures.Departure
  alias Screens.Predictions.ScheduleRelationship
  alias Screens.Vehicles.Vehicle

  defstruct id: nil,
            trip: nil,
            stop: nil,
            route: nil,
            vehicle: nil,
            alerts: [],
            arrival_time: nil,
            departure_time: nil,
            stop_headsign: nil,
            track_number: nil,
            schedule_relationship: :scheduled

  @type t :: %__MODULE__{
          id: String.t(),
          trip: Screens.Trips.Trip.t(),
          stop: Screens.Stops.Stop.t(),
          route: Screens.Routes.Route.t(),
          vehicle: Screens.Vehicles.Vehicle.t() | nil,
          alerts: list(Screens.Alerts.Alert.t()),
          arrival_time: DateTime.t() | nil,
          departure_time: DateTime.t() | nil,
          stop_headsign: String.t() | nil,
          track_number: String.t() | nil,
          schedule_relationship: ScheduleRelationship.t()
        }

  @spec fetch(Departure.query_params()) :: {:ok, list(t())} | :error
  def fetch(%{} = query_params) do
    predictions =
      Departure.do_query_and_parse(
        query_params,
        "predictions",
        Screens.Predictions.Parser,
        %{include: ~w[alerts route.line stop trip.stops vehicle]}
      )

    case predictions do
      {:ok, result} -> {:ok, Enum.reject(result, &is_nil(&1.departure_time))}
      :error -> :error
    end
  end

  def stop_for_vehicle(%__MODULE__{vehicle: %Vehicle{stop_id: stop_id}}), do: stop_id
  def stop_for_vehicle(_), do: nil

  def vehicle_status(%__MODULE__{vehicle: %Vehicle{current_status: current_status}}),
    do: current_status

  def vehicle_status(_), do: nil
end
