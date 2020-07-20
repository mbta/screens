defmodule Screens.Predictions.Prediction do
  @moduledoc false

  alias Screens.Config.Query.Params

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

  @spec fetch(Params.t()) :: {:ok, list(t())} | :error
  def fetch(%Params{} = query_params) do
    Screens.Departures.Departure.do_query_and_parse(
      query_params,
      "predictions",
      Screens.Predictions.Parser,
      %{include: ~w[route stop trip vehicle alerts]}
    )
  end
end
