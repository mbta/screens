defmodule Screens.Schedules.Schedule do
  @moduledoc false
  alias Screens.Departures.Departure

  defstruct id: nil,
            trip: nil,
            stop: nil,
            route: nil,
            trip_id: nil,
            arrival_time: nil,
            departure_time: nil,
            stop_headsign: nil

  @type t :: %__MODULE__{
          id: String.t(),
          trip: Screens.Trips.Trip.t() | nil,
          stop: Screens.Stops.Stop.t(),
          route: Screens.Routes.Route.t(),
          arrival_time: DateTime.t() | nil,
          departure_time: DateTime.t() | nil,
          stop_headsign: String.t() | nil
        }

  @spec fetch(Departure.query_params()) :: {:ok, list(t())} | :error
  def fetch(%{} = query_params, date \\ nil) do
    extra_params = if is_nil(date), do: %{}, else: %{date: date}

    Departure.do_query_and_parse(
      query_params,
      "schedules",
      Screens.Schedules.Parser,
      extra_params
    )
  end
end
