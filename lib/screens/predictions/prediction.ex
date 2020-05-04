defmodule Screens.Predictions.Prediction do
  @moduledoc false

  defstruct id: nil,
            trip: nil,
            stop: nil,
            route: nil,
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

  def by_stop_id(stop_id, route_id, direction_id) do
    case Screens.V3Api.get_json("predictions", %{
           "filter[stop]" => stop_id,
           "filter[route]" => route_id,
           "filter[direction_id]" => direction_id,
           "sort" => "departure_time",
           "include" => "route,stop,trip"
         }) do
      {:ok, result} -> {:ok, Screens.Predictions.Parser.parse_result(result)}
      _ -> :error
    end
  end

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

  def fetch(opts) do
    default_params = %{"sort" => "departure_time", "include" => "route,stop,trip"}
    api_query_params = opts |> Enum.map(&format_query_param/1) |> Enum.into(default_params)

    case Screens.V3Api.get_json("predictions", api_query_params) do
      {:ok, result} -> {:ok, Screens.Predictions.Parser.parse_result(result)}
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

  def departure_in_past(%{departure_time: departure_time}) do
    DateTime.compare(departure_time, DateTime.utc_now()) == :lt
  end
end
