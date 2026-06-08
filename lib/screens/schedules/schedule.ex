defmodule Screens.Schedules.Schedule do
  @moduledoc false

  alias Screens.Trips.Trip
  alias Screens.Util
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

  @type result :: {:ok, [t()]} | :error
  @type fetch_with_date :: (Departure.params(), Date.t() -> result())

  @callback fetch(Departure.params()) :: result()
  @callback fetch(Departure.params(), Date.t()) :: result()
  def fetch(%{} = params, date \\ current_service_date()) do
    params = Map.put(params, :date, date)
    result = Departure.do_fetch("schedules", Map.put(params, :include, @includes))

    case result do
      {:ok, schedules} -> {:ok, Enum.reject(schedules, &is_nil(&1.departure_time))}
      :error -> :error
    end
  end

  @spec headsign(t()) :: String.t()
  def headsign(%__MODULE__{stop_headsign: headsign}) when not is_nil(headsign), do: headsign
  def headsign(%__MODULE__{trip: %Trip{headsign: headsign}}), do: headsign

  @spec time(t()) :: DateTime.t() | nil
  def time(%__MODULE__{arrival_time: arrival, departure_time: departure}),
    do: arrival || departure

  defp current_service_date(now \\ DateTime.utc_now()), do: Util.service_date(now)
end
