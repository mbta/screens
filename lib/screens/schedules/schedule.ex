defmodule Screens.Schedules.Schedule do
  @moduledoc false

  defstruct id: nil,
            trip: nil,
            stop: nil,
            route: nil,
            trip_id: nil,
            arrival_time: nil,
            departure_time: nil

  @type t :: %__MODULE__{
          id: String.t(),
          trip: Screens.Trips.Trip.t() | nil,
          stop: Screens.Stops.Stop.t(),
          route: Screens.Routes.Route.t(),
          arrival_time: DateTime.t() | nil,
          departure_time: DateTime.t() | nil
        }

  def fetch(query_params) do
    Screens.Departures.Departure.do_query_and_parse(
      query_params,
      "schedules",
      Screens.Schedules.Parser
    )
  end
end
