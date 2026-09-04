# Quick one off script to populate modes within a current local config.
# The new config will be written to "priv/local.updated.json".
#
# We first use the current Params values to try and
# get the mode. If there isn't enough information, we go ahead
# and get the departures for that particular section. If there
# aren't any departures, we put a null mode for that section
# which will require manual intervention.
#
# Note: we use the currently configured API environment
# in `.envrc` for pulling departures, so to get production departures
# data, you'll need production values.
#
# example usages:
# mix run scripts/add_mode_to_departures_params.exs
#

# To prevent info logs from the application
Logger.configure(level: :warning)

defmodule AddModeToDeparturesConfig do
  @moduledoc """
  """
  alias Screens.V2.Departure
  @config_path "priv/local.json"
  @output_path "priv/local.updated.json"
  @silver_line_routes ~w[741 742 743 746 749 751]a

  def run do
    config =
      @config_path
      |> File.read!()
      |> Jason.decode!()

    updated_config =
      config
      |> update_config()
      |> ScreensConfig.Config.from_json()
      |> ScreensConfig.Config.to_json()
      |> Jason.encode!(pretty: true)

    File.write!(@output_path, updated_config)

    IO.puts("Wrote updated config to #{@output_path}")
  end

  defp update_config(config) do
    update_in(config, ["screens"], fn screens ->
      Map.new(screens, fn {screen_id, screen} ->
        {screen_id, update_screen(screen)}
      end)
    end)
  end

  defp update_screen(screen) do
    Enum.reduce(
      ["departures", "primary_departures", "secondary_departures"],
      screen,
      fn departure_key, screen ->
        update_departures(screen, departure_key)
      end
    )
  end

  defp update_departures(screen, departure_key) do
    case get_in(screen, ["app_params", departure_key, "sections"]) do
      nil ->
        screen

      sections ->
        put_in(
          screen,
          ["app_params", departure_key, "sections"],
          Enum.map(sections, &update_section/1)
        )
    end
  end

  defp update_section(section) do
    case get_in(section, ["params"]) do
      nil -> section
      params -> put_in(section, ["params"], update_params(params, section))
    end
  end

  defp update_params(params, section) do
    mode = determine_mode(params, section)
    Map.put(params, "mode", mode)
  end

  defp determine_mode(params, section) do
    route_ids = params["route_ids"]
    route_type = params["route_type"]

    cond do
      is_list(route_ids) and route_ids != [] ->
        mode_from_route_ids(route_ids)

      route_type != nil and route_type != "subway" and route_type != "light_rail" ->
        mode_from_route_type(route_type)

      true ->
        mode_from_departure(params, section)
    end
  end

  defp mode_from_route_ids(route_ids) do
    cond do
      Enum.any?(route_ids, &(&1 == "Red")) ->
        "rl"

      Enum.any?(route_ids, &(&1 == "Blue")) ->
        "bl"

      Enum.any?(route_ids, &(&1 == "Orange")) ->
        "ol"

      Enum.any?(route_ids, &String.starts_with?(&1, "Green-")) ->
        "gl"

      true ->
        "bus"
    end
  end

  defp mode_from_route_type("rail"), do: "cr"
  defp mode_from_route_type("ferry"), do: "ferry"
  defp mode_from_route_type(_), do: "bus"

  defp mode_from_departure(params, section) do
    Process.sleep(1_000)

    {:ok, departures} =
      Map.update!(params, "direction_id", fn
        "both" -> :both
        value -> value
      end)
      |> Map.update!("route_type", fn
        "subway" -> :subway
        "light_rail" -> :light_rail
        value -> value
      end)
      |> Map.new(fn {key, value} -> {String.to_atom(key), value} end)
      |> Departure.fetch()

    representative_departure = departures |> List.first()

    if representative_departure == nil do
      # This section will need manual intervention
      IO.puts("Empty Departure for Section")
      IO.inspect(section)
      nil
    else
      route = Departure.route(representative_departure)

      case route.id do
        "Red" -> "rl"
        "Mattapan" -> "m"
        "Orange" -> "ol"
        "Blue" -> "bl"
        "Green" <> _ -> "gl"
        "CR-" <> _ -> "cr"
        "Boat-" <> _ -> "ferry"
        id when id in @silver_line_routes -> "sl"
        _ -> "bus"
      end
    end
  end
end

AddModeToDeparturesConfig.run()
