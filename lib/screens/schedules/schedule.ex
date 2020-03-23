defmodule Screens.Schedules.Schedule do
  @moduledoc false

  defstruct id: nil,
            time: nil,
            trip_id: nil

  @type t :: %__MODULE__{
          id: String.t(),
          time: DateTime.t(),
          trip_id: Screens.Trips.Trip.id()
        }

  def by_stop_id(stop_id, route_id) do
    case Screens.V3Api.get_json("schedules", %{
           "filter[stop]" => stop_id,
           "filter[route]" => route_id,
           "sort" => "departure_time"
         }) do
      {:ok, result} -> {:ok, Screens.Schedules.Parser.parse_result(result)}
      _ -> :error
    end
  end
end
