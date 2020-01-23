defmodule Screens.Schedules.Schedule do
  @moduledoc false

  defstruct id: nil,
            trip: nil,
            route: nil,
            time: nil

  @type t :: %__MODULE__{
          id: String.t(),
          trip: Screens.Trips.Trip.t() | nil,
          route: Screens.Routes.Route.t(),
          time: DateTime.t()
        }

  def by_stop_id(stop_id) do
    with {:ok, result} <-
           Screens.V3Api.get_json("schedules", %{
             "filter[stop]" => stop_id,
             "sort" => "departure_time",
             "include" => "trip,route"
           }) do
      Screens.Schedules.Parser.parse_result(result)
    end
  end
end
