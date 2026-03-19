# Script to find all common headsigns for representative trips of route patterns.
# Creates a CSV file in the project's root directory.

# To use this script:
#    - `elixir scripts/trip_headsigns.exs` (defaults to including all typicality levels)
#    - `elixir scripts/trip_headsigns.exs --typicality 1`
#    - `elixir scripts/trip_headsigns.exs --typicality all --output all_headsigns.csv`

Mix.install([{:csv, "~> 3.2"}, {:httpoison, "~> 2.3"}, {:jason, "~> 1.4"}])

{opts, _, _} =
  System.argv()
  |> OptionParser.parse(strict: [typicality: :string, output: :string])

typicality = Keyword.get(opts, :typicality, "all")
output_file = Keyword.get(opts, :output, "trip_headsigns.csv")

defmodule RouteHeadsigns do
  @route_type_mapping %{0 => :light_rail, 1 => :subway, 2 => :rail, 3 => :bus, 4 => :ferry}

  def find_headsigns(typicality_filter, output_file) do
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
      |> filter_patterns_by_typicality(typicality_filter)
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

    create_csv_file([["Route Type", "Route ID", "Headsign"]] ++ csv_data, output_file)
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

  defp filter_patterns_by_typicality(patterns, "all"), do: patterns

  defp filter_patterns_by_typicality(patterns, typicality_filter) do
    Enum.filter(patterns, fn %{"attributes" => %{"typicality" => typicality}} ->
      typicality == String.to_integer(typicality_filter)
    end)
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
RouteHeadsigns.find_headsigns(typicality, output_file)
