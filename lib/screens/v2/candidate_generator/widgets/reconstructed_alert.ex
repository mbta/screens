defmodule Screens.V2.CandidateGenerator.Widgets.ReconstructedAlert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.LocationContext
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.V2.LocalizedAlert
  alias Screens.V2.WidgetInstance.ReconstructedAlert
  alias ScreensConfig.Screen
  alias ScreensConfig.V2.Header.CurrentStopId
  alias ScreensConfig.V2.PreFare

  @relevant_effects ~w[shuttle suspension station_closure delay]a

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
        %Screen{app_params: %PreFare{} = app_params} = config,
        now \\ DateTime.utc_now(),
        fetch_alerts_fn \\ &Alert.fetch/1,
        fetch_stop_name_fn \\ &Stop.fetch_stop_name/1,
        fetch_location_context_fn \\ &LocationContext.fetch/3,
        fetch_subway_platforms_for_stop_fn \\ &Stop.fetch_subway_platforms_for_stop/1
      ) do
    %PreFare{
      reconstructed_alert_widget: %CurrentStopId{stop_id: stop_id}
    } = app_params

    # Filtering by subway and light_rail types
    with {:ok, location_context} <- fetch_location_context_fn.(PreFare, stop_id, now),
         route_ids <- Route.route_ids(location_context.routes),
         {:ok, alerts} <- fetch_alerts_fn.(route_ids: route_ids) do
      relevant_alerts = relevant_alerts(alerts, location_context, now)
      is_terminal_station = terminal?(stop_id, LocationContext.stop_sequences(location_context))

      immediate_disruptions = get_immediate_disruptions(relevant_alerts, location_context)
      downstream_disruptions = get_downstream_disruptions(relevant_alerts, location_context)
      moderate_delays = get_moderate_disruptions(relevant_alerts)

      common_parameters = [
        config: config,
        location_context: location_context,
        fetch_stop_name_fn: fetch_stop_name_fn,
        is_terminal_station: is_terminal_station,
        now: now,
        fetch_subway_platforms_for_stop_fn: fetch_subway_platforms_for_stop_fn
      ]

      cond do
        Enum.any?(immediate_disruptions) ->
          create_alert_instances(
            immediate_disruptions,
            true,
            common_parameters
          ) ++
            create_alert_instances(downstream_disruptions, false, common_parameters) ++
            create_alert_instances(moderate_delays, false, common_parameters)

        Enum.any?(downstream_disruptions) ->
          closest_downstream =
            find_closest_downstream_alerts(
              downstream_disruptions,
              stop_id,
              LocationContext.stop_sequences(location_context)
            )

          other_downstream = downstream_disruptions -- closest_downstream

          create_alert_instances(closest_downstream, true, common_parameters) ++
            create_alert_instances(other_downstream, false, common_parameters) ++
            create_alert_instances(moderate_delays, false, common_parameters)

        true ->
          create_alert_instances(moderate_delays, true, common_parameters)
      end
    else
      :error -> []
    end
  end

  defp get_immediate_disruptions(relevant_alerts, location_context) do
    Enum.filter(
      relevant_alerts,
      fn
        %{effect: :delay} ->
          false

        alert ->
          LocalizedAlert.location(%{alert: alert, location_context: location_context}) in [
            :inside,
            :boundary_upstream,
            :boundary_downstream
          ]
      end
    )
  end

  defp get_downstream_disruptions(relevant_alerts, location_context) do
    Enum.filter(
      relevant_alerts,
      fn
        %{effect: :delay} = alert ->
          get_severity_level(alert.severity) == :severe

        alert ->
          LocalizedAlert.location(%{alert: alert, location_context: location_context}) in [
            :downstream,
            :upstream
          ]
      end
    )
  end

  defp get_moderate_disruptions(relevant_alerts) do
    Enum.filter(
      relevant_alerts,
      &(&1.effect == :delay and get_severity_level(&1.severity) == :moderate)
    )
  end

  defp create_alert_instances(
         alerts,
         is_priority,
         config: config,
         location_context: location_context,
         fetch_stop_name_fn: fetch_stop_name_fn,
         is_terminal_station: is_terminal_station,
         now: now,
         fetch_subway_platforms_for_stop_fn: fetch_subway_platforms_for_stop_fn
       ) do
    Enum.map(alerts, fn alert ->
      all_platforms_names_at_informed_station =
        get_platform_names_at_informed_station(alert, fetch_subway_platforms_for_stop_fn)

      %ReconstructedAlert{
        screen: config,
        alert: alert,
        now: now,
        location_context: location_context,
        informed_stations: get_stations(alert, fetch_stop_name_fn),
        is_terminal_station: is_terminal_station,
        is_priority: is_priority,
        partial_closure_platform_names: all_platforms_names_at_informed_station
      }
    end)
  end

  defp get_platform_names_at_informed_station(
         %Alert{effect: :station_closure, informed_entities: informed_entities} = alert,
         fetch_subway_platforms_for_stop_fn
       ) do
    with [informed_parent_station] <- Alert.informed_parent_stations(alert),
         platforms <- fetch_subway_platforms_for_stop_fn.(informed_parent_station.stop),
         true <- Alert.partial_station_closure?(alert, platforms) do
      informed_stop_ids = Enum.map(informed_entities, & &1.stop)
      platforms |> Enum.filter(&(&1.id in informed_stop_ids)) |> Enum.map(& &1.platform_name)
    else
      _ -> []
    end
  end

  defp get_platform_names_at_informed_station(_, _), do: []

  defp find_closest_downstream_alerts(alerts, stop_id, stop_sequences) do
    home_stop_distance_map = build_distance_map(stop_id, stop_sequences)
    # Map each alert with its distance from home.
    alerts
    |> Enum.map(fn %{informed_entities: ies} = alert ->
      distance =
        ies
        |> Enum.filter(fn
          # Alert affects entire line
          %{stop: nil, route: route} -> is_binary(route)
          ie -> String.starts_with?(ie.stop, "place-")
        end)
        |> Enum.map(&get_distance(stop_id, home_stop_distance_map, &1))
        |> Enum.min()

      {alert, distance}
    end)
    |> Enum.group_by(&elem(&1, 1), &elem(&1, 0))
    |> Enum.sort_by(&elem(&1, 0))
    # The first item will be all alerts with the shortest distance.
    |> List.first()
    |> elem(1)
  end

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

  defp relevant_alerts(alerts, location_context, now) do
    Enum.filter(alerts, fn %Alert{effect: effect} = alert ->
      reconstructed_alert = %{alert: alert, location_context: location_context}

      relevant_effect?(effect) and relevant_location?(reconstructed_alert) and
        Alert.happening_now?(alert, now)
    end)
  end

  defp relevant_effect?(effect) do
    Enum.member?(@relevant_effects, effect)
  end

  defp relevant_location?(reconstructed_alert) do
    case LocalizedAlert.location(reconstructed_alert) do
      location when location in [:downstream, :upstream] ->
        true

      :inside ->
        relevant_inside_alert?(reconstructed_alert)

      location when location in [:boundary_upstream, :boundary_downstream] ->
        relevant_boundary_alert?(reconstructed_alert)

      _ ->
        false
    end
  end

  defp relevant_inside_alert?(%{alert: %Alert{effect: :delay}} = reconstructed_alert),
    do: relevant_delay?(reconstructed_alert)

  defp relevant_inside_alert?(_), do: true

  defp relevant_boundary_alert?(%{alert: %Alert{effect: :station_closure}}),
    do: false

  defp relevant_boundary_alert?(%{alert: %Alert{effect: :delay}} = reconstructed_alert),
    do: relevant_delay?(reconstructed_alert)

  defp relevant_boundary_alert?(_), do: true

  defp relevant_delay?(%{alert: %Alert{severity: severity}} = reconstructed_alert) do
    get_severity_level(severity) != :low and relevant_direction?(reconstructed_alert)
  end

  # If the current station's stop_id is the first or last entry in all stop_sequences,
  # it is a terminal station. Delay alerts heading in the direction of the station are not relevant.
  defp relevant_direction?(%{
         alert: %Alert{informed_entities: informed_entities},
         location_context: location_context
       }) do
    stop_sequences = LocationContext.stop_sequences(location_context)

    direction_id =
      informed_entities
      |> Enum.map(fn %{direction_id: direction_id} -> direction_id end)
      |> Enum.find(fn direction_id -> not is_nil(direction_id) end)

    relevant_direction_for_terminal =
      cond do
        # Alert affects both directions
        is_nil(direction_id) ->
          nil

        # North/East side terminal stations
        Enum.all?(
          stop_sequences,
          fn stop_sequence -> location_context.home_stop == List.first(stop_sequence) end
        ) ->
          0

        # South/West side terminal stations
        Enum.all?(
          stop_sequences,
          fn stop_sequence -> location_context.home_stop == List.last(stop_sequence) end
        ) ->
          1

        # Single line stations that are not terminal stations
        true ->
          nil
      end

    relevant_direction_for_terminal == nil or relevant_direction_for_terminal == direction_id
  end

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
        |> Enum.flat_map(
          &case fetch_stop_name_fn.(&1) do
            :error -> []
            "Massachusetts Avenue" -> ["Mass Ave"]
            name -> [name]
          end
        )
    end
  end

  defp get_stations(_alert, _fetch_stop_name_fn), do: []

  defp terminal?(stop_id, stop_sequences) do
    # Can't use Enum.any, because then Govt Center will be seen as a terminal
    # Using all is ok because no station is the terminal of one line and NOT the terminal of another line
    # excluding GL branches
    Enum.all?(stop_sequences, fn stop_sequence ->
      List.first(stop_sequence) == stop_id or List.last(stop_sequence) == stop_id
    end)
  end

  defp get_severity_level(severity) do
    cond do
      severity < 5 -> :low
      severity < 7 -> :moderate
      true -> :severe
    end
  end
end
