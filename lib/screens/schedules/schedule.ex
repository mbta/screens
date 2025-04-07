defmodule Screens.Schedules.Schedule do
  @moduledoc false

  alias Screens.Trips.Trip
  alias Screens.V2.Departure

  defstruct id: nil,
            trip: nil,
            stop: nil,
            route: nil,
            trip_id: nil,
            arrival_time: nil,
            departure_time: nil,
            stop_headsign: nil,
            track_number: nil,
            direction_id: nil

  @type t :: %__MODULE__{
          id: String.t(),
          trip: Screens.Trips.Trip.t(),
          stop: Screens.Stops.Stop.t(),
          route: Screens.Routes.Route.t(),
          arrival_time: DateTime.t() | nil,
          departure_time: DateTime.t() | nil,
          stop_headsign: String.t() | nil,
          track_number: String.t() | nil,
          direction_id: Trip.direction()
        }

  @includes ~w[route.line stop trip.route_pattern.representative_trip trip.stops]

  @spec fetch(Departure.params()) :: {:ok, list(t())} | :error
  @spec fetch(Departure.params(), DateTime.t() | Date.t() | String.t() | nil) ::
          {:ok, list(t())} | :error
  def fetch(%{} = params, date \\ nil) do
    params = if is_nil(date), do: params, else: Map.put(params, :date, date)

    schedules =
      Departure.do_fetch(
        "schedules",
        Map.put(params, :include, @includes),
        Screens.Schedules.Parser
      )

    case schedules do
      {:ok, result} -> {:ok, Enum.reject(result, &is_nil(&1.departure_time))}
      :error -> :error
    end
  end
end
