defmodule Screens.Predictions.Prediction do
  @moduledoc false

  defstruct id: nil,
            trip: nil,
            stop: nil,
            route: nil,
            time: nil

  @type t :: %__MODULE__{
          id: String.t(),
          trip: Screens.Trips.Trip.t() | nil,
          stop: Screens.Stops.Stop.t(),
          route: Screens.Routes.Route.t(),
          time: DateTime.t()
        }

  def by_stop_id(stop_id) do
    case Screens.V3Api.get_json("predictions", %{
           "filter[stop]" => stop_id,
           "sort" => "departure_time",
           "include" => "route,stop,trip"
         }) do
      {:ok, result} -> {:ok, Screens.Predictions.Parser.parse_result(result)}
      _ -> :error
    end
  end
end
