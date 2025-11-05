defmodule Screens.V2.WidgetInstance.SubwayStatus.Serialize.Utils do
  @moduledoc """
  Shared utility functions for SubwayStatus serialization.
  Includes location helpers, station closure helpers, and route matching.
  """

  alias Screens.Alerts.Alert
  alias Screens.Alerts.InformedEntity
  alias Screens.Stops.Subway

  @route_directions %{
    "Blue" => ["Westbound", "Eastbound"],
    "Orange" => ["Southbound", "Northbound"],
    "Red" => ["Southbound", "Northbound"],
    "Green-B" => ["Westbound", "Eastbound"],
    "Green-C" => ["Westbound", "Eastbound"],
    "Green-D" => ["Westbound", "Eastbound"],
    "Green-E" => ["Westbound", "Eastbound"],
    "Green" => ["Westbound", "Eastbound"],
    "Mattapan" => ["Outbound", "Inbound"]
  }

  @subway_routes Map.keys(@route_directions)
  @green_line_branches ["Green-B", "Green-C", "Green-D", "Green-E"]
  @green_line_route_ids ["Green" | @green_line_branches]
  @mbta_alerts_url "mbta.com/alerts"

  #######################
  # Location Helpers    #
  #######################

  def get_location(informed_entities, route_id) do
    cond do
      alert_is_whole_route?(informed_entities) ->
        case route_id do
          "Mattapan" -> "Entire Mattapan line"
          _ -> "Entire line"
        end

      alert_is_whole_direction?(informed_entities) ->
        get_direction(informed_entities, route_id)

      true ->
        get_endpoints(informed_entities, route_id)
    end
  end

  def alert_is_whole_route?(informed_entities) do
    Enum.any?(informed_entities, &InformedEntity.whole_route?/1)
  end

  def alert_is_whole_direction?(informed_entities) do
    Enum.any?(informed_entities, &InformedEntity.whole_direction?/1)
  end

  defp get_direction(informed_entities, route_id) do
    [%{direction_id: direction_id} | _] =
      Enum.filter(informed_entities, &InformedEntity.whole_direction?/1)

    direction =
      @route_directions
      |> Map.get(route_id)
      |> Enum.at(direction_id)

    %{full: direction, abbrev: direction}
  end

  # credo:disable-for-next-line
  # TODO: get_endpoints is a common function; could be consolidated
  def get_endpoints(informed_entities, route_id) do
    case Subway.stop_sequence_containing_informed_entities(informed_entities, route_id) do
      nil ->
        nil

      stop_sequence ->
        {min_index, max_index} =
          informed_entities
          |> Enum.filter(&Subway.stop_on_route?(&1.stop, stop_sequence))
          |> Enum.map(&Subway.stop_index_for_informed_entity(&1, stop_sequence))
          |> Enum.min_max()

        {_, {min_full_name, min_abbreviated_name}} = Enum.at(stop_sequence, min_index)
        {_, {max_full_name, max_abbreviated_name}} = Enum.at(stop_sequence, max_index)

        if min_full_name == max_full_name and min_abbreviated_name == max_abbreviated_name do
          %{
            full: "#{min_full_name}",
            abbrev: "#{min_abbreviated_name}"
          }
        else
          %{
            full: "#{min_full_name} ↔ #{max_full_name}",
            abbrev: "#{min_abbreviated_name} ↔ #{max_abbreviated_name}"
          }
        end
    end
  end

  ####################################
  # Station Closure Helper Functions #
  ####################################

  def get_stop_name_with_platform(informed_entities, [platform_name], route_id) do
    # Although it is possible to create a closure alert for multiple partial stations,
    # we pass along platform info only if a single platform is closed at that station.
    # Otherwise we will set an informational URL as the location name to display to the user
    stop_names = Subway.route_stop_names(route_id)
    relevant_entities = filter_entities_by_route(informed_entities, route_id)

    parent_station_id =
      Enum.find_value(relevant_entities, fn %{stop: stop_id} ->
        if Map.has_key?(stop_names, stop_id), do: stop_id
      end)

    case Map.get(stop_names, parent_station_id) do
      {full, _abbrev} ->
        %{
          full: "#{full}: #{platform_name} platform closed",
          abbrev: "#{full} (1 side only)"
        }

      nil ->
        %{full: @mbta_alerts_url, abbrev: @mbta_alerts_url}
    end
  end

  def get_stop_name_with_platform(_informed_entities, _platform_names, _route_id) do
    # If there are multiple platforms or no platforms closed, then use fallback alerts URL
    %{full: @mbta_alerts_url, abbrev: @mbta_alerts_url}
  end

  def get_stop_names_from_ies(informed_entities, route_id) do
    informed_entities
    |> filter_entities_by_route(route_id)
    |> Enum.flat_map(fn
      %{stop: stop_id, route: route_id} ->
        stop_names = Subway.route_stop_names(route_id)

        case Map.get(stop_names, stop_id) do
          nil -> []
          name -> [name]
        end

      _ ->
        []
    end)
    |> Enum.uniq()
  end

  def format_station_closure(stop_names) do
    case stop_names do
      [] ->
        {"Skipping", nil}

      [stop_name] ->
        {full_name, abbreviated_name} = stop_name
        {"Stop Skipped", %{full: full_name, abbrev: abbreviated_name}}

      [stop_name1, stop_name2] ->
        {full_name1, abbreviated_name1} = stop_name1
        {full_name2, abbreviated_name2} = stop_name2

        {"2 Stops Skipped",
         %{
           full: "#{full_name1} and #{full_name2}",
           abbrev: "#{abbreviated_name1} and #{abbreviated_name2}"
         }}

      [stop_name1, stop_name2, stop_name3] ->
        {full_name1, _abbreviated_name1} = stop_name1
        {full_name2, _abbreviated_name2} = stop_name2
        {full_name3, _abbreviated_name3} = stop_name3

        {"3 Stops Skipped",
         %{
           full: "#{full_name1}, #{full_name2}, and #{full_name3}",
           abbrev: @mbta_alerts_url
         }}

      stop_names ->
        {"#{length(stop_names)} Stops Skipped",
         %{full: @mbta_alerts_url, abbrev: @mbta_alerts_url}}
    end
  end

  ############################
  # Route Matching Helpers   #
  ############################

  def filter_entities_by_route(informed_entities, route_id) do
    Enum.filter(informed_entities, fn
      %{route: entity_route} -> matches_route?(entity_route, route_id)
      _ -> false
    end)
  end

  def matches_route?(entity_route, route_id)
      when route_id == "Green" and entity_route in @green_line_route_ids,
      do: true

  def matches_route?(entity_route, route_id), do: entity_route == route_id

  ############################
  # Alert Routes Helper      #
  ############################

  def alert_routes(%{alert: %Alert{informed_entities: entities}}) do
    entities
    |> Enum.map(fn e -> Map.get(e, :route) end)
    |> Enum.reject(&is_nil/1)
    |> Enum.filter(&(&1 in @subway_routes))
    |> Enum.uniq()
  end
end
