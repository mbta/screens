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

  def fetch(query_params) do
    default_params = %{"sort" => "departure_time", "include" => "route,stop,trip"}

    api_query_params =
      query_params |> Enum.map(&format_query_param/1) |> Enum.into(default_params)

    case Screens.V3Api.get_json("schedules", api_query_params) do
      {:ok, result} -> {:ok, Screens.Schedules.Parser.parse_result(result)}
      _ -> :error
    end
  end

  defp format_query_param({:stop_id, stop_id}) do
    {"filter[stop]", stop_id}
  end

  defp format_query_param({:stop_ids, stop_ids}) do
    {"filter[stop]", Enum.join(stop_ids, ",")}
  end

  defp format_query_param({:route_id, route_id}) do
    {"filter[route]", route_id}
  end

  defp format_query_param({:route_ids, route_ids}) do
    {"filter[route]", Enum.join(route_ids, ",")}
  end

  defp format_query_param({:direction_id, direction_id}) do
    {"filter[direction_id]", direction_id}
  end
end
