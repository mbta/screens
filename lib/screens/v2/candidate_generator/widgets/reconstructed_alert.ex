defmodule Screens.V2.CandidateGenerator.Widgets.ReconstructedAlert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.Stops.Stop
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.WidgetInstance.ReconstructedAlert
  alias ScreensConfig.Screen
  alias ScreensConfig.Screen.PreFare

  @gl_eastbound_split_stops [
    "place-mdftf",
    "place-balsq",
    "place-mgngl",
    "place-gilmn",
    "place-esomr",
    "place-unsqu",
    "place-lech"
  ]

  @gl_trunk_stop_ids [
    "place-unsqu",
    "place-lech",
    "place-spmnl",
    "place-north",
    "place-haecl",
    "place-gover",
    "place-pktrm",
    "place-boyls",
    "place-armnl",
    "place-coecl",
    "place-hymnl",
    "place-kencl"
  ]

  @default_distance 99

  @type stop_id :: String.t()
  @type distance :: non_neg_integer()
  @type home_stop_distance_map :: %{stop_id() => distance()}

  @doc """
  Given the stop_id defined in the header, determine relevant routes
  Given the routes, fetch all alerts for the route
  """
  def reconstructed_alert_instances(
        %Screen{
          app_params: %PreFare{
            reconstructed_alert_widget: %ScreensConfig.Alerts{stop_id: stop_id}
          }
        } = config,
        now \\ DateTime.utc_now(),
        fetch_alerts_fn \\ &Alert.fetch/1,
        fetch_stop_name_fn \\ &Stop.fetch_stop_name/1,
        fetch_location_context_fn \\ &LocationContext.fetch/3,
        fetch_subway_platforms_for_stop_fn \\ &Stop.fetch_subway_platforms_for_stop/1
      ) do
    with {:ok, location_context} <- fetch_location_context_fn.(PreFare, stop_id, now),
         route_ids = LocationContext.route_ids(location_context),
         {:ok, alerts} <- fetch_alerts_fn.(route_ids: route_ids) do
      stop_sequences = LocationContext.stop_sequences(location_context)
      distance_map = build_distance_map(stop_id, stop_sequences)
      is_terminal_station = terminal?(stop_id, stop_sequences)

      # Assign alerts to groups (or no group) based on "relevance". The group with the highest
      # relevance will have the `is_priority` flag set on the corresponding alert widgets, giving
      # them more prominent placement.
      {priority_alert_groups, other_alert_groups} =
        alerts
        |> Enum.filter(
          &(Alert.happening_now?(&1, now) and relevant_direction?(&1, stop_id, stop_sequences))
        )
        |> Enum.group_by(fn alert ->
          relevance(
            alert,
            LocalizedAlert.location(
              %{alert: alert, location_context: location_context},
              is_terminal_station
            ),
            distance_from_home(alert, stop_id, distance_map)
          )
        end)
        |> Map.delete(nil)
        |> Enum.sort_by(&elem(&1, 0))
        |> Enum.map(&elem(&1, 1))
        |> Enum.split(1)

      Enum.flat_map(
        [{priority_alert_groups, true}, {other_alert_groups, false}],
        fn {alert_groups, is_priority} ->
          alert_groups
          |> List.flatten()
          |> Enum.map(fn alert ->
            all_platforms_names_at_informed_station =
              get_platform_names_at_informed_station(alert, fetch_subway_platforms_for_stop_fn)

            %ReconstructedAlert{
              screen: config,
              alert: alert,
              now: now,
              location_context: location_context,
              home_station_name:
                fetch_station_name(location_context.home_stop, fetch_stop_name_fn),
              informed_station_names: get_stations(alert, fetch_stop_name_fn),
              is_terminal_station: is_terminal_station,
              is_priority: is_priority,
              partial_closure_platform_names: all_platforms_names_at_informed_station
            }
          end)
        end
      )
    else
      :error -> []
    end
  end

  @inside_locations ~w[inside boundary_upstream boundary_downstream]a
  @service_eliminating_effects ~w[shuttle station_closure suspension]a

  # Filter out `elsewhere` alerts (should never happen).
  defp relevance(_alert, :elsewhere, _distance), do: nil

  # "Immediate disruptions": Service is eliminated in at least one direction at the home stop.
  # Riders may need to take immediate action to continue their trip.
  defp relevance(%Alert{effect: effect}, location, _distance)
       when effect in @service_eliminating_effects and location in @inside_locations,
       do: {0, nil}

  # "Downstream disruptions": Service is eliminated starting somewhere downstream of the home
  # stop. Riders may need to take action later to continue their trip. Split into sub-categories
  # based on how close to the home stop the disruption begins (only the closest get "priority").
  defp relevance(%Alert{effect: effect}, _location, distance)
       when effect in @service_eliminating_effects,
       do: {1, distance}

  # Severe delays are also considered "downstream disruptions".
  defp relevance(%Alert{effect: :delay, severity: severity}, _location, distance)
       when severity >= 7,
       do: {1, distance}

  # "Moderate delays": still important enough to present, but less relevant.
  defp relevance(%Alert{effect: :delay, severity: severity}, _location, _distance)
       when severity >= 5,
       do: {2, nil}

  # Low-severity (including "informational") delays are only included when the cause is
  # single-tracking. Relevance is higher when inside the single-tracked segment.
  defp relevance(%Alert{effect: :delay, cause: :single_tracking}, location, _distance)
       when location in @inside_locations,
       do: {2, nil}

  defp relevance(%Alert{effect: :delay, cause: :single_tracking}, _location, _distance),
    do: {3, nil}

  defp relevance(_alert, _location, _distance), do: nil

  @spec get_platform_names_at_informed_station(Alert.t(), (String.t() -> [Stop.t()])) :: [
          String.t()
        ]
  defp get_platform_names_at_informed_station(
         %Alert{effect: :station_closure, informed_entities: informed_entities} = alert,
         fetch_subway_platforms_for_stop_fn
       ) do
    # Given informed entities representing an alert at a single station,
    # finds the corresponding platform names for those child stops included.
    with [informed_parent_station] <- Alert.informed_parent_stations(alert),
         platforms <- fetch_subway_platforms_for_stop_fn.(informed_parent_station.stop),
         :partial_closure <- Alert.station_closure_type(alert, platforms) do
      informed_stop_ids = Enum.map(informed_entities, & &1.stop)

      platforms |> Enum.filter(&(&1.id in informed_stop_ids)) |> Enum.map(& &1.platform_name)
    else
      _ -> []
    end
  end

  defp get_platform_names_at_informed_station(_, _), do: []

  defp build_distance_map(home_stop_id, stop_sequences) do
    Enum.reduce(stop_sequences, %{}, fn stop_sequence, distances_by_stop ->
      stop_sequence
      # Index each element by its distance from home_stop_id. For example if home_stop_id is at position 2, then indices would start at -2.
      |> Enum.with_index(-Enum.find_index(stop_sequence, &(&1 == home_stop_id)))
      # Convert negative distances to positive, and put into a map.
      |> Map.new(fn {stop, d} -> {stop, abs(d)} end)
      # Merge with the distances recorded from previous stop sequences.
      # If a stop already has a distance recorded, the distances should be the same. Use the first one.
      |> Map.merge(distances_by_stop, fn _stop, d1, _d2 -> d1 end)
    end)
  end

  defp distance_from_home(%Alert{informed_entities: ies}, stop_id, home_stop_distance_map) do
    ies
    |> Enum.filter(fn
      # Alert affects entire line
      %{stop: nil, route: route} -> is_binary(route)
      %{stop: stop} -> String.starts_with?(stop, "place-")
    end)
    |> Enum.map(&get_distance(stop_id, home_stop_distance_map, &1))
    |> Enum.min(fn -> @default_distance end)
  end

  # Default to 99 if stop_id is not in distance map.
  # Stops will not be present in the map if informed_entity and home stop are on different branches.
  # i.e. Braintree is not present in Ashmont stop_sequences, but is still a relevant alert.
  @spec get_distance(stop_id(), home_stop_distance_map(), Alert.informed_entity()) :: distance()
  defp get_distance(home_stop_id, home_stop_distance_map, informed_entity)

  defp get_distance(_home_stop_id, _home_stop_distance_map, %{stop: nil}), do: 0

  defp get_distance(home_stop_id, home_stop_distance_map, %{route: "Green" <> _, stop: ie_stop_id})
       when home_stop_id in @gl_trunk_stop_ids and ie_stop_id in @gl_eastbound_split_stops,
       do: Map.get(home_stop_distance_map, "place-lech", @default_distance)

  defp get_distance(home_stop_id, home_stop_distance_map, %{route: "Green" <> _, stop: ie_stop_id})
       when home_stop_id in @gl_trunk_stop_ids and ie_stop_id not in @gl_trunk_stop_ids,
       do: Map.get(home_stop_distance_map, "place-kencl", @default_distance)

  defp get_distance(_, home_stop_distance_map, %{stop: stop_id}),
    do: Map.get(home_stop_distance_map, stop_id, @default_distance)

  # If the current station's stop_id is the first or last entry in all stop_sequences, it is a
  # terminal station. "Directional" delay alerts heading towards the station are not relevant.
  defp relevant_direction?(
         %Alert{effect: :delay, informed_entities: informed_entities},
         home_stop_id,
         stop_sequences
       ) do
    direction_id =
      informed_entities
      |> Enum.map(fn %{direction_id: direction_id} -> direction_id end)
      |> Enum.find(fn direction_id -> not is_nil(direction_id) end)

    relevant_direction_for_terminal =
      cond do
        # Alert affects both directions
        is_nil(direction_id) -> nil
        # North/East side terminal stations
        Enum.all?(stop_sequences, fn sequence -> home_stop_id == List.first(sequence) end) -> 0
        # South/West side terminal stations
        Enum.all?(stop_sequences, fn sequence -> home_stop_id == List.last(sequence) end) -> 1
        # Single line stations that are not terminal stations
        true -> nil
      end

    relevant_direction_for_terminal == nil or relevant_direction_for_terminal == direction_id
  end

  # Direction filtering doesn't apply to other kinds of alerts.
  defp relevant_direction?(_alert, _home_stop_id, _stop_sequences), do: true

  defp get_stations(
         %{effect: :station_closure, informed_entities: informed_entities},
         fetch_stop_name_fn
       ) do
    stop_ids =
      Enum.flat_map(informed_entities, fn %{stop: stop_id} ->
        case stop_id do
          nil -> []
          id -> [id]
        end
      end)

    case stop_ids do
      [] ->
        []

      _ ->
        stop_ids
        |> Enum.filter(&String.starts_with?(&1, "place-"))
        |> Enum.uniq()
        |> Enum.map(&fetch_station_name(&1, fetch_stop_name_fn))
        |> Enum.reject(&is_nil/1)
    end
  end

  defp get_stations(_alert, _fetch_stop_name_fn), do: []

  defp fetch_station_name(id, fetch_stop_name_fn) do
    case fetch_stop_name_fn.(id) do
      "Massachusetts Avenue" -> ["Mass Ave"]
      name -> name
    end
  end

  defp terminal?(stop_id, stop_sequences) do
    # Can't use Enum.any, because then Govt Center will be seen as a terminal
    # Using all is ok because no station is the terminal of one line and NOT the terminal of another line
    # excluding GL branches
    Enum.all?(stop_sequences, fn stop_sequence ->
      List.first(stop_sequence) == stop_id or List.last(stop_sequence) == stop_id
    end)
  end
end
