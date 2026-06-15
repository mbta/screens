# Script to get all of the destinations we could show on a given Screen
# Uses the local.json file to find each relevant screen's departure query params,
# then makes API calls to find the unique headsigns for those queries,

# This runs based on your local Screens configuration file at local.json, so
#  make sure to run the `sync_s3_env.sh` script first to test with production screens.

# Example usage:
# Remember to sync your local.json with production if you want to see production screens and their destinations!
# To run with no special filters and output to the default file:
#   `elixir scripts/screen_destinations.exs`
# To narrow the scope to a set of screens and specify an output file:
#   `elixir scripts/screen_destinations.exs --screens=PRE-159,PRE-160 --file=filtered_screen_destinations.csv`

Mix.install([{:csv, "~> 3.2"}, {:req, "~> 0.5"}, {:jason, "~> 1.4"}])

# Parse command line options
{opts, _, _} =
  System.argv()
  |> OptionParser.parse(strict: [screens: :string, file: :string])

filtered_screens =
  opts
  |> Keyword.get(:screens, "")
  |> String.split(",", trim: true)

output_file = Keyword.get(opts, :file, "screen_destinations.csv")

defmodule ScreenDestinations do
  @valid_app_ids ["pre_fare_v2", "busway_v2"]
  @typicality_threshold 1
  @route_type_mapping %{0 => "light_rail", 1 => "subway", 2 => "rail", 3 => "bus", 4 => "ferry"}

  def fetch_local_json(output_file, filtered_screens) do
    case File.read("../priv/local.json") do
      {:ok, configs} ->
        destinations_by_screen =
          configs
          |> Jason.decode!()
          |> Map.get("screens")
          |> Enum.filter(fn {_screen_id, screen_data} ->
            screen_data["app_id"] in @valid_app_ids
          end)
          |> Enum.filter(fn {screen_id, _screen_data} ->
            case filtered_screens do
              [] -> true
              filtered_screens -> screen_id in filtered_screens
            end
          end)
          |> Enum.map(fn {screen_id, screen_data} ->
            {screen_id, screen_data["name"], screen_data["app_params"]["departures"]["sections"]}
          end)
          |> Enum.filter(fn {_screen_id, _name, sections} -> sections != nil end)
          |> Enum.map(fn {screen_id, name, sections} ->
            {screen_id, name, all_sections_destinations(screen_id, sections)}
          end)
          |> Enum.map(fn {screen_id, name, destinations} ->
            {
              screen_id,
              name,
              destinations
              |> Enum.uniq()
              |> Enum.group_by(& &1.route_type, &{&1.route_id, &1.headsign})
            }
          end)
          |> Enum.sort_by(&elem(&1, 0))

        csv_data =
          destinations_by_screen
          |> Enum.map(fn {screen_id, name, destinations} ->
            bus_destinations = Map.get(destinations, "bus", [])
            light_rail_destinations = Map.get(destinations, "light_rail", [])
            subway_destinations = Map.get(destinations, "subway", [])

            [
              screen_id,
              if(name != "", do: name, else: "N/A"),
              Enum.count(bus_destinations),
              Enum.count(light_rail_destinations),
              Enum.count(subway_destinations),
              readable_destinations(bus_destinations),
              readable_destinations(light_rail_destinations),
              readable_destinations(subway_destinations)
            ]
          end)

        create_csv_file(
          [
            [
              "Screen ID",
              "Name",
              "Bus Count",
              "Light Rail Count",
              "Subway Count",
              "Bus Destinations",
              "Light Rail Destinations",
              "Subway Destinations"
            ]
          ] ++ csv_data,
          output_file
        )

      {:error, reason} ->
        IO.puts("Failed to read file: #{reason}")
    end
  end

  # For each section of a screen, get the possible destinations from the V3 API, then combine and deduplicate them
  defp all_sections_destinations(screen_id, sections) do
    sections
    |> Enum.filter(&(&1["header_only"] != true))
    |> Enum.map(fn section -> section["query"]["params"] end)
    |> Enum.flat_map(fn params ->
      # For each section of a screen, get the possible destinations from the V3 API
      {route_type_param, fetch_params} = Map.split(params, ["route_type"])
      route_filter = Map.get(route_type_param, "route_type") || "all"

      encoded_params =
        fetch_params
        |> Enum.flat_map(&encode_param/1)
        |> Map.new()
        |> Map.put("include", Enum.join(~w[route representative_trip], ","))

      case Req.get(
             "https://api-v3.mbta.com/route_patterns/?#{URI.encode_query(encoded_params)}",
             headers: [{"x-api-key", System.get_env("API_V3_KEY")}]
           ) do
        {:ok, %{status: 200, body: %{"data" => data, "included" => included}}} ->
          included_headsigns = process_included_headsigns(included)
          included_routes = process_included_routes(included)

          data
          |> Enum.filter(&(&1["attributes"]["typicality"] <= @typicality_threshold))
          |> Enum.map(fn %{
                           "relationships" => %{
                             "representative_trip" => %{"data" => %{"id" => trip_id}},
                             "route" => %{"data" => %{"id" => route_id}}
                           }
                         } ->
            %{
              headsign: Map.get(included_headsigns, trip_id),
              route_id: route_id,
              route_type:
                Map.get(
                  @route_type_mapping,
                  included_routes |> Map.get(route_id) |> Map.get(:type)
                )
            }
          end)
          |> Enum.reject(
            &(String.contains?(&1.headsign, "Shuttle") or
                (route_filter != "all" and &1.route_type != route_filter))
          )
          |> Enum.uniq()

        _ ->
          IO.puts(
            "Failed to fetch route patterns for screen #{screen_id} with configured params: #{inspect(params)}"
          )

          []
      end
    end)
  end

  # Encode params from the Screen's Departures section configuration for the V3 API request
  defp encode_param({"ids", ids}), do: [{"filter[id]", Enum.join(ids, ",")}]
  defp encode_param({"route_ids", []}), do: []
  defp encode_param({"route_ids", ids}), do: [{"filter[route]", Enum.join(ids, ",")}]
  defp encode_param({"direction_id", nil}), do: []
  defp encode_param({"direction_id", "both"}), do: []
  defp encode_param({"direction_id", id}), do: [{"filter[direction_id]", to_string(id)}]
  defp encode_param({"stop_ids", []}), do: []
  defp encode_param({"stop_ids", ids}), do: [{"filter[stop]", Enum.join(ids, ",")}]

  defp process_included_headsigns(included) do
    included
    |> Enum.filter(fn %{"type" => type} -> type == "trip" end)
    |> Enum.map(fn %{"id" => id, "attributes" => %{"headsign" => headsign}} ->
      {id, headsign}
    end)
    |> Enum.into(%{})
  end

  defp process_included_routes(included) do
    included
    |> Enum.filter(fn %{"type" => type} -> type == "route" end)
    |> Enum.map(fn %{
                     "id" => id,
                     "attributes" => %{"type" => route_type}
                   } ->
      {id, %{type: route_type}}
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

  defp readable_destinations(destinations) do
    destinations
    |> Enum.map(fn {id, headsign} -> "#{id} (#{headsign})" end)
    |> Enum.sort()
    |> Enum.join(", ")
  end
end

# Actually run the script
ScreenDestinations.fetch_local_json(output_file, filtered_screens)
