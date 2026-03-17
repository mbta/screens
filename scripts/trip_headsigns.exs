#!/usr/bin/env -S ERL_FLAGS=+B elixir

# Script to find all common headsigns for representative trips of route patterns.
# Creates a CSV file in the project's root directory.

# To use this script: `elixir scripts/trip_headsigns.exs`

# Prevents info logs from the application
Logger.configure(level: :warning)

Mix.install([{:csv, "~> 3.2"}, {:httpoison, "~> 2.3"}, {:jason, "~> 1.4"}])

defmodule RouteHeadsigns do
  @route_type_mapping %{0 => :light_rail, 1 => :subway, 2 => :rail, 3 => :bus, 4 => :ferry}

  def find_headsigns() do
    api_v3_key = System.get_env("API_V3_KEY")
    headers = [{"x-api-key", api_v3_key}]

    {:ok, %{status_code: 200, body: body}} =
      HTTPoison.get(
        "https://api-v3.mbta.com/route_patterns/?include=representative_trip,route",
        headers
      )

    {:ok, parsed} = Jason.decode(body)

    %{"data" => data, "included" => included} = parsed

    included_headsigns = process_included_headsigns(included)
    included_routes = process_included_routes(included)

    csv_data =
      data
      |> Enum.filter(fn %{"attributes" => %{"typicality" => typicality}} -> typicality == 1 end)
      |> Enum.map(fn %{
                       "relationships" => %{
                         "representative_trip" => %{"data" => %{"id" => trip_id}},
                         "route" => %{"data" => %{"id" => route_id}}
                       }
                     } ->
        [
          Map.get(@route_type_mapping, Map.get(included_routes, route_id)),
          route_id,
          Map.get(included_headsigns, trip_id)
        ]
      end)
      |> Enum.uniq()
      |> Enum.sort_by(fn [_route_type, _route_id, headsign] -> headsign end)

    create_csv_file(
      [["Route Type", "Route ID", "Headsign"]] ++ csv_data,
      "trip_headsigns.csv"
    )
  end

  defp process_included_routes(included) do
    included
    |> Enum.filter(fn %{"type" => type} -> type == "route" end)
    |> Enum.map(fn %{"id" => id, "attributes" => %{"type" => route_type}} ->
      {id, route_type}
    end)
    |> Enum.into(%{})
  end

  defp process_included_headsigns(included) do
    included
    |> Enum.filter(fn %{"type" => type} -> type == "trip" end)
    |> Enum.map(fn %{"id" => id, "attributes" => %{"headsign" => headsign}} ->
      {id, headsign}
    end)
    |> Enum.into(%{})
  end

  defp create_csv_file(data, filename) do
    file = File.open!(filename, [:write, :utf8])

    data
    |> CSV.encode()
    |> Enum.each(&IO.write(file, &1))

    File.close(file)
  end
end

# Actually run the function to find headsigns and create the CSV file
RouteHeadsigns.find_headsigns()
