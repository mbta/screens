defmodule Screens.RoutePatterns.RoutePattern do
  @moduledoc false

  alias Screens.RoutePatterns.{Parser, RouteDirectionStops}
  alias Screens.Routes.Route
  alias Screens.RouteType
  alias Screens.Stops.Stop
  alias Screens.Trips.Trip
  alias Screens.V3Api

  defstruct ~w[id canonical? direction_id typicality route stops]a

  @type id :: String.t()
  @type typicality :: 1 | 2 | 3 | 4 | 5

  @type t :: %__MODULE__{
          id: id(),
          canonical?: boolean(),
          direction_id: Trip.direction(),
          typicality: typicality(),
          route: Route.t(),
          stops: [Stop.t()]
        }

  @type params :: %{
          optional(:canonical?) => boolean(),
          optional(:date) => Date.t(),
          optional(:direction_id) => Trip.direction() | :both,
          optional(:ids) => [id()],
          optional(:route_ids) => [Route.id()],
          optional(:route_type) => RouteType.t(),
          optional(:stop_ids) => [Stop.id()],
          optional(:typicality) => typicality()
        }

  @callback fetch(params()) :: {:ok, [t()]} | :error
  def fetch(params, get_json_fn \\ &V3Api.get_json/2) do
    # The API doesn't currently have some of these filters built-in
    {filter_params, fetch_params} = Map.split(params, ~w[route_type typicality]a)

    encoded_params =
      fetch_params
      |> Enum.flat_map(&encode_param/1)
      |> Map.new()
      |> Map.put("include", Enum.join(~w[route representative_trip.stops], ","))

    case get_json_fn.("route_patterns", encoded_params) do
      {:ok, response} ->
        {:ok, Enum.reduce(filter_params, Parser.parse(response), &apply_filter/2)}

      _ ->
        :error
    end
  end

  defp apply_filter({:route_type, type}, patterns),
    do: Enum.filter(patterns, &(&1.route.type == type))

  defp apply_filter({:typicality, typicality}, patterns),
    do: Enum.filter(patterns, &(&1.typicality == typicality))

  defp encode_param({:ids, ids}), do: [{"filter[id]", Enum.join(ids, ",")}]
  defp encode_param({:route_ids, ids}), do: [{"filter[route]", Enum.join(ids, ",")}]
  defp encode_param({:direction_id, :both}), do: []
  defp encode_param({:direction_id, id}), do: [{"filter[direction_id]", to_string(id)}]
  defp encode_param({:stop_ids, ids}), do: [{"filter[stop]", Enum.join(ids, ",")}]
  defp encode_param({:canonical?, canonical?}), do: [{"filter[canonical]", to_string(canonical?)}]
  defp encode_param({:date, date}), do: [{"filter[date]", Date.to_iso8601(date)}]

  @spec stops_by_route_and_direction(Route.id(), Trip.direction()) :: {:ok, [Stop.t()]} | :error
  def stops_by_route_and_direction(route_id, direction_id) do
    with {:ok, route_patterns} <-
           V3Api.get_json("route_patterns", %{
             "filter[route]" => route_id,
             "filter[direction_id]" => direction_id,
             "sort" => "typicality",
             "include" => "representative_trip.stops"
           }),
         parsed_result when parsed_result != :error <-
           RouteDirectionStops.parse_result(route_patterns, route_id) do
      {:ok, parsed_result}
    else
      _ -> :error
    end
  end

  @doc """
  Returns a map from route ID to a list of stop sequences of that route, for all
  routes serving stop, in all applicable directions.
  """
  @spec fetch_tagged_stop_sequences_through_stop(Stop.id()) ::
          {:ok, %{Route.id() => list(list(Stop.id()))}} | :error
  def fetch_tagged_stop_sequences_through_stop(
        stop_id,
        route_filters \\ [],
        get_json_fn \\ &V3Api.get_json/2
      ) do
    params = %{
      "include" => "representative_trip.stops,route",
      "filter[stop]" => stop_id
    }

    params =
      if length(route_filters) > 0,
        do: Map.put(params, "filter[route]", Enum.join(route_filters, ",")),
        else: params

    case get_json_fn.("route_patterns", params) do
      {:ok, result} ->
        {:ok, get_tagged_stop_sequences_from_result(result)}

      _ ->
        :error
    end
  end

  @doc """
  Returns a map from route ID to a list of stop sequences of that route. Stop sequences
  are described in terms of parent station IDs, not platform IDs.

  Pass `true` for `canonical_only?` to limit results to canonical route patterns.
  With `canonical_only? = true`,
  - For most routes (everything but Red Line), only one stop sequence will be in the list.
  - For Red Line, the list will contain one stop sequence for the Ashmont branch and one for the Braintree branch.

  Pass `false` for `canonical_only?` to limit results to *non-canonical* route patterns. (You probably don't want to do this!)

  If no parent station data exists, platform_id is returned instead.
  Only stop sequences for direction ID 0 are returned.
  Assumes that all stop sequences in result are platforms.
  """
  @spec fetch_tagged_parent_station_sequences_through_stop(Stop.id(), list(String.t())) ::
          {:ok, %{Route.id() => list(list(Stop.id()))}} | :error
  def fetch_tagged_parent_station_sequences_through_stop(
        stop_id,
        route_filters,
        canonical_only? \\ nil,
        get_json_fn \\ &V3Api.get_json/2
      ) do
    params = %{
      "include" => "representative_trip.stops,route",
      "filter[stop]" => stop_id,
      "filter[direction_id]" => 0,
      "filter[route]" => Enum.join(route_filters, ",")
    }

    params =
      if is_boolean(canonical_only?),
        do: Map.put(params, "filter[canonical]", canonical_only?),
        else: params

    case get_json_fn.("route_patterns", params) do
      {:ok, %{"data" => []}} ->
        :error

      {:ok, result} ->
        {:ok, get_tagged_parent_station_sequences_from_result(result)}

      _ ->
        :error
    end
  end

  @doc """
  Given a map from route ID to stop sequences of that route, returns a flat list
  of all of the stop sequences.

  ```
  iex> untag_stop_sequences(%{"route1" => [sequence1, sequence2], "route2" => [sequence3]})
  [sequence1, sequence2, sequence3]
  ```
  """
  @spec untag_stop_sequences(%{Route.id() => list(list(Stop.id()))}) :: list(list(Stop.id()))
  def untag_stop_sequences(tagged_stop_sequences) do
    Enum.flat_map(tagged_stop_sequences, &elem(&1, 1))
  end

  defp get_tagged_stop_sequences_from_result(result) do
    result["included"]
    |> Enum.filter(&(&1["type"] == "trip"))
    |> Enum.map(fn trip ->
      route = trip["relationships"]["route"]["data"]["id"]
      sequence = Enum.map(trip["relationships"]["stops"]["data"], & &1["id"])

      {route, sequence}
    end)
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
  end

  defp get_platform_to_station_map_from_result(result) do
    result
    |> get_in([
      "included",
      Access.filter(&(&1["type"] == "stop"))
    ])
    |> Enum.map(fn %{
                     "relationships" => %{
                       "parent_station" => %{"data" => parent_station_data}
                     },
                     "id" => platform_id
                   } ->
      if parent_station_data,
        do: {platform_id, parent_station_data["id"]},
        else: {platform_id, platform_id}
    end)
    |> Enum.into(%{})
  end

  defp get_tagged_parent_station_sequences_from_result(result) do
    platform_to_station_map = get_platform_to_station_map_from_result(result)

    result
    |> get_tagged_stop_sequences_from_result()
    |> Map.new(fn {route_id, stop_sequences} ->
      station_sequences =
        stop_sequences
        |> Enum.map(&platforms_to_stations(&1, platform_to_station_map))
        # Dedup the stop sequences (both directions are listed, but we only need 1)
        |> Enum.uniq_by(&MapSet.new/1)

      {route_id, station_sequences}
    end)
  end

  defp platforms_to_stations(stop_sequence, platform_to_station_map) do
    Enum.map(stop_sequence, &Map.fetch!(platform_to_station_map, &1))
  end
end
