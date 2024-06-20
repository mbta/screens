#!/usr/bin/env -S ERL_FLAGS=+B elixir

Mix.install([
  {:jason, "~> 1.4"},
  {:hackney, "~> 1.13"},
  {:tesla, "~> 1.10"}
])

defmodule AddDUPHeadsignConfig do
  @moduledoc """
  Script to generate DUP alert headsign matchers.

  To add a new DUP alert headsign configuration:

    1. Determine the parent station ID
      - Searching for the station on dotcom and pulling this value from the URL is
          probably the easiest way to do this

    2. Determine which routes pass through the station and are included on the DUP
      - This might be provided already, otherwise you can see which lines pass
          through the station on dotcom aswell.


    4. Run this command for each route and merge the values into the
        `dup_alert_headsign_matchers` map in `config/config.exs`
      - (optional) Provide overrides for headsign text for one or both directions
          using the `--headsign_0` and/or `--headsign_1` options.


  ## Usage

      ./scripts/add_dup_headsign_config.exs --help

      ./scripts/add_dup_headsign_config.exs --parent-station <parent_station>
                                            --route <route_id>
                                           [--headsign_0 <direction_id 0 headsign override>]
                                           [--headsign_1 <direction_id 1 headsign override>]

  """
  defmodule V3Api do
    use Tesla

    adapter(Tesla.Adapter.Hackney)

    plug Tesla.Middleware.BaseUrl, "https://api-v3.mbta.com"
    plug Tesla.Middleware.JSON, decode_content_types: ["application/vnd.api+json"]
    plug Tesla.Middleware.Compression
    plug Tesla.Middleware.Logger, debug: false

    def canonical_route_patterns(opts) do
      stop = Keyword.fetch!(opts, :stop)
      routes = Keyword.fetch!(opts, :routes)

      {:ok, resp} =
        get("/route_patterns",
          query: [
            "filter[stop]": stop,
            "filter[route]": Enum.join(routes, ","),
            "filter[canonical]": true
          ]
        )

      resp.body["data"]
    end

    def trip(trip_id) do
      {:ok, resp} =
        get("/trips/#{trip_id}",
          query: [include: "stops"]
        )

      resp.body["data"]
    end

    def stop(stop_id) do
      {:ok, resp} = get("/stops/#{stop_id}", query: [include: "child_stops"])

      resp.body["data"]
    end
  end

  alias __MODULE__.V3Api

  @strict [
    help: :boolean,
    parent_station: :string,
    route: :string,
    headsign_0: :string,
    headsign_1: :string
  ]
  def main(argv) do
    {parsed, _} = OptionParser.parse!(argv, strict: @strict)
    parsed = Map.new(parsed)

    if parsed[:help] do
      help()
    else
      options_headsigns =
        parsed
        |> Map.take([:headsign_0, :headsign_1])
        |> Map.new(fn
          {:headsign_0, headsign} -> {0, [headsign]}
          {:headsign_1, headsign} -> {1, [headsign]}
        end)

      case parsed do
        %{parent_station: parent_station, route: route}
        when is_binary(parent_station) and is_binary(route) ->
          routes = expand_routes(route)

          %{
            child_stops: child_stops,
            representative_trips: representative_trips
          } = fetch_api_data(parent_station, routes)

          headsigns_by_direction =
            representative_trips
            |> get_headsigns_by_direction()
            |> Map.merge(options_headsigns)

          snippet =
            representative_trips
            |> walk_trips_for_neighboring_stop_ids(child_stops)
            |> build_dup_alert_headsign_matchers(headsigns_by_direction)
            |> to_snippet(parent_station)

          IO.puts("""
          Add the following to `config :screens, :dup_alert_headsign_matchers` in config/config.exs

          #{snippet}
          """)

        _ ->
          IO.puts("Invalid or incomplete arguments.")
          help()
          System.stop(1)
      end
    end

    :ok
  end

  defp help, do: IO.puts(@moduledoc)

  defp fetch_api_data(parent_station, routes) do
    %{"relationships" => %{"child_stops" => %{"data" => child_stops}}} =
      V3Api.stop(parent_station)

    canonical_route_patterns =
      V3Api.canonical_route_patterns(stop: parent_station, routes: routes)

    representative_trips =
      Enum.map(
        canonical_route_patterns,
        &V3Api.trip(&1["relationships"]["representative_trip"]["data"]["id"])
      )

    %{child_stops: child_stops, representative_trips: representative_trips}
  end

  defp get_headsigns_by_direction(representative_trips) do
    representative_trips
    |> Enum.group_by(& &1["attributes"]["direction_id"], & &1["attributes"]["headsign"])
    |> Enum.map(fn {direction_id, headsigns} -> {direction_id, Enum.uniq(headsigns)} end)
    |> Map.new()
  end

  defp walk_trips_for_neighboring_stop_ids(representative_trips, child_stops) do
    child_stop_ids = MapSet.new(child_stops, & &1["id"])

    representative_trips
    |> Enum.map(fn trip ->
      stop_ids = Enum.map(trip["relationships"]["stops"]["data"], & &1["id"])

      [{stop_before, _, stop_after}] =
        [stop_ids, Enum.drop(stop_ids, 1), Enum.drop(stop_ids, 2)]
        |> Enum.zip()
        |> Enum.filter(fn {_, stop_id, _} ->
          MapSet.member?(child_stop_ids, stop_id)
        end)

      {trip["attributes"]["direction_id"], stop_before, stop_after}
    end)
    |> Enum.uniq()
    |> Enum.group_by(&elem(&1, 0), &{elem(&1, 1), elem(&1, 2)})
  end

  defp build_dup_alert_headsign_matchers(stop_ids_by_direction_id, headsigns_by_direction) do
    stop_ids_by_direction_id
    |> Enum.map(fn {direction_id, informed_and_not_informed} ->
      {not_informed, informed} = Enum.unzip(informed_and_not_informed)

      %{
        informed: informed |> Enum.uniq() |> maybe_unwrap_stop_ids(),
        not_informed: not_informed |> Enum.uniq() |> maybe_unwrap_stop_ids(),
        alert_headsign: alert_headsign(direction_id, headsigns_by_direction),
        headway_headsign: headway_headsign(direction_id, headsigns_by_direction)
      }
    end)
  end

  defp to_snippet(dup_alert_headsign_matchers, parent_station) do
    ast =
      quote do
        %{unquote(parent_station) => unquote(dup_alert_headsign_matchers)}
      end

    ast
    |> Macro.to_string()
    |> Code.format_string!()
  end

  defp expand_routes("Green"), do: ~w[Green-B Green-C Green-D Green-E]
  defp expand_routes(route), do: List.wrap(route)

  defp alert_headsign(0, %{0 => headsigns}), do: join_headsigns(headsigns)
  defp alert_headsign(1, %{1 => headsigns}), do: join_headsigns(headsigns)
  defp headway_headsign(0, %{1 => headsigns}), do: join_headsigns(headsigns)
  defp headway_headsign(1, %{0 => headsigns}), do: join_headsigns(headsigns)

  defp join_headsigns(headsigns) do
    headsigns
    |> Enum.sort()
    |> Enum.join("/")
  end

  defp maybe_unwrap_stop_ids([stop_id]), do: stop_id
  defp maybe_unwrap_stop_ids(stop_ids), do: stop_ids

  defp to_ast(parent_station, dup_alert_headsign_matchers) do
    quote do
      %{unquote(parent_station) => unquote(dup_alert_headsign_matchers)}
    end
  end
end

System.argv()
|> AddDUPHeadsignConfig.main()
