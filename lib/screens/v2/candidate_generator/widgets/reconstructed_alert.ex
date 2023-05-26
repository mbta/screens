defmodule Screens.V2.CandidateGenerator.Widgets.ReconstructedAlert do
  @moduledoc false

  alias Screens.Alerts.Alert
  alias Screens.Config.Screen
  alias Screens.Config.V2.Header.CurrentStopId
  alias Screens.Config.V2.PreFare
  alias Screens.RoutePatterns.RoutePattern
  alias Screens.Routes.Route
  alias Screens.Stops.Stop
  alias Screens.Util
  alias Screens.V2.WidgetInstance.Common.BaseAlert
  alias Screens.V2.WidgetInstance.ReconstructedAlert

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

  @doc """
  Given the stop_id defined in the header, determine relevant routes
  Given the routes, fetch all alerts for the route
  """
  def reconstructed_alert_instances(
        %Screen{
          app_params: %PreFare{reconstructed_alert_widget: %CurrentStopId{stop_id: stop_id}}
        } = config,
        now \\ DateTime.utc_now(),
        fetch_routes_by_stop_fn \\ &Route.fetch_routes_by_stop/3,
        fetch_stop_sequences_by_stop_fn \\ &RoutePattern.fetch_parent_station_sequences_through_stop/2,
        fetch_alerts_fn \\ &Alert.fetch/1,
        fetch_stop_name_fn \\ &Stop.fetch_stop_name/1
      ) do
    # Filtering by subway and light_rail types
    with {:ok, routes_at_stop} <- fetch_routes_by_stop_fn.(stop_id, now, [:light_rail, :subway]),
         route_ids_at_stop =
           routes_at_stop
           |> Enum.map(& &1.route_id)
           # We shouldn't handle Mattapan outages at this time
           |> Enum.reject(fn id -> id === "Mattapan" end),
         {:ok, alerts} <- fetch_alerts_fn.(route_ids: route_ids_at_stop),
         {:ok, stop_sequences} <-
           fetch_stop_sequences_by_stop_fn.(stop_id, route_ids_at_stop) do
      relevant_alerts = relevant_alerts(alerts, config, stop_sequences, routes_at_stop, now)
      is_terminal_station = is_terminal?(stop_id, stop_sequences)

      immediate_disruptions =
        Enum.filter(
          relevant_alerts,
          &(Alert.get_alert_location_for_stop_id(
              &1,
              stop_id,
              stop_sequences,
              routes_at_stop,
              is_terminal_station
            ) in [
              :inside,
              :boundary_upstream,
              :boundary_downstream
            ])
        )

      downstream_disruptions =
        Enum.filter(
          relevant_alerts,
          &(Alert.get_alert_location_for_stop_id(
              &1,
              stop_id,
              stop_sequences,
              routes_at_stop,
              is_terminal_station
            ) in [:downstream, :upstream] and
              (&1.effect != :delay or &1.severity >= 7))
        )

      moderate_delays =
        Enum.filter(relevant_alerts, &(&1.effect == :delay and &1.severity in 5..6))

      common_parameters = [
        config: config,
        stop_sequences: stop_sequences,
        routes_at_stop: routes_at_stop,
        fetch_stop_name_fn: fetch_stop_name_fn,
        is_terminal_station: is_terminal_station,
        now: now
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
          fullscreen_alerts =
            find_closest_downstream_alerts(downstream_disruptions, stop_id, stop_sequences)

          flex_zone_alerts = downstream_disruptions -- fullscreen_alerts

          create_alert_instances(fullscreen_alerts, true, common_parameters) ++
            create_alert_instances(flex_zone_alerts, false, common_parameters) ++
            create_alert_instances(moderate_delays, false, common_parameters)

        true ->
          create_alert_instances(moderate_delays, true, common_parameters)
      end
    else
      :error -> []
    end
  end

  defp create_alert_instances(
         alerts,
         is_full_screen,
         config: config,
         stop_sequences: stop_sequences,
         routes_at_stop: routes_at_stop,
         fetch_stop_name_fn: fetch_stop_name_fn,
         is_terminal_station: is_terminal_station,
         now: now
       ) do
    Enum.map(alerts, fn alert ->
      %ReconstructedAlert{
        screen: config,
        alert: alert,
        now: now,
        stop_sequences: stop_sequences,
        routes_at_stop: routes_at_stop,
        informed_stations_string: get_stations(alert, fetch_stop_name_fn),
        is_terminal_station: is_terminal_station,
        is_full_screen: is_full_screen
      }
    end)
  end

  defp find_closest_downstream_alerts(alerts, stop_id, stop_sequences) do
    home_stop_distance_map = build_distance_map(stop_id, stop_sequences)
    # Map each alert with its distance from home.
    Enum.map(alerts, fn %{informed_entities: ies} = alert ->
      distance =
        ies
        |> Enum.filter(&String.starts_with?(&1.stop, "place-"))
        |> Enum.map(&get_distance(home_stop_distance_map, &1))
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
      # If a stop already has a distance recorded, we use the smaller of the two. <-- *** Unsure if this is always what we'd want to do! ***
      |> Map.merge(distances_by_stop, fn _stop, d1, d2 -> min(d1, d2) end)
    end)
  end

  defp get_distance(home_stop_distance_map, %{route: "Green" <> _, stop: stop_id})
       when stop_id in @gl_eastbound_split_stops,
       do: Map.fetch!(home_stop_distance_map, "place-lech")

  defp get_distance(home_stop_distance_map, %{route: "Green" <> _}),
    do: Map.fetch!(home_stop_distance_map, "place-kencl")

  defp get_distance(home_stop_distance_map, %{stop: stop_id}),
    do: Map.fetch!(home_stop_distance_map, stop_id)

  defp relevant_alerts(alerts, config, stop_sequences, routes_at_stop, now) do
    Enum.filter(alerts, fn %Alert{effect: effect} = alert ->
      reconstructed_alert = %ReconstructedAlert{
        screen: config,
        alert: alert,
        stop_sequences: stop_sequences,
        routes_at_stop: routes_at_stop,
        now: now,
        informed_stations_string: "A Station"
      }

      relevant_effect?(effect) and relevant_location?(reconstructed_alert) and
        Alert.happening_now?(alert, now)
    end)
  end

  defp relevant_effect?(effect) do
    Enum.member?(@relevant_effects, effect)
  end

  defp relevant_location?(%ReconstructedAlert{} = reconstructed_alert) do
    case BaseAlert.location(reconstructed_alert) do
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

  defp relevant_inside_alert?(
         %ReconstructedAlert{alert: %Alert{effect: :delay}} = reconstructed_alert
       ),
       do: relevant_delay?(reconstructed_alert)

  defp relevant_inside_alert?(_), do: true

  defp relevant_boundary_alert?(%ReconstructedAlert{alert: %Alert{effect: :station_closure}}),
    do: false

  defp relevant_boundary_alert?(
         %ReconstructedAlert{
           alert: %Alert{effect: :delay}
         } = reconstructed_alert
       ),
       do: relevant_delay?(reconstructed_alert)

  defp relevant_boundary_alert?(_), do: true

  defp relevant_delay?(
         %ReconstructedAlert{alert: %Alert{severity: severity}} = reconstructed_alert
       ) do
    severity > 3 and relevant_direction?(reconstructed_alert)
  end

  # This function assumes that stop_sequences is ordered by direction north/east -> south/west.
  # If the current station's stop_id is the first or last entry in all stop_sequences,
  # it is a terminal station. Delay alerts heading in the direction of the station are not relevant.
  defp relevant_direction?(
         %ReconstructedAlert{
           screen: %Screen{
             app_params: %{reconstructed_alert_widget: %CurrentStopId{stop_id: stop_id}}
           },
           stop_sequences: stop_sequences
         } = t
       ) do
    informed_entities = BaseAlert.informed_entities(t)

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
          fn stop_sequence -> stop_id == List.first(stop_sequence) end
        ) ->
          0

        # South/West side terminal stations
        Enum.all?(
          stop_sequences,
          fn stop_sequence -> stop_id == List.last(stop_sequence) end
        ) ->
          1

        # Single line stations that are not terminal stations
        true ->
          nil
      end

    relevant_direction_for_terminal == nil or relevant_direction_for_terminal == direction_id
  end

  defp get_stations(alert, fetch_stop_name_fn) do
    stop_ids =
      %ReconstructedAlert{alert: alert}
      |> BaseAlert.informed_entities()
      |> Enum.flat_map(fn %{stop: stop_id} ->
        case stop_id do
          nil -> []
          id -> [id]
        end
      end)

    case stop_ids do
      [] ->
        nil

      _ ->
        stop_ids
        |> Enum.filter(&String.starts_with?(&1, "place-"))
        |> Enum.uniq()
        |> Enum.flat_map(
          &case fetch_stop_name_fn.(&1) do
            :error -> []
            name -> [name]
          end
        )
        |> Util.format_name_list_to_string()
    end
  end

  defp is_terminal?(stop_id, stop_sequences) do
    # Can't use Enum.any, because then Govt Center will be seen as a terminal
    # Using all is ok because no station is the terminal of one line and NOT the terminal of another line
    # excluding GL branches
    Enum.all?(stop_sequences, fn stop_sequence ->
      List.first(stop_sequence) == stop_id or List.last(stop_sequence) == stop_id
    end)
  end
end
