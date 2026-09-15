defmodule Screens.RoutePatterns.RoutePattern do
  @moduledoc false

  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V3Api
  alias ScreensConfig.Departures.Mode

  defstruct ~w[id canonical? direction_id typicality route headsign stops]a

  @type id :: String.t()
  @type typicality :: 1 | 2 | 3 | 4 | 5

  @type t :: %__MODULE__{
          id: id(),
          canonical?: boolean(),
          direction_id: Trip.direction(),
          typicality: typicality(),
          route: Route.t(),
          headsign: String.t(),
          stops: [Stop.t()]
        }

  @type result :: {:ok, [t()]} | :error
  @type params :: %{
          optional(:canonical?) => boolean(),
          optional(:date) => Date.t(),
          optional(:direction_id) => Trip.direction() | :both,
          optional(:ids) => [id()],
          optional(:mode) => Mode.t(),
          optional(:route_ids) => [Route.id()],
          optional(:stop_ids) => [Stop.id()],
          optional(:typicality) => typicality()
        }

  @callback fetch(params()) :: result()
  def fetch(params, get_json_fn \\ &V3Api.get_json/2) do
    # The API doesn't currently have some of these filters built-in
    {filter_params, fetch_params} = Map.split(params, ~w[mode typicality]a)

    encoded_params =
      fetch_params
      |> Enum.flat_map(&encode_param/1)
      |> Map.new()
      |> Map.put(
        "include",
        Enum.join(~w[route.line representative_trip.stops.parent_station], ",")
      )

    case get_json_fn.("route_patterns", encoded_params) do
      {:ok, response} ->
        {:ok,
         filter_params
         |> Enum.reduce(V3Api.Parser.parse(response), &apply_filter/2)
         |> refilter_by_route_ids(params[:route_ids])}

      _ ->
        :error
    end
  end

  defp apply_filter({:mode, nil}, patterns), do: patterns

  defp apply_filter({:mode, mode}, patterns),
    do: Enum.filter(patterns, &(&1.route.type == Mode.to_route_type(mode)))

  defp apply_filter({:typicality, typicality}, patterns),
    do: Enum.filter(patterns, &(&1.typicality == typicality))

  defp encode_param({:ids, ids}), do: [{"filter[id]", Enum.join(ids, ",")}]
  defp encode_param({:route_ids, []}), do: []
  defp encode_param({:route_ids, ids}), do: [{"filter[route]", Enum.join(ids, ",")}]
  defp encode_param({:direction_id, :both}), do: []
  defp encode_param({:direction_id, id}), do: [{"filter[direction_id]", to_string(id)}]
  defp encode_param({:stop_ids, []}), do: []
  defp encode_param({:stop_ids, ids}), do: [{"filter[stop]", Enum.join(ids, ",")}]
  defp encode_param({:canonical?, canonical?}), do: [{"filter[canonical]", to_string(canonical?)}]
  defp encode_param({:date, date}), do: [{"filter[date]", Date.to_iso8601(date)}]

  # This endpoint sometimes returns patterns that don't match the specified route IDs due to a
  # legacy behavior involving multi-route trips, so if we want to "really" filter by route ID we
  # have to do it ourselves.
  defp refilter_by_route_ids(patterns, nil), do: patterns

  defp refilter_by_route_ids(patterns, route_ids) do
    route_ids = MapSet.new(route_ids)
    Enum.filter(patterns, &(&1.route.id in route_ids))
  end
end
