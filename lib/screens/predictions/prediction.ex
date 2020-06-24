defmodule Screens.Predictions.Prediction do
  @moduledoc false

  defstruct id: nil,
            trip: nil,
            stop: nil,
            route: nil,
            vehicle: nil,
            alerts: [],
            arrival_time: nil,
            departure_time: nil,
            stop_headsign: nil

  @type t :: %__MODULE__{
          id: String.t(),
          trip: Screens.Trips.Trip.t() | nil,
          stop: Screens.Stops.Stop.t(),
          route: Screens.Routes.Route.t(),
          vehicle: Screens.Vehicles.Vehicle.t(),
          alerts: list(Screens.Alerts.Alert.t()),
          arrival_time: DateTime.t() | nil,
          departure_time: DateTime.t() | nil,
          stop_headsign: String.t() | nil
        }

  def fetch(query_params) do
    Screens.Departures.Departure.do_query_and_parse(
      Map.put(query_params, :include, ~w[route stop trip vehicle alerts]),
      "predictions",
      Screens.Predictions.Parser
    )
  end
end
