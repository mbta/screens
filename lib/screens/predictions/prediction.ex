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

  defp format_query_param({:direction_id, direction_id}) do
    {"filter[direction_id]", direction_id}
  end

  def departure_in_past(%{departure_time: departure_time}) do
    DateTime.compare(departure_time, DateTime.utc_now()) == :lt
  end

  @doc """
  Predictions for combined bus routes, e.g. 24/27, are duplicated as 3 separate predictions:
  one each for 24, 27, and 24/27; all with the same route ID.
  This finds those cases and keeps only the combined prediction--24/27 in our example.
  """
  def deduplicate_slashed_routes(predictions) do
    predictions
    |> Enum.group_by(& &1.id)
    |> Enum.map(fn
      {_id, [prediction]} -> prediction
      {_id, predictions} -> predictions |> Enum.find(hd(predictions), &String.contains?(&1.route.short_name, "/"))
    end)
    |> Enum.sort_by(& &1.departure_time)
  end
end
