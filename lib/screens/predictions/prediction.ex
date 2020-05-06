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

  def fetch(query_params) do
    default_params = %{"sort" => "departure_time", "include" => "route,stop,trip"}

    api_query_params =
      query_params |> Enum.map(&format_query_param/1) |> Enum.into(default_params)

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

  @doc """
  Chooses the "preferred prediction" from multiple predictions in cases of combined routes.

  The parts of a prediction that this function is concerned with are:

      prediction
        |- id
        |- route
        |    |- id
        |- trip
             |- route id

  For any set of predictions with the same ID, they will also share the same trip, but will have differing routes.
  This function finds and chooses the prediction whose route ID equals its trip's route ID.

  For buses, that prediction will always be the "slashed" route, e.g. 24/27.
  """
  @spec deduplicate_combined_routes([t()]) :: [t()]
  def deduplicate_combined_routes(predictions) do
    predictions
    |> Enum.group_by(& &1.id)
    |> Enum.map(fn
      {_id, [single_prediction]} ->
        single_prediction

      {_id, grouped_predictions} ->
        Enum.find(
          grouped_predictions,
          &(&1.route.id == &1.trip.route_id)
        )
    end)
    |> Enum.sort_by(& &1.departure_time)
  end
end
